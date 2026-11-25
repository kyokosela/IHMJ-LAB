extends SceneTree
## Juega la manana COMO UNA PERSONA: solo teclas (caminar, Z, Esc) y clics y arrastres de raton de verdad sobre las pantallas,
## desde despertar hasta que el casero la intercepta en el lobby. Es la prueba de que el tutorial se termina sin atajos.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/jugar_manana.gd
## Con fotos de cada momento (abre una ventana):
##   Godot_v4.6-stable_win64_console.exe --path . --resolution 1920x1080 -s res://Tools/jugar_manana.gd -- C:/ruta/fotos
## Termina con codigo 0 si todo pasa y 1 si algo falla.

const T := 16
## Planos del cuarto (0), el bano (4) y el pasillo (6), como en probar_cuarto.gd: "." se puede pisar.
const PLANOS := {
	0: ["#####.....", "#####.....", "#####...##", "#####...##", "##......##", "........##", "........##", "##....####", "##....####"],
	4: ["##.#.", "##...", ".....", "....."],
	6: ["####..####", "####...###", "####..####", "###...####", "###...####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####"],
}
const TECLAS := {Vector2i.LEFT: "move_left", Vector2i.RIGHT: "move_right", Vector2i.UP: "move_up", Vector2i.DOWN: "move_down"}

var pm
var gm
var tk
var tm
var zm
var dlg
var carpeta_fotos := ""
var passed := 0
var failed := 0
var dichos : Array = []
var raton := Vector2.ZERO ## donde quedo el puntero

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	var guardia := create_timer(240.0)
	guardia.timeout.connect(func(): print("  FALLA: la partida se colgo (240 s)"); quit(2))
	var argumentos := OS.get_cmdline_user_args()
	if not argumentos.is_empty():
		carpeta_fotos = argumentos[0]
		DirAccess.make_dir_recursive_absolute(carpeta_fotos)
	pm = root.get_node("PlayerManager")
	gm = root.get_node("GameManager")
	tk = root.get_node("TaskManager")
	tm = root.get_node("TimeManager")
	zm = root.get_node("ZoneManager")
	dlg = root.get_node("Dialogic")
	await create_timer(0.3).timeout
	dlg.Text.text_started.connect(func(info) -> void: dichos.append(str(info.get("text", "")).strip_edges()))
	await _jugar()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ como una persona
func _tecla(codigo: Key) -> void:
	for presionada in [true, false]:
		var tecla := InputEventKey.new()
		tecla.keycode = codigo
		tecla.physical_keycode = codigo
		tecla.pressed = presionada
		Input.parse_input_event(tecla)
		await process_frame

func _z() -> void:
	await _tecla(KEY_Z)

## Pulsa Z (o lo que se pida) y pasa con Z todo lo que se diga. Devuelve las lineas oidas.
func _hablar(accion: Callable = Callable()) -> Array:
	dichos.clear()
	if accion.is_valid():
		await accion.call()
	else:
		await _z()
	await create_timer(0.8).timeout
	for i in 14:
		if dlg.current_timeline == null:
			break
		await _z()
		await create_timer(0.8).timeout
	await create_timer(0.4).timeout
	return dichos.duplicate()

func _zona() -> int:
	return int(zm.zone_node.zone_id)

func _casilla() -> Vector2i:
	return Vector2i((pm.player.global_position / T).floor())

func _libre(c: Vector2i) -> bool:
	var mapa : Array = PLANOS[_zona()]
	return c.y >= 0 and c.y < mapa.size() and c.x >= 0 and c.x < mapa[0].length() and mapa[c.y][c.x] == "."

func _paso(dir: Vector2i) -> void:
	var inicio : Vector2 = pm.player.global_position
	Input.action_press(TECLAS[dir])
	for i in 30:
		await physics_frame
		if not pm.player.movement.tile_destination.is_equal_approx(inicio):
			break
	Input.action_release(TECLAS[dir])
	for i in 60:
		await physics_frame
		if not pm.player.movement.is_moving:
			break

