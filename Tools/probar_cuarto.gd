extends SceneTree
## Prueba del cuarto de Mayui (Apartment.tscn): paredes y muebles estorban donde deben, a todo el piso libre se puede llegar, y
## caminando con las teclas de verdad se llega a cada mueble, no se atraviesa, y Z hace lo suyo.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_cuarto.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla. Si se mueve un mueble en la escena, cambiar MAPA aqui.

const T := 16
## Una letra por baldosa (10 columnas x 9 filas): "." se puede pisar, "#" hay pared o mueble.
const MAPA := [
	"######....",
	"######....",
	"#####...##",
	"######..##",
	"##......##",
	"........##",
	"........##",
	"##....####",
	"##....####",
]
## El hueco de la puerta principal (en la pared de arriba): solo se pisa caminando hacia ella a proposito.
const UMBRAL := Vector2i(7, -1)
const TECLAS := {Vector2i.LEFT: "move_left", Vector2i.RIGHT: "move_right", Vector2i.UP: "move_up", Vector2i.DOWN: "move_down"}
const MUEBLES := ["Bed", "Wardrobe", "Kitchen", "Shower", "Sink"]

var pm
var gm
var tk
var dlg
var casa : Node
var passed := 0
var failed := 0
var dichos : Array = []

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	var guardia := create_timer(120.0)
	guardia.timeout.connect(func(): print("  FALLA: la prueba se colgo (120 s)"); quit(2))
	pm = root.get_node("PlayerManager")
	gm = root.get_node("GameManager")
	tk = root.get_node("TaskManager")
	dlg = root.get_node("Dialogic")
	await create_timer(0.3).timeout
	dlg.Text.text_started.connect(func(info) -> void: dichos.append(str(info.get("text", "")).strip_edges()))
	gm.game_started = false
	casa = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(casa)
	current_scene = casa
	await create_timer(1.5).timeout
	await _hablar(_pulsar_z)   # "Tengo que ducharme."
	await _t_mapa()
	await _t_caminando()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
func _centro(casilla: Vector2i) -> Vector2:
	return Vector2(casilla * T) + Vector2(T, T) / 2.0

func _casilla(posicion: Vector2) -> Vector2i:
	return Vector2i((posicion / T).floor())

func _libre(c: Vector2i) -> bool:
	return c.y >= 0 and c.y < MAPA.size() and c.x >= 0 and c.x < MAPA[0].length() and MAPA[c.y][c.x] == "."

## Casillas a las que se llega desde `desde`, cada una con la casilla anterior del camino mas corto.
func _alcanzables(desde: Vector2i) -> Dictionary:
	var previas := {desde: desde}
	var cola := [desde]
	while not cola.is_empty():
		var a : Vector2i = cola.pop_front()
		for d : Vector2i in TECLAS:
			if _libre(a + d) and not previas.has(a + d):
				previas[a + d] = a
				cola.append(a + d)
	return previas

func _pulsar_z() -> void:
	for presionada in [true, false]:
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_Z
		tecla.physical_keycode = KEY_Z
		tecla.pressed = presionada
		Input.parse_input_event(tecla)
		await process_frame

## Hace algo, pasa con Z todo lo que se diga y devuelve las lineas oidas.
func _hablar(accion: Callable) -> Array:
	dichos.clear()
	await accion.call()
	await create_timer(0.8).timeout
	for i in 14:
		if dlg.current_timeline == null:
			break
		await _pulsar_z()
		await create_timer(0.8).timeout
	await create_timer(0.4).timeout
	return dichos.duplicate()

## Un paso (una baldosa) con la tecla de verdad.
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
	var origen := _casilla(pm.player.global_position)
	var previas := _alcanzables(origen)
	if not previas.has(destino):
		return false
	var pasos : Array = []
	var c := destino
	while c != origen:
		pasos.push_front(c - previas[c])
		c = previas[c]
	for d : Vector2i in pasos:
		await _paso(d)
	return pm.player.global_position.is_equal_approx(_centro(destino))

## Mantiene una tecla contra algo: debe girarse hacia ahi sin moverse.
func _empujar(dir: Vector2i) -> void:
	Input.action_press(TECLAS[dir])
	for i in 10:
		await physics_frame
	Input.action_release(TECLAS[dir])
	for i in 8:
		await physics_frame

## Los muebles que ofrecen interaccion en este momento (Mayui los tiene delante).
func _delante() -> Array:
	return MUEBLES.filter(func(n: String) -> bool: return casa.get_node(n).is_inside)

## Camina hasta `desde`, empuja hacia el mueble y comprueba que no lo atraviesa y que solo ese queda delante.
func _ir_a(mueble: String, desde: Vector2i, dir: Vector2i) -> void:
	var llego : bool = await _caminar_a(desde)
	_check("%s: se llega caminando a su lado" % mueble, llego, str(pm.player.global_position))
	await _empujar(dir)
	_check("%s: es solido (no se atraviesa)" % mueble, pm.player.global_position.is_equal_approx(_centro(desde)), str(pm.player.global_position))
	_check("%s: queda delante, y solo ese" % mueble, _delante() == [mueble], str(_delante()))

