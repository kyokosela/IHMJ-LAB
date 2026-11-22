extends SceneTree
## Pruebas automaticas de los CRAFTEOS de la cocina. Usa la cocina REAL del Apartamento (nodo Kitchen) y las clases de tu dev.
## Comprueba que NADA se duplica ni se pierde (comidas infinitas), la regla de lo cocinado (estados de "preparation":
## no_prepared -> prepared -> cooked), la comida casera con olla y estufa (45 min), las estaciones (fregadero y estufa),
## comer desde la olla y que todo se conserva al salir de la zona y volver (incluida la estufa cocinando).
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_crafteos.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

const RUTA_BOLSA := "res://Resources/Items/Data/ingredients_bag.tres"
const RUTA_INGREDIENTES := "res://Resources/Items/Data/ingredients_unpack.tres"
const RUTA_COMIDA := "res://Resources/Items/Data/home_meal.tres"
const RUTA_OLLA := "res://Resources/Items/Data/KitchenUtils/cooking_pot.tres"

var pm
var gm
var zm
var cm
var evm
var tm
var ItemCls
var passed := 0
var failed := 0

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	var guardia := create_timer(150.0)
	guardia.timeout.connect(func(): print("  FALLA: la prueba se colgo (150 s)"); quit(2))
	pm = root.get_node("PlayerManager")
	gm = root.get_node("GameManager")
	zm = root.get_node("ZoneManager")
	cm = root.get_node("ContainerManager")
	evm = root.get_node("EventManager")
	tm = root.get_node("TimeManager")
	await create_timer(0.3).timeout
	ItemCls = load("res://Resources/Items/item.gd")
	gm.game_started = true
	_t_datos()
	await _t_cocina()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
func _item(ruta: String):
	return ItemCls.new(load(ruta))

## Una olla con ingredientes preparados dentro (como la que da "Combinar").
func _olla_con_ingredientes():
	var o = _item(RUTA_OLLA)
	o.held_item = _item(RUTA_INGREDIENTES)
	return o

## Cuantos objetos con ese id hay en TODAS las casillas de la cocina.
func _contar(kc, id: String) -> int:
	var n := 0
	for s in kc.inventory.slots:
		if not s.is_empty() and s.item.data.item_unique_name == id:
			n += 1
	return n

## Cuantos hay en las manos de Mayui.
func _contar_manos(id: String) -> int:
	var n := 0
	for it in pm.player.inventory.get_all_player_items():
		if it.data.item_unique_name == id:
			n += 1
	return n

func _ollas(kc) -> int:
	return _contar(kc, "cooking_pot") + _contar_manos("cooking_pot")

## Primera casilla de la cocina que tiene un objeto con ese id; -1 si no hay.
func _donde(kc, id: String) -> int:
	for i in range(kc.inventory.slots.size()):
		var s = kc.inventory.slots[i]
		if not s.is_empty() and s.item.data.item_unique_name == id:
			return i
	return -1

func _vaciar_entradas(kc) -> void:
	for i in kc.get_simple_craft_input_indices():
		kc.inventory.slots[i].clear()
	kc.inventory.slots[kc.get_simple_craft_result_index()].clear()
	kc.inventory.inventory_changed.emit()

## Aprieta "Combinar" muchas veces seguidas (como alguien que repite el clic). Devuelve lo que fue saliendo.
func _combinar_spam(kc) -> Array:
	var salidas := []
	for k in range(8):
		var m = kc.execute_simple_craft()
		if m != null:
			salidas.append(m)
	return salidas

func _casillas_vacias(kc, indices: Array) -> bool:
	for i in indices:
		if not kc.inventory.slots[i].is_empty():
			return false
	return true

func _reiniciar_estaciones(kc) -> void:
	for st in kc.stations:
		if st.is_locked and st.active_craft_event != "":
			evm.remove_event(st.active_craft_event)
		st.unlock()

