extends SceneTree
## Prueba de la casa de Mayui (Apartment.tscn y Bathroom.tscn): paredes y muebles estorban donde deben, a todo el piso libre se
## puede llegar, y caminando con las teclas de verdad se llega a cada cosa, no se atraviesa, Z hace lo suyo y las puertas llevan
## a donde deben.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_cuarto.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla. Si se mueve un mueble en una escena, cambiar su plano aqui.

const T := 16
## Un plano por zona (ZoneManager.ZONES), una letra por baldosa: "." se puede pisar, "#" hay pared o mueble.
## "puertas": huecos en la pared que llevan a otro lado (solo se pisan a proposito). "rango": baldosas que se revisan.
const PLANOS := {
	0: {
		"mapa": [
			"#####.....",
			"#####.....",
			"#####...##",
			"#####...##",
			"##......##",
			"........##",
			"........##",
			"##....####",
			"##....####",
		],
		"puertas": [Vector2i(7, -1), Vector2i(4, 0), Vector2i(3, 9), Vector2i(4, 9)],
		"rango": Rect2i(-1, -3, 12, 13),
	},
	5: {
		"mapa": [
			"......",
			"......",
			"......",
		],
		"puertas": [Vector2i(2, -1), Vector2i(3, -1)],
		"rango": Rect2i(-1, -2, 8, 6),
	},
	4: {
		"mapa": [
			"##.#.",
			"##...",
			".....",
			".....",
		],
		"puertas": [Vector2i(5, 2)],
		"rango": Rect2i(-1, -3, 7, 8),
	},
	6: {   # pasillo del piso 2: huecos de las 4 puertas (filas 1 y 10); la puerta M-21 (7,1) y las escaleras (3,3 y 3,4)
		"mapa": [
			"####..####", "###....###", "####..####", "####..####", "####..####", "####..####",
			"####..####", "####..####", "####..####", "####..####", "###....###", "####..####",
		],
		"puertas": [Vector2i(7, 1), Vector2i(3, 3), Vector2i(3, 4)],
		"rango": Rect2i(-1, -1, 12, 14),
	},
	1: {   # recepcion (piso 1): huecos de las puertas, escaleras (3,3 y 3,4), mantenimiento (7,9) y puerta a la calle (2,12)
		"mapa": [
			"####..####", "###....###", "####..####", "####..####", "####..####", "####..####",
			"####..####", "####..####", "#.....####", "#......###", "#.....####", "##.#######",
		],
		"puertas": [Vector2i(3, 3), Vector2i(3, 4), Vector2i(7, 9), Vector2i(2, 12)],
		"rango": Rect2i(-1, -1, 12, 15),
	},
}
const TECLAS := {Vector2i.LEFT: "move_left", Vector2i.RIGHT: "move_right", Vector2i.UP: "move_up", Vector2i.DOWN: "move_down"}
const MUEBLES := ["Bed", "Wardrobe", "Kitchen", "Shower", "Sink", "Calendario", "Escritorio"]

var pm
var gm
var tk
var tm
var zm
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
	var guardia := create_timer(240.0)
	guardia.timeout.connect(func(): print("  FALLA: la prueba se colgo (240 s)"); quit(2))
	pm = root.get_node("PlayerManager")
	gm = root.get_node("GameManager")
	tk = root.get_node("TaskManager")
	tm = root.get_node("TimeManager")
	zm = root.get_node("ZoneManager")
	dlg = root.get_node("Dialogic")
	await create_timer(0.3).timeout
	dlg.Text.text_started.connect(func(info) -> void: dichos.append(str(info.get("text", "")).strip_edges()))
	gm.game_started = false
	casa = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(casa)
	current_scene = casa
	await create_timer(1.5).timeout
	await _hablar(_pulsar_z)   # "Tengo que ducharme."
	_check("Mayui despierta de pie junto a la cama", pm.player.global_position.is_equal_approx(Vector2(88, 120)), str(pm.player.global_position))
	_check("...sin ningun mueble delante (la Z del primer dialogo no activa nada)", _delante().is_empty(), str(_delante()))
	await _t_plano("A. Cuarto: paredes, muebles y piso libre")
	await _t_cuarto()
	await _t_bano()
	await _t_despues_del_bano()
	await _t_balcon()
	await _t_edificio()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
func _plano() -> Dictionary:
	return PLANOS[int(casa.zone_id)]

func _centro(casilla: Vector2i) -> Vector2:
	return Vector2(casilla * T) + Vector2(T, T) / 2.0

func _casilla(posicion: Vector2) -> Vector2i:
	return Vector2i((posicion / T).floor())