# ------------------------------------------------------------------ A. paredes y muebles
func _t_mapa() -> void:
	print("A. Paredes, muebles y piso libre")
	_check("Mayui despierta de pie junto a la cama", pm.player.global_position.is_equal_approx(Vector2(88, 120)), str(pm.player.global_position))
	_check("...sin ningun mueble delante (la Z del primer dialogo no activa nada)", _delante().is_empty(), str(_delante()))
	await physics_frame
	await physics_frame
	var espacio : PhysicsDirectSpaceState2D = casa.get_world_2d().direct_space_state
	var mal : Array = []
	for fila in range(-3, 10):
		for columna in range(-1, 11):
			var consulta := PhysicsPointQueryParameters2D.new()
			consulta.position = _centro(Vector2i(columna, fila))
			consulta.exclude = [pm.player.get_rid()]
			var estorba : bool = espacio.intersect_point(consulta).any(func(golpe: Dictionary) -> bool: return golpe.collider is StaticBody2D)
			if estorba == (_libre(Vector2i(columna, fila)) or Vector2i(columna, fila) == UMBRAL):
				mal.append(Vector2i(columna, fila))
	_check("Cada baldosa estorba o se puede pisar segun el plano (incluye las paredes)", mal.is_empty(), str(mal))
	var libres := 0
	for fila in MAPA:
		libres += fila.count(".")
	var llega := _alcanzables(Vector2i(5, 7)).size()
	_check("A todo el piso libre se llega desde la cama", llega == libres, "%d de %d" % [llega, libres])

# ------------------------------------------------------------------ B. caminando
func _t_caminando() -> void:
	print("B. Caminando hasta cada cosa")
	await _empujar(Vector2i.RIGHT)
	_check("Cama: desde donde despierta basta girarse a la derecha", _delante() == ["Bed"] and pm.player.global_position.is_equal_approx(Vector2(88, 120)), str(_delante()))
	var oido : Array = await _hablar(_pulsar_z)
	_check("Cama: Z dice la frase del tutorial", oido == ["Si vuelvo ahí, no salgo."], str(oido))

	await _ir_a("Wardrobe", Vector2i(7, 6), Vector2i.RIGHT)
	oido = await _hablar(_pulsar_z)
	_check("Armario antes de ducharse: Z dice su frase", oido == ["Primero debería ducharme."], str(oido))

	await _ir_a("Sink", Vector2i(5, 2), Vector2i.DOWN)
	oido = await _hablar(_pulsar_z)
	_check("Lavamanos antes de comer: Z avisa", oido.size() == 1 and (oido[0].contains("comer") or oido[0] == "Luego."), str(oido))

	dichos.clear()
	var recorrido : bool = await _caminar_a(Vector2i(6, 0)) and await _caminar_a(Vector2i(9, 0)) and await _caminar_a(Vector2i(7, 0))
	await create_timer(0.5).timeout
	_check("Puerta: pasar por delante no la activa", recorrido and dichos.is_empty() and dlg.current_timeline == null, str(dichos))
	oido = await _hablar(func() -> void: await _paso(Vector2i.UP))
	_check("Puerta: al caminar hacia ella sin la rutina habla y no deja salir", oido == ["..."] and current_scene == casa, str(oido))
	await _paso(Vector2i.DOWN)
	_check("Puerta: se puede volver a bajar", pm.player.global_position.is_equal_approx(_centro(Vector2i(7, 0))), str(pm.player.global_position))

	await _ir_a("Shower", Vector2i(6, 0), Vector2i.LEFT)
	oido = await _hablar(_pulsar_z)
	_check("Ducha: Z banya a Mayui", pm.get_outfit_id() == "towel" and tk.get_task_list_res("TUTORIAL_DOOR").get_task_res("BATHE").task_done and oido.size() == 5, str(oido))

	await _ir_a("Kitchen", Vector2i(7, 3), Vector2i.RIGHT)
	var cocina = casa.get_node("UILayer/KitchenMultiUI")
	await _pulsar_z()
	await create_timer(0.5).timeout
	_check("Cocina: Z abre la pantalla y Mayui queda quieta", cocina.visible and gm.modal_count == 1)
	cocina.close()
	await create_timer(0.3).timeout
	await _ir_a("Kitchen", Vector2i(8, 1), Vector2i.DOWN)

	await _ir_a("Wardrobe", Vector2i(7, 6), Vector2i.RIGHT)
	var armario = casa.get_node("UILayer/WardrobeUI")
	await _pulsar_z()
	await create_timer(0.5).timeout
	_check("Armario despues de ducharse: Z lo abre", armario.visible and gm.modal_count == 1)
	armario.close()
	await create_timer(0.3).timeout

	# esquinas: las paredes frenan y la camara no se mueve
	for esquina in [[Vector2i(9, 0), Vector2i.RIGHT, Vector2i.UP], [Vector2i(2, 8), Vector2i.LEFT, Vector2i.DOWN], [Vector2i(0, 5), Vector2i.LEFT, Vector2i.UP]]:
		var llego : bool = await _caminar_a(esquina[0])
		await _empujar(esquina[1])
		await _empujar(esquina[2])
		_check("Esquina %s: las paredes y muebles la frenan" % str(esquina[0]), llego and pm.player.global_position.is_equal_approx(_centro(esquina[0])), str(pm.player.global_position))
		var centro : Vector2 = root.get_viewport().get_camera_2d().get_screen_center_position()
		_check("Esquina %s: el cuarto entero sigue en pantalla (camara fija)" % str(esquina[0]), centro.distance_to(Vector2(80, 56)) < 0.5, str(centro))
