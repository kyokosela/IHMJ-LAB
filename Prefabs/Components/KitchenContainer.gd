extends InventoryContainer
class_name KitchenContainer
## Contenedor multi-estación para la cocina
## Agrupa: estaciones de craft + craft simple (3 slots) + almacenamiento

signal station_craft_started(station_id: String, recipe: Crafts)
signal station_craft_completed(station_id: String, result: Item)
signal station_craft_failed(station_id: String, reason: String)
signal simple_craft_available(recipe: Crafts)
signal simple_craft_executed(result: Item)
signal overflow_detected(items: Array[Item])

@export_group("Stations")
@export var stations: Array[Station] = []

@export_group("Simple Craft")
@export var simple_craft_recipes: Array[Crafts] = []  ## Recetas para los 3 slots

@export_group("Storage")
@export var storage_size: int = 6

## Constantes para índices de slots
## Layout: [Station0, Station1, Station2, SimpleCraft0, SimpleCraft1, SimpleCraftResult, Storage...]
var _station_start_index: int = 0
var _simple_craft_start_index: int:
	get: return stations.size()
var _simple_craft_result_index: int:
	get: return _simple_craft_start_index + 2
var _storage_start_index: int:
	get: return _simple_craft_start_index + 3

## Cache de craft simple actual (para preview)
var _pending_simple_craft: Crafts = null
var _pending_simple_craft_items: Array[Item] = []

func _ready():
	super()
	_setup_slot_structure()
	
	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)
	
	_restore_stations()

func _setup_slot_structure(): ## Calcula el tamaño total necesario
	var total_slots = stations.size() + 3 + storage_size  # stations + simple craft (2+1) + storage

	if inventory:
		# Completado: si el inventario ya viene armado (p. ej. restaurado por el ContainerManager al volver
		# a la escena) NO se vuelve a crear: antes esto borraba todo lo guardado en la cocina.
		if inventory.slots.size() == total_slots:
			return
		inventory.size = total_slots
		inventory._initialize_slots()

## Completado (P31): las estaciones son recursos COMPARTIDOS: al salir de la zona con la estufa cocinando seguia "ocupada" y su
## evento apuntaba al nodo viejo (ya liberado), asi que la comida nunca terminaba. Al volver se retoma: si el evento sigue en
## marcha se rehace con este nodo y el tiempo que le queda; si ya se cumplio mientras no estabas, el crafteo termina ahora.
func _restore_stations() -> void:
	for station in stations:
		if not station.is_locked: continue
		var event = EventManager.get_event(station.active_craft_event) as LapseEvent
		var left := ""
		if event != null:
			left = event.timer_count if not event.timer_count.is_empty() else event.time_lapse_value
			EventManager.remove_event(station.active_craft_event)
		var item = get_station_item(station.station_id)
		var recipe = station.find_valid_recipe([item]) if item != null else null
		if recipe == null:
			station.unlock()
			continue
		var items : Array[Item] = [item]
		if left == "":
			station.unlock()
			_execute_station_craft(station, recipe, items)
		else:
			EventManager.create_lapse_event(left, _on_station_craft_timer_complete.bind(station.station_id, recipe, items), station.active_craft_event, "COOKING_" + station.station_id, false, true, true)
#region Station API
## Obtiene una estación por ID
func get_station(station_id: String) -> Station:
	for station in stations:
		if station.station_id == station_id:
			return station
	return null

## Obtiene el índice del slot de una estación
func get_station_slot_index(station_id: String) -> int:
	for i in range(stations.size()):
		if stations[i].station_id == station_id:
			return _station_start_index + i
	return -1

## Verifica si una estación está bloqueada
func is_station_locked(station_id: String) -> bool:
	var station = get_station(station_id)
	return station != null and station.is_locked

## Intenta añadir un item a una estación
func add_item_to_station(station_id: String, item: Item) -> bool:
	var station = get_station(station_id)
	if station == null: return false
	
	if not station.can_accept(item):
		return false
	
	var slot_index = get_station_slot_index(station_id)
	if slot_index == -1: return false
	
	var slot = inventory.slots[slot_index]
	if not slot.is_empty(): return false
	
	slot.item = item
	inventory.slot_changed.emit(slot_index)
	inventory.inventory_changed.emit()
	
	return true