func _libre(c: Vector2i) -> bool:
	var mapa : Array = _plano().mapa
	return c.y >= 0 and c.y < mapa.size() and c.x >= 0 and c.x < mapa[0].length() and mapa[c.y][c.x] == "."

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
	return MUEBLES.filter(func(n: String) -> bool: return casa.has_node(n) and casa.get_node(n).is_inside)

## Camina hasta `desde`, empuja hacia el mueble y comprueba que no lo atraviesa y que solo ese queda delante.
func _ir_a(mueble: String, desde: Vector2i, dir: Vector2i) -> void:
	var llego : bool = await _caminar_a(desde)
	_check("%s: se llega caminando a su lado" % mueble, llego, str(pm.player.global_position))
	await _empujar(dir)
	_check("%s: es solido (no se atraviesa)" % mueble, pm.player.global_position.is_equal_approx(_centro(desde)), str(pm.player.global_position))
	_check("%s: queda delante, y solo ese" % mueble, _delante() == [mueble], str(_delante()))

## Da un paso hacia una puerta y espera a llegar a la otra zona.
func _cruzar(dir: Vector2i, zona: int) -> bool:
	await _paso(dir)
	for i in 80:
		await create_timer(0.1).timeout
		if zm.zone_node != null and is_instance_valid(zm.zone_node) and zm.zone_node.zone_id == zona and not zm._changing_zone:
			casa = zm.zone_node
			await create_timer(0.3).timeout
			return true
	return false

func _camara_en(centro_esperado: Vector2) -> bool:
	return root.get_viewport().get_camera_2d().get_screen_center_position().distance_to(centro_esperado) < 0.5

# ------------------------------------------------------------------ paredes y muebles de la zona cargada
func _t_plano(titulo: String) -> void:
	print(titulo)
	await physics_frame
	await physics_frame
	var plano := _plano()
	var espacio : PhysicsDirectSpaceState2D = casa.get_world_2d().direct_space_state
	var mal : Array = []
	var rango : Rect2i = plano.rango
	for fila in range(rango.position.y, rango.end.y):
		for columna in range(rango.position.x, rango.end.x):
			var casilla := Vector2i(columna, fila)
			var consulta := PhysicsPointQueryParameters2D.new()
			consulta.position = _centro(casilla)
			consulta.exclude = [pm.player.get_rid()]
			var estorba : bool = espacio.intersect_point(consulta).any(func(golpe: Dictionary) -> bool: return golpe.collider is StaticBody2D)
			if estorba == _libre(casilla):   # las puertas y escaleras tambien estorban: se usan caminando contra ellas
				mal.append(casilla)
	_check("Cada baldosa estorba o se puede pisar segun el plano (incluye paredes y puertas)", mal.is_empty(), str(mal))
	var libres := 0
	for fila in plano.mapa:
		libres += fila.count(".")
	var llega := _alcanzables(_casilla(pm.player.global_position)).size()
	_check("A todo el piso libre se llega desde donde aparece Mayui", llega == libres, "%d de %d" % [llega, libres])

