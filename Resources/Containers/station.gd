extends Resource
class_name Station
## Define una estación de crafteo (stove, sink, cutting board)
## Cada estación tiene un util inherente y restricciones de qué items puede aceptar

signal craft_started(recipe: Crafts)
signal craft_completed(result: Item)
signal craft_failed(reason: String)
signal locked_changed(is_locked: bool)

@export_group("Identity")
@export var station_id: String = ""  ## Identificador único (stove, sink, cutting)
@export var station_name: String = ""  ## Nombre para mostrar en UI
@export var inherent_util: String = ""  ## Util que provee esta estación (heat, water, cutting)

@export_group("Crafting")
@export var available_crafts: Array[Crafts] = []  ## Recetas disponibles en esta estación
@export var slot_count: int = 1  ## Número de slots de input

@export_group("Restrictions")
## Utils que el item debe proveer para entrar (ej: stove requiere "cookware")
@export var required_provided_utils: Array[String] = []
## El item debe tener algo contenido (held_item != null)
@export var required_held_item: bool = false
## Estados que bloquean la entrada del item
@export var blocked_states: Array[String] = ["broken"]

## Estado de la estación
var is_locked: bool = false :
	set(v):
		is_locked = v
		locked_changed.emit(v)

var active_craft_event: String = ""  ## Nombre del LapseEvent activo
var locked_slot_indices: Array[int] = []  ## Índices de slots bloqueados durante craft

## Verifica si un item puede entrar en esta estación
func can_accept(item: Item) -> bool:
	if item == null: return false
	if is_locked: return false
	
	# Verificar utils requeridos
	if not required_provided_utils.is_empty():
		var has_required = false
		for util in required_provided_utils:
			if item.data.has_util(util):
				has_required = true
				break
		if not has_required:
			return false
	
	# Verificar que tenga contenido si es requerido
	if required_held_item and not item.has_held_item():
		return false
	
	# Verificar estados bloqueados
	for state in blocked_states:
		if item.has_state(state):
			return false
	
	return true

## Obtiene la razón por la que un item no puede entrar
func get_rejection_reason(item: Item) -> String:
	if item == null: 
		return "ITEM_NULL"
	
	if is_locked:
		return "STATION_BUSY"
	
	if not required_provided_utils.is_empty():
		var has_required = false
		for util in required_provided_utils:
			if item.data.has_util(util):
				has_required = true
				break
		if not has_required:
			return "REQUIRES_UTIL"  # "Necesitas un recipiente adecuado"
	
	if required_held_item and not item.has_held_item():
		return "CONTAINER_EMPTY"  # "El recipiente está vacío"
	
	for state in blocked_states:
		if item.has_state(state):
			return "ITEM_STATE_BLOCKED"  # "Este item está roto"
	
	return ""

## Busca una receta válida para los items dados
func find_valid_recipe(items: Array[Item]) -> Crafts:
	for recipe in available_crafts:
		if recipe == null: continue
		if _recipe_matches(recipe, items):
			return recipe
	return null

## Verifica si una receta coincide con los items
func _recipe_matches(recipe: Crafts, items: Array[Item]) -> bool:
	if items.size() < recipe.needed_items.size():
		return false
	# Verificar que todos los needed_items están presentes
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

## Bloquea la estación durante un craft con tiempo
func lock_for_craft(event_name: String, slot_indices: Array[int] = []) -> void:
	is_locked = true
	active_craft_event = event_name
	locked_slot_indices = slot_indices

## Desbloquea la estación después de un craft
func unlock() -> void:
	is_locked = false
	active_craft_event = ""
	locked_slot_indices.clear()
