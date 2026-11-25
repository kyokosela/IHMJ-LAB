extends SceneTree
## "Teclas al azar" por toda la casa y el edificio: camina, pulsa Z, Enter, Espacio, Esc y las flechas, hace clic y arrastra en
## las pantallas abiertas y se planta junto a las cosas. Cada pocas acciones comprueba que un jugador puede SALIR de donde este
## (Esc cierra lo abierto, Z pasa lo que se diga, y Mayui vuelve a moverse) y que nunca atraviesa una pared. Semillas fijas.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_mono.gd
##   ... -s res://Tools/probar_mono.gd -- 300 5 6      (300 acciones con cada una de las semillas 5 y 6)
## Termina con codigo 0 si todo pasa y 1 si algo falla.

const T := 16
## Planos de las zonas de la casa y el edificio (como en probar_cuarto.gd): "." se puede pisar. Las puertas se cruzan solas.
const PLANOS := {
	0: ["#####.....", "#####.....", "#####...##", "#####...##", "##......##", "........##", "........##", "##....####", "##....####"],
	4: ["##.#.", "##...", ".....", "....."],
	5: ["......", "......", "......"],
	6: ["####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####"],
	1: ["####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "####..####", "#.....####", "#.....####", "#.....####", "##########"],
}
## Sitios junto a cada cosa: zona -> [baldosa (centro), hacia donde mira]
const SITIOS := {
	0: [[Vector2(88, 120), Vector2.RIGHT], [Vector2(120, 104), Vector2.RIGHT], [Vector2(120, 56), Vector2.RIGHT],
		[Vector2(40, 72), Vector2.UP], [Vector2(40, 72), Vector2.LEFT]],
	4: [[Vector2(40, 8), Vector2.LEFT], [Vector2(56, 24), Vector2.UP]],
}
## Delante de cada puerta: zona -> [baldosa (centro), tecla que la cruza]
const PUERTAS := {
	0: [[Vector2(88, 24), "move_left"], [Vector2(120, 8), "move_up"], [Vector2(56, 136), "move_down"]],
	4: [[Vector2(72, 40), "move_right"]],
	5: [[Vector2(40, 8), "move_up"]],
	6: [[Vector2(88, 24), "move_right"], [Vector2(72, 56), "move_left"]],
	1: [[Vector2(72, 56), "move_left"], [Vector2(40, 168), "move_down"]],
}
const MOVER := ["move_left", "move_right", "move_up", "move_down"]
const TECLAS := [KEY_Z, KEY_Z, KEY_Z, KEY_ENTER, KEY_SPACE, KEY_ESCAPE, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_W, KEY_S]

var pm
var gm
var tk
var zm
var dlg
var passed := 0
var failed := 0
var azar := RandomNumberGenerator.new()
var bitacora : Array = []
var raton := Vector2.ZERO
var zonas_vistas := {}

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	var argumentos := OS.get_cmdline_user_args()
	var acciones := 220
	var semillas : Array = [1, 2]
	if argumentos.size() >= 2:
		acciones = int(argumentos[0])
		semillas = Array(argumentos.slice(1)).map(func(a: String) -> int: return int(a))
	var limite : float = 60.0 + semillas.size() * acciones * 1.3
	create_timer(limite).timeout.connect(func(): print("  FALLA: la prueba se colgo (%d s) | %s" % [limite, str(bitacora.slice(-8))]); quit(2))
	pm = root.get_node("PlayerManager")
	gm = root.get_node("GameManager")
	tk = root.get_node("TaskManager")
	zm = root.get_node("ZoneManager")
	dlg = root.get_node("Dialogic")
	await create_timer(0.3).timeout
	gm.game_started = false
	var casa : Node = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(casa)
	current_scene = casa
	await create_timer(1.2).timeout
	for semilla in semillas:
		await _una_ronda(semilla, acciones)
	print("   (zonas visitadas: %s)" % str(zonas_vistas.keys()))
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _una_ronda(semilla: int, acciones: int) -> void:
	print("Semilla %d (%d acciones)" % [semilla, acciones])
	azar.seed = semilla
	bitacora.clear()
	var problema := ""
	var comprobadas := 0
	for i in acciones:
		if i == acciones / 2:
			await _terminar_la_rutina()   # para que el azar tambien recorra el pasillo y la recepcion
		bitacora.append(await _accion())
		problema = await _pared()
		if problema != "":
			break
		if i % 12 == 11:
			problema = await _se_puede_salir()
			comprobadas += 1
			if problema != "":
				break
	if problema == "":
		problema = await _se_puede_salir()
	_check("Semilla %d: nunca se queda atascado ni atraviesa paredes (%d veces comprobado)" % [semilla, comprobadas], problema == "", "%s | ultimas: %s" % [problema, str(bitacora.slice(-10))])

# ------------------------------------------------------------------ acciones
func _tecla(codigo: Key) -> void:
	for presionada in [true, false]:
		var tecla := InputEventKey.new()
		tecla.keycode = codigo
		tecla.physical_keycode = codigo
		tecla.pressed = presionada
		Input.parse_input_event(tecla)
		await process_frame

func _zona() -> int:
	if zm.zone_node == null or not is_instance_valid(zm.zone_node):
		return -1
	return int(zm.zone_node.zone_id)

func _pantallas() -> Array:
	var lista : Array = []
	if _zona() == -1:
		return lista
	for ruta in ["UILayer/KitchenMultiUI", "UILayer/WardrobeUI", "UILayer/MirrorUI"]:
		var ui : Node = zm.zone_node.get_node_or_null(ruta)
		if ui != null and ui.visible:
			lista.append(ui)
	return lista

## Todo lo que se puede tocar con el raton en una pantalla: botones, casillas y zonas de clic.
func _tocables(nodo: Node, lista: Array) -> void:
	for hijo in nodo.get_children():
		if hijo.is_queued_for_deletion():
			continue
		if hijo is Control and hijo.is_visible_in_tree() and (hijo is BaseButton or hijo.get("slot_index") != null or hijo.name.ends_with("Hit") or hijo.name == "Exit"):
			lista.append(hijo)
		_tocables(hijo, lista)

func _raton_a(posicion: Vector2, con_boton: bool = false) -> void:
	var mov := InputEventMouseMotion.new()
	mov.position = posicion
	mov.global_position = posicion
	mov.relative = posicion - raton
	raton = posicion
	mov.button_mask = MOUSE_BUTTON_MASK_LEFT if con_boton else 0
	root.push_input(mov, true)
	await process_frame

func _boton(posicion: Vector2, boton: MouseButton, presionado: bool) -> void:
	var clic := InputEventMouseButton.new()
	clic.button_index = boton
	clic.pressed = presionado
	clic.position = posicion
	clic.global_position = posicion
	root.push_input(clic, true)
	await process_frame

func _accion() -> String:
	zonas_vistas[_zona()] = true
	if _zona() == 2:   # la oficina no es parte de esta prueba: se vuelve a casa
		await _se_puede_salir()
		zm.change_zone(0)
		await create_timer(2.6).timeout
		return "vuelve de la oficina"
	var pantallas := _pantallas()
	var dado := azar.randf()
	if not pantallas.is_empty() and dado < 0.65:
		var tocables : Array = []
		_tocables(pantallas[0], tocables)
		if not tocables.is_empty():
			# los nombres y las posiciones se toman antes de pulsar: la pantalla puede rehacer sus casillas al hacerlo
			var a : Control = tocables[azar.randi() % tocables.size()]
			var origen : Vector2 = a.get_global_rect().get_center()
			var nombre_a := str(a.name)
			if dado < 0.2:
				var b : Control = tocables[azar.randi() % tocables.size()]
				var destino : Vector2 = b.get_global_rect().get_center()
				var nombre_b := str(b.name)
				await _raton_a(origen)
				await _boton(origen, MOUSE_BUTTON_LEFT, true)
				for i in range(1, 5):
					await _raton_a(origen.lerp(destino, i / 4.0), true)
				await _boton(destino, MOUSE_BUTTON_LEFT, false)
				return "arrastra %s -> %s" % [nombre_a, nombre_b]
			var cual : MouseButton = MOUSE_BUTTON_RIGHT if dado < 0.3 else MOUSE_BUTTON_LEFT
			await _raton_a(origen)
			await _boton(origen, cual, true)
			await _boton(origen, cual, false)
			await create_timer(0.1).timeout
			return "clic %s" % nombre_a
	dado = azar.randf()
	if dado < 0.10 and PUERTAS.has(_zona()) and gm.modal_count == 0 and dlg.current_timeline == null and not zm._changing_zone:
		var puerta : Array = PUERTAS[_zona()][azar.randi() % PUERTAS[_zona()].size()]
		var desde := _zona()
		pm.player.movement.tile_destination = puerta[0]
		pm.player.global_position = puerta[0]
		for i in 6:
			await physics_frame
		Input.action_press(puerta[1])
		for i in 14:
			await physics_frame
		Input.action_release(puerta[1])
		await create_timer(2.4).timeout
		return "puerta %s de la zona %d -> %d" % [puerta[1], desde, _zona()]
	dado = azar.randf()
	if dado < 0.35:
		var accion : String = MOVER[azar.randi() % MOVER.size()]
		Input.action_press(accion)
		for i in 4 + azar.randi() % 40:
			await physics_frame
		Input.action_release(accion)
		for i in 20:
			await physics_frame
		return accion
	if dado < 0.80:
		var codigo : Key = TECLAS[azar.randi() % TECLAS.size()]
		await _tecla(codigo)
		await create_timer(0.2).timeout
		return OS.get_keycode_string(codigo)
	if SITIOS.has(_zona()) and gm.modal_count == 0 and dlg.current_timeline == null and not zm._changing_zone:
		var sitio : Array = SITIOS[_zona()][azar.randi() % SITIOS[_zona()].size()]
		pm.player.movement.tile_destination = sitio[0]
		pm.player.global_position = sitio[0]
		pm.player.set_facing_direction(sitio[1])
		for i in 8:
			await physics_frame
		await _tecla(KEY_Z)
		await create_timer(0.3).timeout
		return "usa %s" % str(sitio[0])
	await create_timer(0.3).timeout
	return "espera"

func _terminar_la_rutina() -> void:
	for id in ["BATHE", "CLOTHES", "COOK", "TEETH"]:
		tk.done_task("TUTORIAL_DOOR", id)
	await _se_puede_salir()
	var uniforme : Array = pm.wardrobe.filter(func(i) -> bool: return pm.outfit_id_of(i) == "work")
	if not uniforme.is_empty():
		pm.wear_clothes(uniforme[0])
	bitacora.append("rutina completa")

# ------------------------------------------------------------------ comprobaciones
## Con la zona quieta, Mayui debe estar en una baldosa que se pisa (o en una puerta, cruzandola).
func _pared() -> String:
	var zona := _zona()
	if not PLANOS.has(zona) or zm._changing_zone or pm.player.movement.is_moving:
		return ""
	var c := Vector2i((pm.player.global_position / T).floor())
	var mapa : Array = PLANOS[zona]
	var puertas := {0: [Vector2i(7, -1), Vector2i(4, 1), Vector2i(3, 9), Vector2i(4, 9)], 4: [Vector2i(5, 2)],
		5: [Vector2i(2, -1), Vector2i(3, -1)], 6: [Vector2i(6, 1), Vector2i(3, 3), Vector2i(3, 4)], 1: [Vector2i(3, 3), Vector2i(3, 4), Vector2i(2, 11)]}
	if c in puertas[zona]:
		return ""
	if c.y >= 0 and c.y < mapa.size() and c.x >= 0 and c.x < mapa[0].length() and mapa[c.y][c.x] == ".":
		return ""
	return "Mayui esta dentro de una pared en la zona %d, baldosa %s" % [zona, str(c)]

## Como una persona que quiere seguir: Esc cierra lo abierto y Z pasa lo que se diga. "" si despues puede moverse.
func _se_puede_salir() -> String:
	for intento in 3:
		for i in 40:
			if dlg.current_timeline == null:
				break
			await _tecla(KEY_Z)
			await create_timer(0.4).timeout
		var abiertas : bool = not _pantallas().is_empty() or gm.modal_count > 0
		if abiertas:
			await _tecla(KEY_ESCAPE)
			await create_timer(1.2).timeout
		for i in 40:
			if not zm._changing_zone:
				break
			await create_timer(0.1).timeout
		await create_timer(0.3).timeout
		if gm.modal_count == 0 and dlg.current_timeline == null and not zm._changing_zone and _pantallas().is_empty() and pm.player.movement.can_move:
			return ""
	return "atascado: zona %d, pantallas %s, contador %d, dialogo %s, viajando %s, puede moverse %s" % [_zona(),
			str(_pantallas().map(func(n: Node) -> String: return n.name)), gm.modal_count, str(dlg.current_timeline != null), str(zm._changing_zone), str(pm.player.movement.can_move)]