## Obtiene el item en una estación
func get_station_item(station_id: String) -> Item:
	var slot_index = get_station_slot_index(station_id)
	if slot_index == -1: return null
	
	var slot = inventory.slots[slot_index]
	return slot.item if not slot.is_empty() else null

## Inicia un craft en una estación
func start_station_craft(station_id: String, recipe: Crafts = null) -> bool:
	var station = get_station(station_id)
	if station == null or station.is_locked: return false
	
	var slot_index = get_station_slot_index(station_id)
	var item = get_station_item(station_id)
	if item == null: return false
	
	if recipe == null:
		recipe = station.find_valid_recipe([item])
	
	if recipe == null: return false
	
	if _check_breakage([item]):
		station_craft_failed.emit(station_id, "ITEM_BROKEN")
		return false
	
	if recipe.needed_time != "00:00" and recipe.needed_time != "":
		var event_name = "CRAFT_%s_%s_%d" % [station_id, recipe.result_item.item_unique_name, Time.get_ticks_msec()]
		
		station.lock_for_craft(event_name, [slot_index])
		
		EventManager.create_lapse_event(
			recipe.needed_time,
			_on_station_craft_complete.bind(station_id, recipe, [item]),
			event_name,
			"Cooking " + recipe.result_item.item_name,
			false, true, true
		)
		
		station_craft_started.emit(station_id, recipe)
		return true
	else:
		_execute_station_craft(station, recipe, [item])
		return true

## Callback cuando el timer del craft de estación termina
func _on_station_craft_timer_complete(station_id: String, recipe: Crafts, items: Array[Item]):
	var station = get_station(station_id)
	if station == null: return
	
	station.unlock()
	_execute_station_craft(station, recipe, items)

func _on_station_craft_complete(station_id: String, recipe: Crafts, items: Array[Item]):
	var station = get_station(station_id)
	if station == null: return
	
	station.unlock()
	_execute_station_craft(station, recipe, items)

func _execute_station_craft(station: Station, recipe: Crafts, items: Array[Item]):
	var slot_index = get_station_slot_index(station.station_id)
	
	var result = recipe.create_result(items)
	result.update_states()
	for i in range(mini(recipe.needed_items.size(), items.size())):
		var craft_slot: CraftSlot = recipe.needed_items[i]
		var original_item = items[i] if i < items.size() else null
		
		var return_item = craft_slot.create_return_item(original_item)
		if return_item != null:
			return_item.update_states()
			inventory.slots[slot_index].item = return_item
		else:
			inventory.slots[slot_index].clear()
	
	# Completado: el resultado se queda en la estacion donde se hizo (lo picado en la tabla, la olla en la estufa o el fregadero).
	# Solo si la estacion la ocupa un objeto devuelto por la receta, va al resultado de Combinar o a la alacena.
	if inventory.slots[slot_index].is_empty():
		inventory.slots[slot_index].item = result
		inventory.slot_changed.emit(slot_index)
	elif not _try_place_result(result):
		overflow_detected.emit([result])

	station_craft_completed.emit(station.station_id, result)
	inventory.inventory_changed.emit()
#endregion

#region Simple Craft API (3 slots)
## Obtiene los índices de los slots de craft simple (input)
func get_simple_craft_input_indices() -> Array[int]:
	return [_simple_craft_start_index, _simple_craft_start_index + 1] as Array[int]

## Obtiene el índice del slot de resultado de craft simple
func get_simple_craft_result_index() -> int:
	return _simple_craft_result_index

## Completado: lo combinado se queda en la casilla de resultado hasta que el jugador lo saque; mientras tanto no se combina otra vez.
func is_simple_craft_result_free() -> bool:
	return inventory.slots[_simple_craft_result_index].is_empty()

func set_simple_craft_result(item: Item) -> void:
	inventory.slots[_simple_craft_result_index].item = item
	inventory.slot_changed.emit(_simple_craft_result_index)
	inventory.inventory_changed.emit()

## Obtiene los items en los slots de craft simple
func get_simple_craft_items() -> Array[Item]:
	var items: Array[Item] = []
	for i in get_simple_craft_input_indices():
		var slot = inventory.slots[i]
		if not slot.is_empty():
			items.append(slot.item)
	return items