# ------------------------------------------------------------------ cuarto, antes de ducharse
func _t_cuarto() -> void:
	print("B. Cuarto: caminando antes de ducharse")
	await _empujar(Vector2i.RIGHT)
	_check("Cama: desde donde despierta basta girarse a la derecha", _delante() == ["Bed"] and pm.player.global_position.is_equal_approx(Vector2(88, 120)), str(_delante()))
	var oido : Array = await _hablar(_pulsar_z)
	_check("Cama: Z dice la frase del tutorial", oido == ["Si vuelvo ahí, no salgo."], str(oido))

	await _ir_a("Wardrobe", Vector2i(7, 6), Vector2i.RIGHT)
	oido = await _hablar(_pulsar_z)
	_check("Armario antes de ducharse: Z dice su frase", oido == ["Primero debería ducharme."], str(oido))

	await _ir_a("Kitchen", Vector2i(7, 3), Vector2i.RIGHT)
	var frases : Array = []
	for i in 4:
		frases.append_array(await _hablar(_pulsar_z))
	_check("Nevera antes de ducharse: tus frases y el aviso, sin abrir la cocina", frases == ["No quiero ni pensar en comida así.", "Luego.", "Quiero bañarme primero.", "Quiero bañarme primero."] and not casa.get_node("UILayer/KitchenMultiUI").visible, str(frases))

	await _ir_a("Escritorio", Vector2i(2, 4), Vector2i.LEFT)
	oido = await _hablar(_pulsar_z)
	_check("Escritorio antes de comer: dice para que sirve", oido == ["Aquí puedo comer cuando tenga algo listo."], str(oido))
	await _empujar(Vector2i.UP)
	_check("Calendario: desde la misma baldosa, mirando a la pared", _delante() == ["Calendario"], str(_delante()))
	frases = await _hablar(_pulsar_z)
	_check("Calendario, primera vez: tus 2 lineas", frases == ["El viernes pagan.", "Tengo que asegurarme de ir al supermercado con tiempo."], str(frases))
	frases = await _hablar(_pulsar_z)
	_check("Calendario, segunda vez: tus otras 2 lineas", frases == ["Tampoco puedo olvidarme del alquiler…", "Quiero evitar problemas con el casero."], str(frases))

	# Apartarse justo cuando algo esta ocupado (teclas deprisa) no debe dejarlo pegado
	var calendario = casa.get_node("Calendario")
	calendario.can_interact = false
	await _empujar(Vector2i.LEFT)
	calendario.can_interact = true
	_check("Apartarse de algo ocupado lo suelta: delante queda solo el escritorio", _delante() == ["Escritorio"], str(_delante()))
	oido = await _hablar(_pulsar_z)
	_check("...y Z en el escritorio no hace hablar al calendario", oido == ["Aquí puedo comer cuando tenga algo listo."], str(oido))

	dichos.clear()
	var recorrido : bool = await _caminar_a(Vector2i(6, 0)) and await _caminar_a(Vector2i(9, 0)) and await _caminar_a(Vector2i(7, 0))
	await create_timer(0.5).timeout
	_check("Puerta: pasar por delante no la activa", recorrido and dichos.is_empty() and dlg.current_timeline == null, str(dichos))
	oido = await _hablar(func() -> void: await _paso(Vector2i.UP))
	_check("Puerta: al caminar hacia ella sin la rutina habla y no deja salir", oido == ["..."] and current_scene == casa, str(oido))
	_check("Puerta: Mayui no se mete en el dibujo", pm.player.global_position.is_equal_approx(_centro(Vector2i(7, 0))), str(pm.player.global_position))
	oido = await _hablar(func() -> void: await _paso(Vector2i.UP))
	_check("Puerta: otro empujon vuelve a activarla, sin alejarse antes", oido == ["No puedo salir así."], str(oido))
	dichos.clear()
	await _pulsar_z()
	await create_timer(0.8).timeout
	_check("Puerta: Z delante de ella no hace nada (se usa caminando)", dichos.is_empty() and dlg.current_timeline == null, str(dichos))
	Input.action_press("move_up")
	await create_timer(0.3).timeout
	var primera : Array = dichos.duplicate()
	for i in 3:   # se pasa lo dicho sin soltar la tecla
		await _pulsar_z()
		await create_timer(0.8).timeout
	var seguidas : int = dichos.size()
	Input.action_release("move_up")
	await create_timer(0.3).timeout
	_check("Puerta: mantener la tecla la activa una sola vez", seguidas == 1, "%s -> %s" % [str(primera), str(dichos)])

	_check("Bano: se llega caminando a su puerta", await _caminar_a(Vector2i(5, 0)), str(pm.player.global_position))
	var energia : float = pm.get_stat_value("ENERGY")
	var hora : int = tm.minutes
	_check("Bano: al caminar hacia su puerta se entra", await _cruzar(Vector2i.LEFT, 4))
	_check("Bano: Mayui aparece junto a la puerta, sin gastar energia ni tiempo", pm.player.global_position.is_equal_approx(Vector2(72, 40)) and pm.get_stat_value("ENERGY") == energia and tm.minutes == hora, str(pm.player.global_position))

# ------------------------------------------------------------------ bano
func _t_bano() -> void:
	await _t_plano("C. Bano")
	_check("Bano: entero y centrado en pantalla", _camara_en(Vector2(40, 16)), str(root.get_viewport().get_camera_2d().get_screen_center_position()))
	await _ir_a("Sink", Vector2i(3, 1), Vector2i.UP)
	var oido : Array = await _hablar(_pulsar_z)
	_check("Lavamanos antes de ducharse: Z manda a la ducha", oido == ["Primero debería ducharme."], str(oido))
	await _ir_a("Shower", Vector2i(2, 0), Vector2i.LEFT)
	oido = await _hablar(_pulsar_z)
	_check("Ducha: Z banya a Mayui", pm.get_outfit_id() == "towel" and tk.get_task_list_res("TUTORIAL_DOOR").get_task_res("BATHE").task_done and oido.size() == 5, str(oido))
	_check("Bano: se llega caminando a la salida", await _caminar_a(Vector2i(4, 2)), str(pm.player.global_position))
	_check("Bano: al caminar hacia la puerta se vuelve al cuarto", await _cruzar(Vector2i.RIGHT, 0))
	_check("Mayui aparece junto a la puerta del bano", pm.player.global_position.is_equal_approx(Vector2(88, 8)), str(pm.player.global_position))