func _entrar(origen: int) -> Node:
	zm.previous_zone = origen
	var escena : Node = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(escena)
	await create_timer(1.2).timeout
	return escena

func _salir(escena: Node) -> void:
	escena.release_player()
	root.remove_child(escena)
	escena.free()
	zm.zone_node = null
	await process_frame

# ------------------------------------------------------------------ A. datos
func _t_datos() -> void:
	print("A. Datos de las recetas y de los objetos")
	for id in ["home_meal", "ingredients", "ingredients_bag"]:
		var d = cm.item_database.get(id)
		_check("La base de objetos guarda la copia COMPLETA de '%s' (con condicion de preparacion)" % id, d != null and d.custom_conditions.size() > 0, d.resource_path if d else "no existe")
	var picar = load("res://Resources/Crafts/Kitchen/HomeMeal/ingredients_craft.tres")
	_check("Picar pide una bolsa 'no_prepared'", picar.needed_items[0].item_id == "ingredients_bag" and picar.needed_items[0].required_states == ["no_prepared"])
	_check("Picar da ingredientes ya 'prepared'", ItemCls.new(picar.result_item).has_state("prepared"))
	var meter = load("res://Resources/Crafts/Kitchen/HomeMeal/pot_add_ingredients.tres")
	_check("Meter en la olla pide una olla VACIA e ingredientes 'prepared'", meter.needed_items.size() == 2 and meter.needed_items[0].item_id == "cooking_pot" and meter.needed_items[0].exclude_if_has_held_item and meter.needed_items[1].item_id == "ingredients" and meter.needed_items[1].required_states == ["prepared"])
	var estufa = load("res://Resources/Containers/Stations/stove_station.tres")
	var cocinar = load("res://Resources/Crafts/Kitchen/HomeMeal/pot_cook_home_meal.tres")
	_check("La estufa tiene la receta de la comida casera (ademas de calentar agua)", estufa.available_crafts.size() == 2 and estufa.available_crafts[1] == cocinar)
	_check("Cocinar tarda 45 min y pide una olla con ingredientes 'prepared' dentro", cocinar.needed_time == "00:45" and cocinar.needed_items[0].required_held_item_id == "ingredients" and cocinar.needed_items[0].required_held_item_states == ["prepared"])
	var resultado = cocinar.create_result(Array([_olla_con_ingredientes()], TYPE_OBJECT, &"Resource", ItemCls))
	_check("Cocinar da una olla con la comida dentro, 'cooked' y 'hot'", resultado.data.item_unique_name == "cooking_pot" and resultado.held_item != null and resultado.held_item.data.item_unique_name == "home_meal" and resultado.held_item.has_state("cooked") and resultado.held_item.has_state("hot"))

