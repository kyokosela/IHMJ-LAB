extends SceneTree
## El "jugador torpe": en la manana del tutorial insiste en todo, arrastra y pulsa al azar en la cocina (con el raton de
## verdad), se va con la estufa cocinando... y se comprueba que nada se pierde ni se duplica y que despues TODAVIA se puede
## terminar la manana. Las partidas al azar usan semillas fijas: si algo falla, se repite igual.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_torpe.gd
##   ... -s res://Tools/probar_torpe.gd -- 40 7 8 9      (40 acciones al azar con cada una de las semillas 7, 8 y 9)
## Termina con codigo 0 si todo pasa y 1 si algo falla.

const UNIDADES := ["ingredients_bag", "ingredients", "home_meal"]
const COCINA_DESDE := Vector2(120, 56) ## baldosa junto a la cocina, mirando a la derecha
const NEUTRO := Vector2(104, 72) ## baldosa del cuarto sin nada alrededor

var pm
var gm
var tk
var tm
var zm
var ev
var dlg
var passed := 0
var failed := 0
var dichos : Array = []
var raton := Vector2.ZERO
var azar := RandomNumberGenerator.new()
var bitacora : Array = []
var agua_vaciada := 0

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var acciones := 45
	var semillas : Array = [1, 2]
	if argumentos.size() >= 2:
		acciones = int(argumentos[0])
		semillas = Array(argumentos.slice(1)).map(func(a: String) -> int: return int(a))
	var limite : float = 200.0 + semillas.size() * acciones * 2.5
	var guardia := create_timer(limite)
	guardia.timeout.connect(func(): print("  FALLA: la prueba se colgo (%d s)" % limite); quit(2))
	pm = root.get_node("PlayerManager")
	gm = root.get_node("GameManager")
	tk = root.get_node("TaskManager")
	tm = root.get_node("TimeManager")
	zm = root.get_node("ZoneManager")
	ev = root.get_node("EventManager")
	dlg = root.get_node("Dialogic")
	await create_timer(0.3).timeout
	dlg.Text.text_started.connect(func(info) -> void: dichos.append(str(info.get("text", "")).strip_edges()))
	await _despertar()
	await _insistir_antes_de_la_ducha()
	await _insistir_con_la_ducha()
	await _armario()
	await _olla_con_agua()
	for semilla in semillas:
		await _cocina_al_azar(semilla, acciones)
	await _terminar_la_manana()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ manos y raton
func _tecla(codigo: Key) -> void:
	for presionada in [true, false]:
		var tecla := InputEventKey.new()
		tecla.keycode = codigo
		tecla.physical_keycode = codigo
		tecla.pressed = presionada
		Input.parse_input_event(tecla)
		await process_frame

## Pasa con Z todo lo que se este diciendo (y lo que quede en cola).
func _calma() -> void:
	await create_timer(0.25).timeout
	for i in 24:
		if dlg.current_timeline == null:
			break
		await _tecla(KEY_Z)
		await create_timer(0.3).timeout
	await create_timer(0.15).timeout

## Pulsa Z (o hace otra cosa), escucha lo que se diga y lo pasa. Devuelve las lineas oidas.
func _hacer(accion: Callable = Callable()) -> Array:
	dichos.clear()
	if accion.is_valid():
		await accion.call()
	else:
		await _tecla(KEY_Z)
	await _calma()
	return dichos.duplicate()

func _poner(pos: Vector2) -> void:
	pm.player.movement.tile_destination = pos
	pm.player.global_position = pos

func _junto(pos: Vector2, mirando: Vector2) -> void:
	_poner(pos)
	pm.player.set_facing_direction(mirando)
	for i in 6:
		await physics_frame

## Se aleja de la puerta y vuelve a pisarla.
func _pisar(desde: Vector2, puerta: Vector2) -> void:
	_poner(desde)
	for i in 6:
		await physics_frame
	_poner(puerta)
	for i in 6:
		await physics_frame