# ------------------------------------------------------------------ cuarto, ya duchada
func _t_despues_del_bano() -> void:
	print("D. Cuarto: ya duchada")
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
	await create_timer(0.9).timeout   # entra con su transicion
	_check("Armario despues de ducharse: Z lo abre", armario.visible and gm.modal_count == 1)
	armario.close()
	await create_timer(0.9).timeout   # sale con su transicion

	# calendario despues de volver del bano: se acuerda de lo ya leido
	_check("Calendario: se llega caminando", await _caminar_a(Vector2i(2, 4)), str(pm.player.global_position))
	await _empujar(Vector2i.UP)
	var frases : Array = []
	for i in 2:
		frases.append_array(await _hablar(_pulsar_z))
	_check("Calendario ya leido (tras volver del bano): el aviso", frases == ["Suficiente, tengo que irme.", "Suficiente, tengo que irme."], str(frases))
	# escritorio despues de comer
	tk.get_task_list_res("TUTORIAL_DOOR").get_task_res("COOK").task_done = true
	await _empujar(Vector2i.LEFT)
	frases = []
	for i in 4:
		frases.append_array(await _hablar(_pulsar_z))
	_check("Escritorio despues de comer: tus frases y el aviso", frases == ["No puedo quedarme aquí.", "Voy tarde.", "Ya terminé de comer, no tengo nada que hacer acá.", "Ya terminé de comer, no tengo nada que hacer acá."], str(frases))

	# esquinas: las paredes frenan y la camara no se mueve
	for esquina in [[Vector2i(9, 0), Vector2i.RIGHT, Vector2i.UP], [Vector2i(2, 8), Vector2i.LEFT, Vector2i.DOWN], [Vector2i(0, 5), Vector2i.LEFT, Vector2i.UP]]:
		var llego : bool = await _caminar_a(esquina[0])
		await _empujar(esquina[1])
		await _empujar(esquina[2])
		_check("Esquina %s: las paredes y muebles la frenan" % str(esquina[0]), llego and pm.player.global_position.is_equal_approx(_centro(esquina[0])), str(pm.player.global_position))
		_check("Esquina %s: el cuarto entero sigue en pantalla (camara fija)" % str(esquina[0]), _camara_en(Vector2(80, 56)), str(root.get_viewport().get_camera_2d().get_screen_center_position()))

# ------------------------------------------------------------------ balcon
func _t_balcon() -> void:
	print("E. Balcon")
	_check("Balcon: se llega caminando a su puerta", await _caminar_a(Vector2i(3, 8)), str(pm.player.global_position))
	var oidas : Array = []
	for i in 3:   # tres empujones seguidos, sin retroceder
		oidas.append_array(await _hablar(func() -> void: await _paso(Vector2i.DOWN)))
	_check("Balcon en la manana del tutorial: tus 2 frases y el aviso, sin salir", oidas == ["No tengo tiempo.", "Luego.", "Debo apresurarme."] and casa.zone_id == 0, str(oidas))
	root.get_node("NarrativeFlags").set_flag("tutorial_door_done")
	var energia : float = pm.get_stat_value("ENERGY")
	var hora : int = tm.minutes
	_check("Balcon: pasada la manana del tutorial se sale", await _cruzar(Vector2i.DOWN, 5))
	_check("Balcon: aparece junto a la puerta, sin gastar energia ni tiempo", pm.player.global_position.is_equal_approx(Vector2(40, 8)) and pm.get_stat_value("ENERGY") == energia and tm.minutes == hora, str(pm.player.global_position))
	await _t_plano("F. Balcon: paredes y piso")
	_check("Balcon: entero y centrado en pantalla", _camara_en(Vector2(48, 8)), str(root.get_viewport().get_camera_2d().get_screen_center_position()))
	_check("Balcon: se vuelve al cuarto", await _cruzar(Vector2i.UP, 0))
	_check("Mayui aparece junto a la puerta del balcon", pm.player.global_position.is_equal_approx(Vector2(56, 136)), str(pm.player.global_position))