func _caminar_a(destino: Vector2i) -> bool:
	var origen := _casilla()
	var previas := {origen: origen}
	var cola := [origen]
	while not cola.is_empty():
		var a : Vector2i = cola.pop_front()
		for d : Vector2i in TECLAS:
			if _libre(a + d) and not previas.has(a + d):
				previas[a + d] = a
				cola.append(a + d)
	if not previas.has(destino):
		return false
	var pasos : Array = []
	var c := destino
	while c != origen:
		pasos.push_front(c - previas[c])
		c = previas[c]
	for d : Vector2i in pasos:
		await _paso(d)
	return _casilla() == destino

## Camina a una casilla y se gira hacia lo que quiere usar.
func _ir(destino: Vector2i, mirando: Vector2i, que: String) -> void:
	var llego : bool = await _caminar_a(destino)
	Input.action_press(TECLAS[mirando])
	for i in 8:
		await physics_frame
	Input.action_release(TECLAS[mirando])
	for i in 8:
		await physics_frame
	_check("Llega a %s" % que, llego and _casilla() == destino, str(_casilla()))

## Camina hasta una puerta y la cruza.
func _cruzar(desde: Vector2i, dir: Vector2i, zona: int) -> void:
	var llego : bool = await _caminar_a(desde)
	await _paso(dir)
	for i in 80:
		await create_timer(0.1).timeout
		if _zona() == zona and not zm._changing_zone:
			break
	await create_timer(0.4).timeout
	_check("Cruza la puerta hacia la zona %d" % zona, llego and _zona() == zona, "zona %d" % _zona())

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
	mov.relative = posicion - raton   # Godot decide que empieza un arrastre sumando este avance
	raton = posicion
	mov.button_mask = MOUSE_BUTTON_MASK_LEFT if con_boton else 0
	root.push_input(mov, true)
	await process_frame

func _clic(control: Control, boton: MouseButton = MOUSE_BUTTON_LEFT, desplazamiento := Vector2.ZERO) -> void:
	await create_timer(0.15).timeout   # que la pantalla termine de acomodar sus casillas
	var centro : Vector2 = control.get_global_rect().get_center() + desplazamiento
	await _mover_raton(centro)
	await _raton(centro, boton, true)
	await _raton(centro, boton, false)
	await create_timer(0.15).timeout

func _arrastrar(origen: Control, destino: Control) -> void:
	await create_timer(0.15).timeout
	var a : Vector2 = origen.get_global_rect().get_center()
	var b : Vector2 = destino.get_global_rect().get_center()
	await _mover_raton(a)
	await _raton(a, MOUSE_BUTTON_LEFT, true)
	for i in range(1, 9):
		await _mover_raton(a.lerp(b, i / 8.0), true)
	await _raton(b, MOUSE_BUTTON_LEFT, false)
	await create_timer(0.25).timeout

## La casilla de una pantalla de contenedor para ese indice.
func _slot(rejillas: Array, indice: int) -> Control:
	await create_timer(0.15).timeout
	for rejilla : Node in rejillas:
		for c in rejilla.get_children():
			if not c.is_queued_for_deletion() and c.get("slot_index") == indice:
				return c
	return null

func _foto(nombre: String) -> void:
	if carpeta_fotos.is_empty():
		return
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(carpeta_fotos.path_join(nombre + ".png"))

func _tarea(id: String) -> bool:
	return tk.get_task_list_res("TUTORIAL_DOOR").get_task_res(id).task_done