## Cambia de zona desde un punto sin puertas debajo (como haria quien llega a otra puerta).
func _ir_a_zona(zona: int) -> void:
	if zm.zone_node.zone_id == 0:
		_poner(NEUTRO)
		for i in 6:
			await physics_frame
	zm.change_zone(zona)
	for i in 80:
		await create_timer(0.1).timeout
		if zm.zone_node != null and is_instance_valid(zm.zone_node) and zm.zone_node.zone_id == zona and not zm._changing_zone:
			break
	await create_timer(0.3).timeout

func _raton(posicion: Vector2, boton: MouseButton, presionado: bool) -> void:
	var clic := InputEventMouseButton.new()
	clic.button_index = boton
	clic.pressed = presionado
	clic.position = posicion
	clic.global_position = posicion
	root.push_input(clic, true)
	await process_frame

func _mover_raton(posicion: Vector2, con_boton: bool = false) -> void:
	var mov := InputEventMouseMotion.new()
	mov.position = posicion
	mov.global_position = posicion
	mov.relative = posicion - raton
	raton = posicion
	mov.button_mask = MOUSE_BUTTON_MASK_LEFT if con_boton else 0
	root.push_input(mov, true)
	await process_frame

func _clic(control: Control, boton: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	if control == null:
		return
	var centro : Vector2 = control.get_global_rect().get_center()
	await _mover_raton(centro)
	await _raton(centro, boton, true)
	await _raton(centro, boton, false)
	await create_timer(0.08).timeout

func _arrastrar(origen: Control, destino: Control) -> void:
	if origen == null or destino == null:
		return
	var a : Vector2 = origen.get_global_rect().get_center()
	var b : Vector2 = destino.get_global_rect().get_center()
	await _mover_raton(a)
	await _raton(a, MOUSE_BUTTON_LEFT, true)
	for i in range(1, 6):
		await _mover_raton(a.lerp(b, i / 5.0), true)
	await _raton(b, MOUSE_BUTTON_LEFT, false)
	await create_timer(0.1).timeout

func _tarea(id: String) -> bool:
	return tk.get_task_list_res("TUTORIAL_DOOR").get_task_res(id).task_done

func _libre_para_seguir() -> bool:
	return gm.modal_count == 0 and dlg.current_timeline == null and pm.player.movement.can_move

# ------------------------------------------------------------------ 1. insistir antes de la ducha
func _despertar() -> void:
	gm.game_started = false
	zm.previous_zone = -1
	var casa : Node = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(casa)
	current_scene = casa
	await create_timer(1.2).timeout
	await _calma()

func _insistir_antes_de_la_ducha() -> void:
	print("A. Insistir en todo antes de ducharse")
	var casa : Node = zm.zone_node
	var energia0 : float = pm.get_stat_value("ENERGY")
	var ultima : Array = []
	var calladas := 0
	for i in 12:
		ultima = await _hacer(_pisar.bind(Vector2(120, 8), Vector2(120, -8)))
		if ultima.is_empty():
			calladas += 1
	_check("La puerta responde las 12 veces (no se queda muda)", calladas == 0, "%d veces sin decir nada" % calladas)
	_check("Tras insistir en la puerta, Mayui sigue en casa y puede moverse", zm.zone_node == casa and _libre_para_seguir())
	var muebles := {
		"cama": [Vector2(88, 120), Vector2.RIGHT], "armario": [Vector2(120, 104), Vector2.RIGHT],
		"nevera": [COCINA_DESDE, Vector2.RIGHT], "calendario": [Vector2(40, 72), Vector2.UP],
	}
	for mueble : String in muebles:
		var mudas := 0
		for i in 7:
			await _junto(muebles[mueble][0], muebles[mueble][1])
			if (await _hacer()).is_empty():
				mudas += 1
		_check("%s: responde las 7 veces y deja seguir" % mueble.capitalize(), mudas == 0 and _libre_para_seguir(), "%d sin decir nada" % mudas)
	for i in 7:
		await _junto(Vector2(40, 72), Vector2.LEFT)
		await _hacer()
	_check("Escritorio: insistir no traba nada", _libre_para_seguir())
	for i in 7:
		await _hacer(_pisar.bind(Vector2(56, 136), Vector2(56, 152)))
	_check("Balcon: insistir no traba ni saca a Mayui", zm.zone_node == casa and _libre_para_seguir())
	var energia : float = pm.get_stat_value("ENERGY")
	_check("Insistir no deja a Mayui sin energia para ducharse", energia >= 20.0, "%.1f -> %.1f" % [energia0, energia])
	print("   (tras insistir en todo: %s, energia %.1f)" % [tm.get_current_time(), energia])

# ------------------------------------------------------------------ 2. la ducha y el lavamanos
func _insistir_con_la_ducha() -> void:
	print("B. La ducha una y otra vez, y el lavamanos sin comer")
	await _ir_a_zona(4)
	await _junto(Vector2(40, 8), Vector2.LEFT)
	await _hacer()
	_check("Se ducha", _tarea("BATHE") and pm.get_outfit_id() == "towel", pm.get_outfit_id())
	var toalla : String = pm.get_outfit_id()
	for i in 10:
		await _junto(Vector2(40, 8), Vector2.LEFT)
		await _hacer()
	_check("Insistir en la ducha no traba ni cambia nada", _libre_para_seguir() and pm.get_outfit_id() == toalla and pm.get_stat_value("ENERGY") >= 10.0,
			"energia %.1f" % pm.get_stat_value("ENERGY"))
	var mudas := 0
	for i in 7:
		await _junto(Vector2(56, 24), Vector2.UP)
		if (await _hacer()).is_empty():
			mudas += 1
	_check("Lavamanos sin comer: responde las 7 veces", mudas == 0 and _libre_para_seguir(), "%d sin decir nada" % mudas)
	await _ir_a_zona(0)

# ------------------------------------------------------------------ 3. el armario a las prisas
func _armario() -> void:
	print("C. El armario a las prisas")
	await _junto(Vector2(120, 104), Vector2.RIGHT)
	await _tecla(KEY_Z)
	await create_timer(0.4).timeout
	var armario : Control = zm.zone_node.get_node("UILayer/WardrobeUI")
	_check("Se abre el armario", armario.visible)
	for i in 4:
		if armario.garment_slots["home"].is_visible_in_tree():
			await _clic(armario.garment_slots["home"].get_node("Hit"))
			await _calma()
	_check("La ropa de casa no se puede poner en la manana", pm.get_outfit_id() == "towel", pm.get_outfit_id())
	await _clic(armario.garment_slots["work"].get_node("Hit"))
	await _tecla(KEY_ESCAPE)                                  # Esc a mitad del cambio
	await _clic(armario.garment_slots["work"].get_node("Hit"))  # y otro clic
	await create_timer(1.4).timeout
	await _calma()
	_check("Esc y clics a mitad del cambio: acaba con el uniforme puesto", pm.get_outfit_id() == "work" and _tarea("CLOTHES"), pm.get_outfit_id())
	await _tecla(KEY_ESCAPE)
	await create_timer(0.3).timeout
	_check("Cierra con Esc y Mayui puede moverse", not armario.visible and _libre_para_seguir(), "modal %d" % gm.modal_count)

# ------------------------------------------------------------------ 4. la cocina al azar
func _cocina() -> Node:
	return zm.zone_node.get_node("Kitchen").container

func _ui() -> Control:
	return zm.zone_node.get_node("UILayer/KitchenMultiUI")

func _abrir_cocina() -> void:
	if dlg.current_timeline != null:   # Mayui esta hablando (p. ej. la estufa vacia): se pasa con Z, como una persona
		await _calma()
	if _ui().visible:
		return
	await _calma()
	await _junto(COCINA_DESDE, Vector2.RIGHT)
	await _tecla(KEY_Z)
	await create_timer(0.3).timeout

func _cerrar_cocina() -> void:
	if _ui().visible:
		await _tecla(KEY_ESCAPE)
		await create_timer(0.2).timeout
	await _calma()

## Deja la cocina como al empezar: 2 bolsas y la olla en la alacena, nada en las manos y la tarea de comer sin hacer.
func _cocina_de_cero() -> void:
	await _cerrar_cocina()
	var kc = _cocina()
	for estacion in kc.stations:
		if estacion.is_locked:
			ev.remove_event(estacion.active_craft_event)
			estacion.unlock()
	kc.inventory.clear()
	pm.player.inventory.inventory.clear()
	for ruta in ["res://Resources/Items/Data/ingredients_bag.tres", "res://Resources/Items/Data/ingredients_bag.tres",
			"res://Resources/Items/Data/KitchenUtils/cooking_pot.tres"]:
		kc.add_item_by_data(load(ruta))
	pm.daily.home_meals = 0
	tk.get_task_list_res("TUTORIAL_DOOR").get_task_res("COOK").task_done = false

func _anotar(item, cuenta: Dictionary, vistos: Dictionary) -> void:
	var nombre : String = item.data.item_unique_name
	cuenta[nombre] = cuenta.get(nombre, 0) + 1
	if vistos.has(item.get_instance_id()):
		cuenta["repetido"] = cuenta.get("repetido", 0) + 1
	vistos[item.get_instance_id()] = true
	if item.held_item != null:
		_anotar(item.held_item, cuenta, vistos)

func _inventario_total() -> Dictionary:
	var cuenta := {}
	var vistos := {}
	for lista in [_cocina().inventory.slots, pm.player.inventory.inventory.slots]:
		for casilla in lista:
			if not casilla.is_empty():
				_anotar(casilla.item, cuenta, vistos)
	return cuenta

## "" si todo esta en orden; si no, que se rompio.
func _revisar() -> String:
	var cuenta := _inventario_total()
	var unidades : int = pm.daily.home_meals
	for nombre in UNIDADES:
		unidades += cuenta.get(nombre, 0)
	if unidades != 2:
		return "hay %d raciones de 2 (comidas %d, %s)" % [unidades, pm.daily.home_meals, str(cuenta)]
	if cuenta.get("cooking_pot", 0) != 1:
		return "hay %d ollas (%s)" % [cuenta.get("cooking_pot", 0), str(cuenta)]
	if cuenta.get("repetido", 0) > 0:
		return "el mismo objeto esta en dos sitios"
	var kc = _cocina()
	for estacion in kc.stations:
		if estacion.is_locked and kc.get_station_item(estacion.station_id) == null:
			return "la estacion %s trabaja sin nada encima" % estacion.station_id
	var esperado : int = 1 if _ui().visible else 0
	if dlg.current_timeline == null and gm.modal_count != esperado:
		return "contador de pantallas %d (cocina %s)" % [gm.modal_count, "abierta" if _ui().visible else "cerrada"]
	return ""

## La casilla de la pantalla para ese indice (null si no esta a la vista).
func _casilla(rejillas: Array, indice: int) -> Control:
	for rejilla in rejillas:
		if rejilla == null:
			continue
		for c in rejilla.get_children():
			if not c.is_queued_for_deletion() and c.get("slot_index") == indice and c.is_visible_in_tree():
				return c
	return null

func _casilla_cocina(indice: int) -> Control:
	var ui = _ui()
	var kc = _cocina()
	match kc.get_slot_type(indice):
		"station":
			return _casilla([ui.station_containers[kc.get_station_for_slot(indice).station_id]], indice)
		"simple_craft_input":
			return _casilla([ui.simple_craft_input_grid], indice)
		"simple_craft_result":
			return _casilla([ui.simple_craft_result_grid], indice)
	return _casilla([ui.storage_grid, ui.storage_grid_2], indice)

func _casilla_mano(indice: int) -> Control:
	return _casilla([_ui().player_hands_grid], indice)

## Todas las casillas a la vista: [control, tiene_objeto]
func _casillas_visibles() -> Array:
	var lista : Array = []
	var kc = _cocina()
	for i in kc.inventory.slots.size():
		var c := _casilla_cocina(i)
		if c != null:
			lista.append([c, not kc.inventory.slots[i].is_empty(), "cocina %d" % i])
	for i in pm.player.inventory.get_hands_indices():
		var c := _casilla_mano(i)
		if c != null:
			lista.append([c, not pm.player.inventory.inventory.slots[i].is_empty(), "mano %d" % i])
	return lista

func _botones_disponibles() -> Array:
	var ui = _ui()
	var lista : Array = []
	for id in ui.station_craft_buttons:
		var b : Button = ui.station_craft_buttons[id]
		if b.is_visible_in_tree() and not b.disabled:
			lista.append([b, id])
	if ui.craft_button.is_visible_in_tree() and not ui.craft_button.disabled:
		lista.append([ui.craft_button, "combinar"])
	return lista

func _abrir_alacenas() -> void:
	var ui = _ui()
	if not ui.storage_grid.is_visible_in_tree():
		await _clic(ui.get_node("Panel/MainContainer/ShelfButton"))
	if not ui.storage_grid_2.is_visible_in_tree():
		await _clic(ui.get_node("Panel/MainContainer/ShelfLeftButton"))

func _confirmar_espera() -> void:
	var ui = _ui()
	await _clic(ui.station_wait_buttons["stove"])
	await create_timer(0.15).timeout
	if ui.wait_dialog.visible:
		ui.wait_dialog.get_ok_button().pressed.emit()
	await create_timer(0.2).timeout

## Una accion cualquiera de un jugador perdido. Devuelve lo que hizo.
func _accion_al_azar(viajes: Array) -> String:
	await _abrir_cocina()
	var dado := azar.randf()
	if dado < 0.52:
		var visibles := _casillas_visibles()
		var con_objeto := visibles.filter(func(c: Array) -> bool: return c[1])
		if con_objeto.is_empty():
			await _abrir_alacenas()
			return "abre las alacenas"
		var de : Array = con_objeto[azar.randi() % con_objeto.size()]
		var a : Array = visibles[azar.randi() % visibles.size()]
		await _arrastrar(de[0], a[0])
		return "arrastra %s -> %s" % [de[2], a[2]]
	if dado < 0.74:
		var botones := _botones_disponibles()
		if botones.is_empty():
			await _abrir_alacenas()
			return "abre las alacenas"
		var boton : Array = botones[azar.randi() % botones.size()]
		await _clic(boton[0])
		return "pulsa %s" % boton[1]
	if dado < 0.80:
		if _cocina().is_station_locked("stove"):
			await _confirmar_espera()
			return "espera a la estufa"
		await _abrir_alacenas()
		return "abre las alacenas"
	if dado < 0.90:
		var mano : int = azar.randi() % 2
		await _clic(_casilla_mano(mano), MOUSE_BUTTON_RIGHT)
		return "usa la mano %d" % mano
	if dado < 0.94:
		var boton_alacena : String = "ShelfButton" if azar.randf() < 0.5 else "ShelfLeftButton"
		await _clic(_ui().get_node("Panel/MainContainer/" + boton_alacena))
		return "clic en " + boton_alacena
	if dado < 0.97 or viajes[0] >= 2:
		await _cerrar_cocina()
		return "cierra la cocina"
	viajes[0] += 1
	await _cerrar_cocina()
	await _ir_a_zona(4)
	await _ir_a_zona(0)
	return "va al bano y vuelve"

func _olla_con_agua() -> void:
	print("D0. La olla llena de agua")
	await _cocina_de_cero()
	await _abrir_cocina()
	await _abrir_alacenas()
	await _llevar("cooking_pot", "cocina", _cocina().get_station_slot_index("sink"))
	await _clic(_ui().station_craft_buttons["sink"])
	var olla := _donde_esta("cooking_pot")
	_check("El fregadero llena la olla", not olla.is_empty() and olla[2].held_item != null and olla[2].held_item.data.item_unique_name == "water")
	var como := await _cocinar_como_sea()
	_check("Con la olla llena de agua todavia se puede cocinar y comer", como == "", como)
	_check("Con la olla de agua nada se pierde", _revisar() == "", _revisar())
	await _cerrar_cocina()

func _cocina_al_azar(semilla: int, acciones: int) -> void:
	print("D. Cocina al azar, semilla %d (%d acciones)" % [semilla, acciones])
	azar.seed = semilla
	bitacora.clear()
	await _cocina_de_cero()
	await _abrir_cocina()
	await _abrir_alacenas()
	var viajes := [0]
	var roto := ""
	for i in acciones:
		bitacora.append(await _accion_al_azar(viajes))
		roto = _revisar()
		if roto != "":
			break
	_check("Semilla %d: nada se pierde ni se duplica" % semilla, roto == "", "%s | ultimas: %s" % [roto, str(bitacora.slice(-6))])
	var como := await _cocinar_como_sea()
	_check("Semilla %d: despues del desorden todavia se puede cocinar y comer" % semilla, como == "", como)
	_check("Semilla %d: al terminar nada se perdio ni se duplico" % semilla, _revisar() == "", _revisar())
	await _cerrar_cocina()
	_check("Semilla %d: cierra la cocina y puede moverse" % semilla, _libre_para_seguir(), "modal %d" % gm.modal_count)

# ------------------------------------------------------------------ cocinar desde cualquier estado
func _donde_esta(nombre: String) -> Array:
	var kc = _cocina()
	for i in kc.inventory.slots.size():
		if not kc.inventory.slots[i].is_empty() and kc.inventory.slots[i].item.data.item_unique_name == nombre:
			return ["cocina", i, kc.inventory.slots[i].item]
	for i in pm.player.inventory.inventory.slots.size():
		var casilla = pm.player.inventory.inventory.slots[i]
		if not casilla.is_empty() and casilla.item.data.item_unique_name == nombre:
			return ["mano", i, casilla.item]
	return []

func _control_de(sitio: Array) -> Control:
	return _casilla_cocina(sitio[1]) if sitio[0] == "cocina" else _casilla_mano(sitio[1])

## Deja libre una casilla de la cocina o de la mano llevando lo que tenga a un hueco de la alacena.
func _despejar(sitio: String, indice: int, salvo = null) -> void:
	var kc = _cocina()
	var casilla = kc.inventory.slots[indice] if sitio == "cocina" else pm.player.inventory.inventory.slots[indice]
	if casilla.is_empty() or casilla.item == salvo:
		return
	for hueco in kc.get_storage_indices():
		if kc.inventory.slots[hueco].is_empty():
			await _arrastrar(_control_de([sitio, indice]), _casilla_cocina(hueco))
			return

## Lleva un objeto a una casilla de la cocina o a una mano.
func _llevar(nombre: String, sitio: String, indice: int) -> void:
	var origen := _donde_esta(nombre)
	if origen.is_empty() or (origen[0] == sitio and origen[1] == indice):
		return
	await _despejar(sitio, indice, origen[2])
	origen = _donde_esta(nombre)
	await _arrastrar(_control_de(origen), _control_de([sitio, indice]))

## Como una persona que ya sabe cocinar: parte de como haya quedado todo. "" si consigue comer.
func _cocinar_como_sea() -> String:
	var kc = _cocina()
	var estufa : int = kc.get_station_slot_index("stove")
	var tabla : int = kc.get_station_slot_index("cutting")
	var entradas : Array = kc.get_simple_craft_input_indices()
	var pasos : Array = []
	for vuelta in 14:
		if pm.daily.home_meals > 0 and _tarea("COOK"):
			return ""
		if pm.daily.home_meals >= 2:
			return "se acabaron las raciones sin marcar la tarea"
		await _abrir_cocina()
		await _abrir_alacenas()
		if kc.is_station_locked("stove"):
			pasos.append("espera")
			await _confirmar_espera()
			continue
		var olla := _donde_esta("cooking_pot")
		if olla.is_empty():
			return "no hay olla"
		var dentro : String = "" if olla[2].held_item == null else olla[2].held_item.data.item_unique_name
		match dentro:
			"home_meal":
				pasos.append("come")
				await _llevar("cooking_pot", "mano", 0)
				await _clic(_casilla_mano(0), MOUSE_BUTTON_RIGHT)
			"water":
				pasos.append("vacia el agua en el fregadero")
				agua_vaciada += 1
				await _llevar("cooking_pot", "cocina", kc.get_station_slot_index("sink"))
				await _clic(_ui().station_craft_buttons["sink"])
			"ingredients":
				pasos.append("a la estufa")
				await _llevar("cooking_pot", "cocina", estufa)
				await _clic(_ui().station_craft_buttons["stove"])
			_:
				var picados := _donde_esta("ingredients")
				if not picados.is_empty():
					pasos.append("combina")
					await _despejar("cocina", kc.get_simple_craft_result_index())
					await _llevar("cooking_pot", "cocina", entradas[0])
					await _llevar("ingredients", "cocina", entradas[1])
					await _clic(_ui().craft_button)
					await _despejar_resultado_a_estufa(estufa)
				elif not _donde_esta("ingredients_bag").is_empty():
					pasos.append("pica")
					await _llevar("ingredients_bag", "cocina", tabla)
					await _clic(_ui().station_craft_buttons["cutting"])
				else:
					return "no quedan ingredientes (%s)" % str(_inventario_total())
	return "no lo consigue: %s | %s" % [str(pasos), str(_inventario_total())]

func _despejar_resultado_a_estufa(estufa: int) -> void:
	var kc = _cocina()
	var resultado : int = kc.get_simple_craft_result_index()
	if kc.inventory.slots[resultado].is_empty():
		return
	await _despejar("cocina", estufa)
	await _arrastrar(_casilla_cocina(resultado), _casilla_cocina(estufa))

# ------------------------------------------------------------------ 5. y aun asi se termina
func _terminar_la_manana() -> void:
	print("E. Cepillarse y salir")
	await _cerrar_cocina()
	await _ir_a_zona(4)
	await _junto(Vector2(56, 24), Vector2.UP)
	await _tecla(KEY_Z)
	await create_timer(0.4).timeout
	var espejo : Control = zm.zone_node.get_node("UILayer/MirrorUI")
	await _clic(espejo.hits["brush"])
	await _tecla(KEY_ESCAPE)                 # Esc a mitad de cepillarse
	await _clic(espejo.hits["brush"])
	await create_timer(2.0).timeout
	_check("Esc y clics a mitad de cepillarse: queda cepillada", _tarea("TEETH"))
	await _tecla(KEY_ESCAPE)
	await create_timer(0.3).timeout
	await _calma()
	_check("Cierra el espejo y puede moverse", not espejo.visible and _libre_para_seguir(), "modal %d" % gm.modal_count)
	await _ir_a_zona(0)
	var oido : Array = await _hacer(_pisar.bind(Vector2(120, 8), Vector2(120, -8)))
	for i in 60:
		await create_timer(0.1).timeout
		if zm.zone_node != null and is_instance_valid(zm.zone_node) and zm.zone_node.zone_id == 6:
			break
	_check("Despues de todo, la puerta deja salir ('Aqui vamos.')", zm.zone_node.zone_id == 6, "zona %d, %s" % [zm.zone_node.zone_id, str(oido)])
	print("   (salio a las %s; veces que hubo que vaciar la olla en el fregadero: %d)" % [tm.get_current_time(), agua_vaciada])
	await _calma()