# ------------------------------------------------------------------ pasillo y recepcion
func _t_edificio() -> void:
	print("G. Del cuarto a la calle: pasillo y recepcion")
	for id in ["BATHE", "CLOTHES", "COOK", "TEETH"]:   # la rutina completa, con el uniforme puesto
		tk.done_task("TUTORIAL_DOOR", id)
	pm.wear_clothes(pm.wardrobe.filter(func(i) -> bool: return pm.outfit_id_of(i) == "work")[0])
	_check("Del cuarto se camina hasta la puerta principal", await _caminar_a(Vector2i(7, 0)), str(pm.player.global_position))
	var energia : float = pm.get_stat_value("ENERGY")
	var hora : int = tm.minutes
	_check("La puerta principal lleva al pasillo", await _cruzar(Vector2i.UP, 6))
	_check("Pasillo: aparece junto a M-21, dentro de su hueco, sin gastar energia ni tiempo", pm.player.global_position.is_equal_approx(Vector2(104, 24)) and pm.get_stat_value("ENERGY") == energia and tm.minutes == hora, str(pm.player.global_position))
	await _t_plano("H. Pasillo: paredes y piso")
	_check("Pasillo: entero en pantalla", _camara_en(Vector2(80, 92)), str(root.get_viewport().get_camera_2d().get_screen_center_position()))
	_check("Pasillo: se entra en el hueco de M-22 hasta su puerta", await _caminar_a(Vector2i(3, 1)), str(pm.player.global_position))
	var callada : Array = await _hablar(func() -> void: await _paso(Vector2i.LEFT))
	_check("M-22 (de otro vecino) esta cerrada: no pasa nada", callada.is_empty() and casa.zone_id == 6 and pm.player.global_position.is_equal_approx(_centro(Vector2i(3, 1))), str(callada))
	_check("Pasillo: se camina hasta las escaleras", await _caminar_a(Vector2i(4, 4)), str(pm.player.global_position))
	_check("Las escaleras bajan a la recepcion", await _cruzar(Vector2i.LEFT, 1))
	_check("Recepcion: aparece al pie de las escaleras, sin gastar energia ni tiempo", pm.player.global_position.is_equal_approx(Vector2(72, 56)) and pm.get_stat_value("ENERGY") == energia and tm.minutes == hora, "%s %.1f +%d" % [str(pm.player.global_position), pm.get_stat_value("ENERGY"), tm.minutes - hora])
	await create_timer(1.0).timeout
	if dlg.current_timeline != null:   # el casero la intercepta (su dialogo tiene opciones: aqui se corta)
		dlg.end_timeline()
	await create_timer(1.5).timeout
	await _t_plano("I. Recepcion: paredes y piso")
	_check("Recepcion: entera en pantalla", _camara_en(Vector2(80, 96)), str(root.get_viewport().get_camera_2d().get_screen_center_position()))
	_check("Recepcion: se entra en el hueco de mantenimiento", await _caminar_a(Vector2i(6, 9)), str(pm.player.global_position))
	var aviso : Array = await _hablar(func() -> void: await _paso(Vector2i.RIGHT))
	_check("Puerta de mantenimiento: dice lo que es y no deja pasar", aviso == ["Cuarto de mantenimiento."] and casa.zone_id == 1 and pm.player.global_position.is_equal_approx(_centro(Vector2i(6, 9))), str(aviso))
	var dinero : int = root.get_node("EconomyManager").money
	_check("Recepcion: se camina hasta la puerta de la calle", await _caminar_a(Vector2i(2, 11)), str(pm.player.global_position))
	_check("La puerta de la calle lleva en bus a la oficina (S/10)", await _cruzar(Vector2i.DOWN, 2) and root.get_node("EconomyManager").money == dinero - 10, "dinero %d -> %d" % [dinero, root.get_node("EconomyManager").money])
	zm.change_zone(1)
	await create_timer(3.0).timeout
	casa = zm.zone_node
	_check("De la oficina se vuelve a la puerta de la calle", casa.zone_id == 1 and pm.player.global_position.is_equal_approx(Vector2(40, 184)), str(pm.player.global_position))
	if dlg.current_timeline != null:
		dlg.end_timeline()
		await create_timer(1.5).timeout
	_check("Se vuelve caminando a las escaleras", await _caminar_a(Vector2i(4, 4)), str(pm.player.global_position))
	_check("Las escaleras suben al pasillo", await _cruzar(Vector2i.LEFT, 6))
	_check("Pasillo: aparece junto a las escaleras", pm.player.global_position.is_equal_approx(Vector2(72, 56)), str(pm.player.global_position))
	_check("Pasillo: se entra en el hueco de M-21", await _caminar_a(Vector2i(6, 1)), str(pm.player.global_position))
	_check("M-21 vuelve a casa", await _cruzar(Vector2i.RIGHT, 0))
	_check("En casa aparece junto a la puerta principal", pm.player.global_position.is_equal_approx(Vector2(120, 8)), str(pm.player.global_position))