## Verifica si hay un craft simple válido (no emite señal - solo para consulta)
func check_simple_craft() -> Crafts:
	var items = get_simple_craft_items()
	if items.is_empty(): 
		_pending_simple_craft = null
		return null
	
	for recipe in simple_craft_recipes:
		if _simple_craft_matches(recipe, items):
			if _pending_simple_craft != recipe:
				_pending_simple_craft = recipe
				_pending_simple_craft_items = items
				simple_craft_available.emit(recipe)
			return recipe
	
	_pending_simple_craft = null
	return null

func _simple_craft_matches(recipe: Crafts, items: Array[Item]) -> bool:
	if items.size() < recipe.needed_items.size():
		return false
	
	var used_indices: Array[int] = []
	
	for needed in recipe.needed_items:
		var found = false
		for i in range(items.size()):
			if i in used_indices: continue
			if needed.matches(items[i]):
				used_indices.append(i)
				found = true
				break
		if not found:
			return false
	
	return true

## Ejecuta el craft simple pendiente (cuando el player toma el resultado)
## Completado: antes cada ingrediente se buscaba por su POSICION en la lista de items ocupados y no por la casilla donde
## estaba: con el ingrediente en la 2.a casilla se vaciaba la 1.a (vacia) y el ingrediente nunca se gastaba (comidas
## infinitas). Ahora cada ingrediente se consume en SU casilla, como hace CraftingContainer con los indices usados.
func execute_simple_craft() -> Item:
	if _pending_simple_craft == null: return null
	
	var recipe = _pending_simple_craft
	var slot_indices : Array[int] = _simple_craft_slot_indices(recipe)
	if slot_indices.size() < recipe.needed_items.size():
		# lo que hay en las casillas ya no coincide con la receta pendiente
		_pending_simple_craft = null
		_pending_simple_craft_items.clear()
		return null
	
	var items: Array[Item] = []
	for idx in slot_indices:
		items.append(inventory.slots[idx].item)
	
	if _check_breakage(items):
		_pending_simple_craft = null
		_pending_simple_craft_items.clear()
		return null
	
	var result = recipe.create_result(items)
	result.update_states()
	
	for i in range(slot_indices.size()):
		var craft_slot: CraftSlot = recipe.needed_items[i]
		var return_item = craft_slot.create_return_item(items[i])
		if return_item != null:
			return_item.update_states()
			inventory.slots[slot_indices[i]].item = return_item
		else:
			inventory.slots[slot_indices[i]].clear()
	
	_pending_simple_craft = null
	_pending_simple_craft_items.clear()
	
	simple_craft_executed.emit(result)
	inventory.inventory_changed.emit()
	
	return result

## Completado: casilla de entrada que usa cada ingrediente de la receta (en el orden de la receta); vacio si no coincide.
func _simple_craft_slot_indices(recipe: Crafts) -> Array[int]:
	var used: Array[int] = []
	for needed in recipe.needed_items:
		var found := -1
		for idx in get_simple_craft_input_indices():
			if idx in used: continue
			var slot = inventory.slots[idx]
			if not slot.is_empty() and needed.matches(slot.item):
				found = idx
				break
		if found == -1:
			return []
		used.append(found)
	return used

## Devuelve los items de craft simple a un inventario (al cerrar UI)
func return_simple_craft_items(target: InventoryContainer) -> Array[Item]:
	var overflow: Array[Item] = []
	var input_indices = get_simple_craft_input_indices()
	
	for idx in input_indices:
		var slot = inventory.slots[idx]
		if slot.is_empty(): continue
		
		var item = slot.item
		slot.clear()
		# Intentar mover al target
		if target.has_space_for(item.data):
			target.add_item(item)
		# Intentar mover al storage de la cocina
		elif _add_to_storage(item):
			pass  # Éxito
		else:
			overflow.append(item)
	
	inventory.inventory_changed.emit()
	
	if not overflow.is_empty():
		overflow_detected.emit(overflow)
	
	return overflow
#endregion

#region Storage API
## Completado: lo que se agrega "sin mas" a la cocina (ej. los items iniciales de la nevera) va al
## ALMACENAMIENTO. El add_item de InventoryContainer usa el primer slot libre, que aqui es una estacion.
func add_item_by_data(data: ItemData) -> bool:
	if rules and not rules.can_store(data): return false
	return add_item(Item.new(data))

func add_item(item: Item) -> bool:
	if rules and not rules.can_store(item.data): return false
	if not _add_to_storage(item): return false
	inventory.item_added.emit(item)
	inventory.inventory_changed.emit()
	return true