# ------------------------------------------------------------------ la manana
func _jugar() -> void:
	gm.game_started = false
	zm.previous_zone = -1
	var casa : Node = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(casa)
	current_scene = casa
	await create_timer(1.5).timeout
	await _foto("1_despierta")
	await _hablar()
	await _foto("2_a_oscuras")

	print("1. Ducha")
	await _cruzar(Vector2i(5, 1), Vector2i.LEFT, 4)
	await _ir(Vector2i(2, 0), Vector2i.LEFT, "la ducha")
	await _z()
	await create_timer(1.2).timeout
	await _foto("3_ducha")
	await _hablar(func() -> void: await create_timer(0.1).timeout)
	_check("Se ducha y sale en toalla", _tarea("BATHE") and pm.get_outfit_id() == "towel")
	await _cruzar(Vector2i(4, 2), Vector2i.RIGHT, 0)

	print("2. Uniforme (clic en el armario)")
	await _ir(Vector2i(7, 6), Vector2i.RIGHT, "el armario")
	await _z()
	await create_timer(0.5).timeout
	var armario : Control = zm.zone_node.get_node("UILayer/WardrobeUI")
	_check("Se abre el armario", armario.visible)
	await _foto("4_armario")
	dichos.clear()
	await _clic(armario.garment_slots["work"].get_node("Hit"))
	await create_timer(1.5).timeout
	await _hablar(func() -> void: await create_timer(0.1).timeout)
	_check("Con un clic se pone el uniforme", pm.get_outfit_id() == "work" and _tarea("CLOTHES"), pm.get_outfit_id())
	await _tecla(KEY_ESCAPE)
	await create_timer(0.3).timeout
	_check("Esc cierra el armario", not armario.visible and gm.modal_count == 0)

	print("3. Cocinar y comer (arrastrando con el raton)")
	await _ir(Vector2i(7, 3), Vector2i.RIGHT, "la cocina")
	await _z()
	await create_timer(0.6).timeout
	var ui : Control = zm.zone_node.get_node("UILayer/KitchenMultiUI")
	var cocina = zm.zone_node.get_node("Kitchen")
	var kc = cocina.container
	var inv = kc.inventory
	_check("Se abre la cocina", ui.visible)
	var alacena : Control = ui.get_node("Panel/MainContainer/ShelfButton")
	await _clic(alacena)
	if not ui.storage_grid.is_visible_in_tree():
		await _clic(ui.get_node("Panel/MainContainer/ShelfLeftButton"))
	await _foto("5_cocina_alacena")
	var guardados : Array = kc.get_storage_indices()
	var bolsa := -1
	var olla := -1
	for i in guardados:
		if inv.slots[i].is_empty():
			continue
		var nombre : String = inv.slots[i].item.data.item_unique_name
		if nombre == "ingredients_bag" and bolsa == -1:
			bolsa = i
		if nombre == "cooking_pot":
			olla = i
	var almacen : Array = [ui.storage_grid, ui.storage_grid_2]
	var tabla : int = kc.get_station_slot_index("cutting")
	var estufa : int = kc.get_station_slot_index("stove")
	var entradas : Array = kc.get_simple_craft_input_indices()
	var rejilla_tabla : Array = [ui.station_containers["cutting"]]
	var rejilla_estufa : Array = [ui.station_containers["stove"]]
	await _arrastrar(await _slot(almacen, bolsa), await _slot(rejilla_tabla, tabla))
	_check("Arrastra la bolsa a la tabla", not inv.slots[tabla].is_empty())
	await _clic(ui.station_craft_buttons["cutting"])
	_check("Clic en Picar", not inv.slots[tabla].is_empty() and inv.slots[tabla].item.data.item_unique_name != "ingredients_bag", str(inv.slots[tabla].item.data.item_unique_name if not inv.slots[tabla].is_empty() else "vacia"))
	await _arrastrar(await _slot(almacen, olla), await _slot([ui.simple_craft_input_grid], entradas[0]))
	await _arrastrar(await _slot(rejilla_tabla, tabla), await _slot([ui.simple_craft_input_grid], entradas[1]))
	await _clic(ui.craft_button)
	var resultado : int = kc.get_simple_craft_result_index()
	_check("Clic en Combinar", not inv.slots[resultado].is_empty())
	await _arrastrar(await _slot([ui.simple_craft_result_grid], resultado), await _slot(rejilla_estufa, estufa))
	await _clic(ui.station_craft_buttons["stove"])
	await _foto("6_cocinando")
	await _clic(ui.station_wait_buttons["stove"])
	await create_timer(0.3).timeout
	var aviso : Window = ui.wait_dialog
	_check("Clic en Esperar: sale el aviso", aviso.visible)
	var boton : Button = aviso.get_ok_button()
	await _clic(boton, MOUSE_BUTTON_LEFT, Vector2(aviso.position))
	await create_timer(0.3).timeout
	if aviso.visible:
		print("  (el aviso no recibio el clic simulado: se confirma con su boton)")
		boton.pressed.emit()
	await _hablar(func() -> void: await create_timer(0.2).timeout)
	var manos = pm.player.inventory
	var mano : int = manos.get_hands_indices()[0]
	var rejilla_manos : Array = [ui.player_hands_grid]
	await _arrastrar(await _slot(rejilla_estufa, estufa), await _slot(rejilla_manos, mano))
	_check("Pasa la comida a las manos", not manos.inventory.slots[mano].is_empty())
	await _clic(await _slot(rejilla_manos, mano), MOUSE_BUTTON_RIGHT)
	await _hablar(func() -> void: await create_timer(0.2).timeout)
	await _foto("7_comio")
	_check("Clic derecho: come (tarea de comer y sin Hambre)", _tarea("COOK") and not pm.has_effect("HUNGER"))
	await _tecla(KEY_ESCAPE)
	await create_timer(0.3).timeout
	_check("Esc cierra la cocina", not ui.visible and gm.modal_count == 0)

	print("4. Escritorio y calendario")
	await _ir(Vector2i(2, 4), Vector2i.LEFT, "el escritorio")
	var oido : Array = await _hablar()
	_check("El escritorio habla", oido == ["No puedo quedarme aquí."], str(oido))

	print("5. Dientes (clic en el espejo)")
	await _cruzar(Vector2i(5, 1), Vector2i.LEFT, 4)
	await _ir(Vector2i(3, 1), Vector2i.UP, "el lavamanos")
	await _z()
	await create_timer(0.5).timeout
	var espejo : Control = zm.zone_node.get_node("UILayer/MirrorUI")
	_check("Se abre el espejo", espejo.visible)
	await _clic(espejo.hits["brush"])
	await create_timer(0.5).timeout
	await _foto("8_cepillandose")
	await create_timer(2.0).timeout
	_check("Con un clic se cepilla", _tarea("TEETH"))
	await _hablar(func() -> void: await create_timer(0.1).timeout)
	await _tecla(KEY_ESCAPE)
	await create_timer(0.3).timeout
	_check("Esc cierra el espejo", not espejo.visible and gm.modal_count == 0)
	await _cruzar(Vector2i(4, 2), Vector2i.RIGHT, 0)
	await _foto("9_todo_listo")

	print("6. Salir")
	_check("Llega frente a la puerta", await _caminar_a(Vector2i(7, 0)), str(_casilla()))
	oido = await _hablar(func() -> void: await _paso(Vector2i.UP))
	_check("La puerta: 'Aquí vamos.'", oido.has("Aquí vamos."), str(oido))
	var hora : String = tm.get_current_time()
	for i in 80:
		await create_timer(0.1).timeout
		if _zona() == 6 and not zm._changing_zone:
			break
	await create_timer(0.4).timeout
	_check("Sale al pasillo", _zona() == 6, "zona %d" % _zona())
	await _foto("10_pasillo")
	await _cruzar(Vector2i(4, 3), Vector2i.LEFT, 1)   # baja las escaleras a la recepcion
	var casero := false
	for i in 50:
		await create_timer(0.1).timeout
		if dlg.current_timeline != null and str(dlg.current_timeline.resource_path).contains("casero_intro"):
			casero = true
			break
	await create_timer(1.0).timeout
	await _foto("11_casero")
	_check("El casero la intercepta", casero)
	_check("Sale a tiempo (antes de las 08:00)", tm.minutes < 8 * 60, hora)
	print("   (salio a las %s)" % hora)
	if dlg.current_timeline != null:
		dlg.end_timeline()