# ------------------------------------------------------------------ B. la cocina real
func _t_cocina() -> void:
	print("B. Cocina real: cadena, regla de lo cocinado, olla, estufa y comer")
	cm.container_states.clear()
	gm.new_game()
	pm.reset_engine_state(true)
	var tarea = root.get_node("TaskManager").get_task_list_res("TUTORIAL_DOOR").get_task_res("COOK")
	tarea.task_done = false
	var escena : Node = await _entrar(-1)
	var kc = escena.get_node("Kitchen").container
	var inv = kc.inventory
	var manos = pm.player.inventory
	var res_idx : int = kc.get_simple_craft_result_index()
	var entradas : Array = kc.get_simple_craft_input_indices()
	var corte : int = kc.get_station_slot_index("cutting")
	var fregadero : int = kc.get_station_slot_index("sink")
	var estufa : int = kc.get_station_slot_index("stove")
	_reiniciar_estaciones(kc)

	# --- cocina inicial
	_check("Hay 12 casillas de almacenamiento (dos alacenas de 6)", kc.get_storage_indices().size() == 12)
	_check("Trae 2 bolsas de ingredientes y 1 olla", _contar(kc, "ingredients_bag") == 2 and _contar(kc, "cooking_pot") == 1, "bolsas %d, ollas %d" % [_contar(kc, "ingredients_bag"), _contar(kc, "cooking_pot")])
	_check("La cocina acepta guardar ollas (objetos tipo contenedor)", kc.rules.can_store(load(RUTA_OLLA)))

	# --- arrastrar no duplica ni pierde (ida y vuelta entre almacenamiento y tabla)
	var origen : int = _donde(kc, "ingredients_bag")
	for k in range(4):
		inv.interact_inventory(corte, inv, origen)
		inv.interact_inventory(origen, inv, corte)
	_check("Mover una bolsa de ida y vuelta no cambia cuantas hay", _contar(kc, "ingredients_bag") == 2 and inv.slots[origen].item != null)

	# --- picar: la bolsa se gasta y sale un grupo de ingredientes preparados
	inv.interact_inventory(corte, inv, origen)
	_check("Con la bolsa en la tabla hay receta (picar)", kc.has_valid_station_craft("cutting"))
	_check("Se puede picar", kc.start_manual_station_craft("cutting"))
	var ing = inv.slots[res_idx].item
	_check("Picar gasta la bolsa y da 1 ingredientes", _contar(kc, "ingredients_bag") == 1 and _contar(kc, "ingredients") == 1, "bolsas %d, ingredientes %d" % [_contar(kc, "ingredients_bag"), _contar(kc, "ingredients")])
	_check("Los ingredientes picados quedan 'prepared'", ing != null and ing.has_state("prepared"))
	_check("La tabla queda libre despues de picar", kc.get_station_item("cutting") == null)

	# --- COMBINAR (olla + ingredientes): nunca mas de lo que hay, esten en la casilla que esten
	var olla_idx : int = _donde(kc, "cooking_pot")
	var olla = inv.slots[olla_idx].item
	inv.slots[olla_idx].clear()
	for orden in [[0, 1], [1, 0]]:
		_vaciar_entradas(kc)
		inv.slots[entradas[orden[0]]].item = olla
		inv.slots[entradas[orden[1]]].item = _item(RUTA_INGREDIENTES)
		inv.inventory_changed.emit()
		var salidas : Array = _combinar_spam(kc)
		var s0 = salidas[0] if salidas.size() > 0 else null
		_check("Olla en la casilla %d + ingredientes en la %d: sale UNA olla con los ingredientes dentro (repitiendo el clic no sale mas)" % [orden[0] + 1, orden[1] + 1], salidas.size() == 1 and s0.data.item_unique_name == "cooking_pot" and s0.held_item != null and s0.held_item.data.item_unique_name == "ingredients" and s0.held_item.has_state("prepared"), "salieron %d" % salidas.size())
		_check("Las dos casillas de entrada quedan vacias (se gastaron la olla vieja y los ingredientes)", _casillas_vacias(kc, entradas))
		olla = _item(RUTA_OLLA)   # la de la siguiente vuelta
	_check("Las ollas que salen de 'Combinar' no se quedan en la cocina (van a las manos)", _ollas(kc) == 0)
	_vaciar_entradas(kc)
	_check("Sin nada en las casillas no sale nada", _combinar_spam(kc).is_empty())

	# --- la regla de lo cocinado (preparation: no_prepared -> prepared -> cooked)
	_vaciar_entradas(kc)
	var crudo = _item(RUTA_INGREDIENTES)
	crudo.get_custom_condition("preparation").value = 0.0
	crudo.update_states()
	_check("(prueba) un ingrediente con preparacion 0 queda 'no_prepared'", crudo.has_state("no_prepared"))
	inv.slots[entradas[0]].item = _item(RUTA_OLLA)
	inv.slots[entradas[1]].item = crudo
	inv.inventory_changed.emit()
	_check("Un ingrediente SIN preparar no se mete en la olla", kc.check_simple_craft() == null and kc.execute_simple_craft() == null)
	_vaciar_entradas(kc)
	inv.slots[entradas[0]].item = _item(RUTA_OLLA)
	inv.slots[entradas[1]].item = _item(RUTA_COMIDA)
	inv.inventory_changed.emit()
	_check("Una comida ya cocinada no se mete en la olla como ingrediente", kc.check_simple_craft() == null and kc.execute_simple_craft() == null)
	_vaciar_entradas(kc)
	inv.slots[entradas[0]].item = _item(RUTA_OLLA)
	inv.slots[entradas[1]].item = _item(RUTA_BOLSA)
	inv.inventory_changed.emit()
	_check("Una bolsa sin picar no se mete en la olla", kc.check_simple_craft() == null and kc.execute_simple_craft() == null)
	_vaciar_entradas(kc)
	var con_agua = _item(RUTA_OLLA)
	con_agua.held_item = _item("res://Resources/Items/Data/Liquids/water.tres")
	inv.slots[entradas[0]].item = con_agua
	inv.slots[entradas[1]].item = _item(RUTA_INGREDIENTES)
	inv.inventory_changed.emit()
	_check("Una olla que ya tiene agua no recibe ingredientes", kc.check_simple_craft() == null and kc.execute_simple_craft() == null)
	_vaciar_entradas(kc)
	inv.slots[corte].item = _item(RUTA_COMIDA)
	inv.inventory_changed.emit()
	_check("Una comida cocinada no se puede picar", not kc.has_valid_station_craft("cutting"))
	inv.slots[corte].clear()
	inv.slots[corte].item = _item(RUTA_INGREDIENTES)
	inv.inventory_changed.emit()
	_check("Unos ingredientes ya picados no se pueden picar otra vez", not kc.has_valid_station_craft("cutting"))
	inv.slots[corte].clear()

	# --- la olla con agua: llenar en el fregadero y calentar en la estufa (siempre hay UNA sola olla)
	_vaciar_entradas(kc)
	inv.slots[res_idx].clear()
	var nueva = _item(RUTA_OLLA)
	inv.slots[kc.get_storage_indices()[0]].item = nueva
	var donde_olla : int = _donde(kc, "cooking_pot")
	var mano : int = manos.get_hands_indices()[0]
	manos.inventory.interact_inventory(mano, inv, donde_olla)
	_check("Se puede sacar la olla de la alacena a las manos", _contar_manos("cooking_pot") == 1 and _contar(kc, "cooking_pot") == 0)
	inv.interact_inventory(fregadero, manos.inventory, mano)
	_check("La olla vacia en el fregadero tiene receta (llenarla)", kc.has_valid_station_craft("sink"))
	_check("Se puede llenar la olla", kc.start_manual_station_craft("sink"))
	_check("Llenarla no duplica ni pierde la olla", _ollas(kc) == 1, "ollas %d" % _ollas(kc))
	_check("El fregadero queda libre", kc.get_station_item("sink") == null)
	var donde : int = _donde(kc, "cooking_pot")
	var con_agua2 = inv.slots[donde].item if donde != -1 else null
	_check("La olla ahora trae agua", con_agua2 != null and con_agua2.held_item != null and con_agua2.held_item.data.item_unique_name == "water")
	inv.interact_inventory(fregadero, inv, donde)
	_check("Una olla que ya tiene agua no se vuelve a llenar", not kc.has_valid_station_craft("sink"))
	inv.interact_inventory(estufa, inv, fregadero)
	_check("Una olla con agua en la estufa tiene receta (calentar)", kc.has_valid_station_craft("stove"))
	var estacion = kc.get_station("stove")
	_check("Se puede calentar", kc.start_manual_station_craft("stove"))
	_check("La estufa queda ocupada mientras calienta", estacion.is_locked)
	_check("No se puede empezar otra vez mientras trabaja", not kc.start_manual_station_craft("stove"))
	tm.minutes_delta.emit(25)   # pasan los 25 min
	_check("A los 25 min la estufa se libera sola", not estacion.is_locked and kc.get_station_item("stove") == null)
	_check("Calentar no duplica ni pierde la olla", _ollas(kc) == 1, "ollas %d" % _ollas(kc))
	donde = _donde(kc, "cooking_pot")
	var caliente = inv.slots[donde].item if donde != -1 else null
	_check("El agua de la olla queda caliente", caliente != null and caliente.held_item != null and caliente.held_item.has_state("hot"))
	inv.interact_inventory(estufa, inv, donde)
	_check("Una olla con agua YA caliente no se vuelve a calentar", not kc.has_valid_station_craft("stove"))
	inv.slots[estufa].clear()
	inv.slots[res_idx].clear()

	# --- LA COMIDA CASERA: olla + ingredientes -> estufa 45 min -> comer desde la olla
	var pot = _olla_con_ingredientes()
	inv.slots[estufa].item = pot
	inv.inventory_changed.emit()
	_check("Una olla con ingredientes en la estufa tiene receta (cocinar la comida)", kc.has_valid_station_craft("stove"))
	_check("Se puede cocinar la comida", kc.start_manual_station_craft("stove"))
	_check("La estufa queda ocupada cocinando", estacion.is_locked)
	tm.minutes_delta.emit(44)
	_check("A los 44 min todavia no esta lista (la olla sigue en la estufa con los ingredientes)", estacion.is_locked and kc.get_station_item("stove") != null and kc.get_station_item("stove").held_item.data.item_unique_name == "ingredients" and _contar(kc, "home_meal") == 0)
	tm.minutes_delta.emit(1)
	_check("A los 45 min la estufa se libera", not estacion.is_locked and kc.get_station_item("stove") == null)
	_check("Cocinar no duplica ni pierde la olla ni deja ingredientes sueltos", _ollas(kc) == 1 and _contar(kc, "ingredients") == 0 and _contar(kc, "home_meal") == 0, "ollas %d" % _ollas(kc))
	donde = _donde(kc, "cooking_pot")
	var lista = inv.slots[donde].item if donde != -1 else null
	var comida = lista.held_item if lista != null else null
	_check("La olla trae UNA comida casera, cocinada y caliente", comida != null and comida.data.item_unique_name == "home_meal" and comida.has_state("cooked") and comida.has_state("hot"))
	inv.slots[donde].clear()
	manos.add_item(lista)
	pm.add_effect(load("res://Resources/Effects/Effects/hunger.tres").duplicate())
	var energia0 : float = pm.get_stat_value("ENERGY")
	var mano_idx : int = -1
	for i in manos.get_hands_indices():
		if manos.get_slot(i).item == lista:
			mano_idx = i
	manos.use_item_at(mano_idx)
	_check("Comer de la olla: sube la energia, quita el Hambre y cuenta como comida casera", pm.get_stat_value("ENERGY") > energia0 and not pm.has_effect("HUNGER") and pm.daily.home_meals == 1, "energia %.1f -> %.1f" % [energia0, pm.get_stat_value("ENERGY")])
	_check("Comer de la olla marca la tarea COOK", tarea.task_done)
	_check("La comida se gasta y la olla queda vacia en las manos (una sola olla)", lista.held_item == null and _contar_manos("cooking_pot") == 1 and _ollas(kc) == 1)
	var energia1 : float = pm.get_stat_value("ENERGY")
	manos.use_item_at(mano_idx)
	_check("La olla vacia no se puede 'comer' otra vez (no da energia ni comidas)", pm.get_stat_value("ENERGY") <= energia1 and pm.daily.home_meals == 1)
	manos.remove_from_hands(lista)

	# --- persistencia: salir y volver conserva lo guardado, con su contenido y sus estados
	_vaciar_entradas(kc)
	var libre : int = kc.get_storage_indices()[11]
	inv.slots[libre].clear()
	inv.slots[libre].item = _item(RUTA_INGREDIENTES)
	var libre2 : int = kc.get_storage_indices()[10]
	inv.slots[libre2].clear()
	inv.slots[libre2].item = _olla_con_ingredientes()
	var antes := {}
	for id in ["ingredients_bag", "ingredients", "home_meal", "cooking_pot"]:
		antes[id] = _contar(kc, id)
	await _salir(escena)
	escena = await _entrar(1)
	kc = escena.get_node("Kitchen").container
	inv = kc.inventory
	var igual := true
	var detalle := ""
	for id in antes.keys():
		if _contar(kc, id) != antes[id]:
			igual = false
			detalle += " %s: %d -> %d;" % [id, antes[id], _contar(kc, id)]
	_check("Al volver a la cocina queda lo mismo que se dejo (sin duplicar ni perder)", igual, detalle)
	var idx_ing : int = _donde(kc, "ingredients")
	_check("Los ingredientes guardados siguen 'prepared' al volver", idx_ing != -1 and inv.slots[idx_ing].item.has_state("prepared"))
	var olla_guardada = inv.slots[kc.get_storage_indices()[10]].item
	_check("La olla guardada con ingredientes los conserva al volver", olla_guardada != null and olla_guardada.held_item != null and olla_guardada.held_item.data.item_unique_name == "ingredients" and olla_guardada.held_item.has_state("prepared"))

	# --- la estufa cocinando mientras sales a otra zona
	estufa = kc.get_station_slot_index("stove")
	estacion = kc.get_station("stove")
	_reiniciar_estaciones(kc)
	_vaciar_entradas(kc)
	inv.slots[estufa].item = _olla_con_ingredientes()
	inv.inventory_changed.emit()
	_check("(prueba) se empieza a cocinar antes de salir", kc.start_manual_station_craft("stove") and estacion.is_locked)
	await _salir(escena)
	tm.minutes_delta.emit(20)   # 20 min fuera
	escena = await _entrar(1)
	kc = escena.get_node("Kitchen").container
	inv = kc.inventory
	_check("Al volver (a los 20 min) la estufa sigue cocinando con su olla", estacion.is_locked and kc.get_station_item("stove") != null and kc.get_station_item("stove").held_item != null)
	_check("El evento de la estufa se rehizo con la cocina nueva y le quedan unos 25 min", evm.get_event(estacion.active_craft_event) != null and evm.get_event(estacion.active_craft_event).time_lapse_value == "00:25", str(evm.get_event(estacion.active_craft_event)))
	tm.minutes_delta.emit(25)
	_check("Pasados los 45 min la comida sale sola", not estacion.is_locked and _donde(kc, "cooking_pot") != -1 and inv.slots[_donde(kc, "cooking_pot")].item.held_item.data.item_unique_name == "home_meal")
	_vaciar_entradas(kc)
	for i in kc.get_storage_indices():
		if not inv.slots[i].is_empty() and inv.slots[i].item.data.item_unique_name == "cooking_pot":
			inv.slots[i].clear()
	_reiniciar_estaciones(kc)
	inv.slots[estufa].item = _olla_con_ingredientes()
	inv.inventory_changed.emit()
	_check("(prueba) se empieza a cocinar otra vez", kc.start_manual_station_craft("stove") and estacion.is_locked)
	await _salir(escena)
	tm.minutes_delta.emit(60)   # se pasa de los 45 min estando fuera
	escena = await _entrar(1)
	kc = escena.get_node("Kitchen").container
	inv = kc.inventory
	var d2 : int = _donde(kc, "cooking_pot")
	_check("Si la comida se termino estando fuera, al volver ya esta lista y la estufa libre", not estacion.is_locked and d2 != -1 and inv.slots[d2].item.held_item != null and inv.slots[d2].item.held_item.data.item_unique_name == "home_meal", "olla en %d" % d2)
	_check("Y no queda nada duplicado ni ingredientes sueltos", _contar(kc, "ingredients") == 1 and kc.get_station_item("stove") == null, "ingredientes %d" % _contar(kc, "ingredients"))
	await _salir(escena)