## Obtiene los índices de los slots de storage
func get_storage_indices() -> Array[int]:
	var indices: Array[int] = []
	for i in range(storage_size):
		indices.append(_storage_start_index + i)
	return indices

## Añade un item al storage
func _add_to_storage(item: Item) -> bool:
	for idx in get_storage_indices():
		var slot = inventory.slots[idx]
		if slot.is_empty():
			slot.item = item
			inventory.slot_changed.emit(idx)
			return true
	return false

## Verifica si hay espacio en storage
func has_storage_space() -> bool:
	for idx in get_storage_indices():
		if inventory.slots[idx].is_empty():
			return true
	return false
#endregion

#region Internal Helpers
func _on_inventory_changed():
	check_simple_craft()
	_check_all_station_crafts()

func _check_all_station_crafts():
	# Solo notifica cambios, no ejecuta - la ejecución es manual via botón
	pass

## Verifica si hay craft válido en una estación (para UI)
func has_valid_station_craft(station_id: String) -> bool:
	var station = get_station(station_id)
	if station == null or station.is_locked:
		return false
	
	var item = get_station_item(station_id)
	if item == null:
		return false
	
	var recipe = station.find_valid_recipe([item])
	return recipe != null

## Inicia manualmente un craft en una estación (llamado desde botón de UI)
func start_manual_station_craft(station_id: String) -> bool:
	var station = get_station(station_id)
	if station == null or station.is_locked:
		return false
	
	var item = get_station_item(station_id)
	if item == null:
		return false
	
	var recipe = station.find_valid_recipe([item])
	if recipe == null:
		return false
	
	_execute_station_craft_with_time(station, recipe, [item])
	return true

## Ejecuta un craft de estación (con o sin tiempo)
func _execute_station_craft_with_time(station: Station, recipe: Crafts, items: Array[Item]):
	var slot_index = get_station_slot_index(station.station_id)
	
	# Bloquear la estación
	var event_name = "COOKING_%s_%d" % [station.station_id, Time.get_ticks_msec()]
	station.lock_for_craft(event_name, [slot_index])
	
	station_craft_started.emit(station.station_id, recipe)
	
	if recipe.needed_time != "" and recipe.needed_time != "00:00":
		EventManager.create_lapse_event(
			recipe.needed_time,
			_on_station_craft_timer_complete.bind(station.station_id, recipe, items),
			event_name,
			"COOKING_" + station.station_id,
			false,
			true,
			true
		)
	else:
		# Craft instantáneo
		station.unlock()
		_execute_station_craft(station, recipe, items)

func _create_craft_result(recipe: Crafts, items: Array[Item]) -> Item:
	# Usa el nuevo sistema de resultados variables
	return recipe.create_result(items)

func _try_place_result(result: Item) -> bool:
	# Intentar en slot de resultado de simple craft
	var result_slot = inventory.slots[_simple_craft_result_index]
	if result_slot.is_empty():
		result_slot.item = result
		inventory.slot_changed.emit(_simple_craft_result_index)
		return true
	
	# Intentar en storage
	return _add_to_storage(result)

func _check_breakage(items: Array[Item]) -> bool:
	# TODO: Verificar si el player tiene efecto STRESS
	# if not PlayerManager.has_effect("STRESS"): return false
	
	for item in items:
		if item.can_break:
			var chance = item.data.break_chance if item.data else 0.1
			if randf() < chance:
				item.add_state(preload("res://Resources/Items/States/ItemStates/broken.tres"))
				return true
	return false

func _mark_item_dirty(item: Item):
	var cleanliness = item.get_custom_condition("cleanliness")
	if cleanliness != null:
		cleanliness.value = 0
		item.update_states()
#endregion

#region Slot Type Helpers
## Determina qué tipo de slot es un índice
func get_slot_type(index: int) -> String:
	if index < 0 or index >= inventory.slots.size():
		return "invalid"
	
	if index < _simple_craft_start_index:
		return "station"
	elif index < _simple_craft_result_index:
		return "simple_craft_input"
	elif index == _simple_craft_result_index:
		return "simple_craft_result"
	else:
		return "storage"

## Obtiene la estación para un índice de slot
func get_station_for_slot(index: int) -> Station:
	if index < 0 or index >= stations.size():
		return null
	return stations[index]
#endregion
