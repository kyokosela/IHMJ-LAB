extends SceneTree
## Pruebas automaticas del FLUJO del juego (zonas, Mayui quieta con una UI abierta, dialogos sin texto
## de relleno, eventos de historia, asistencia y acciones del apartamento). Usa los nodos y autoloads REALES.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_flujo.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla. Las pruebas de efectos estan en probar_efectos.gd.

var pm
var gm
var zm
var tm
var evm
var att
var dlg
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
	tm = root.get_node("TimeManager")
	evm = root.get_node("EventManager")
	att = root.get_node("AttendanceManager")
	dlg = root.get_node("Dialogic")
	await create_timer(0.3).timeout
	gm.game_started = true   # que el apartamento no reinicie la partida al cargarse
	await _t_zonas()
	await _t_bloqueo_con_ui()
	await _t_dialogos()
	_t_historia()
	_t_asistencia()
	await _t_apartamento()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
## Carga una zona como si Mayui llegara desde `origen` (ZoneManager.previous_zone).
func _cargar(ruta: String, origen: int) -> Node:
	zm.previous_zone = origen
	var escena : Node = (load(ruta) as PackedScene).instantiate()
	root.add_child(escena)
	await process_frame
	return escena

## Cierra la zona igual que ZoneManager.change_zone: primero devuelve a Mayui y la camara.
func _soltar(escena: Node) -> void:
	escena.release_player()
	root.remove_child(escena)
	escena.free()
	zm.zone_node = null   # que nadie lea una zona ya liberada
	await process_frame

# ------------------------------------------------------------------ A. puntos de aparicion
func _t_zonas() -> void:
	print("A. Puntos de aparicion por zona")
	var casos := [
		["res://Scenes/World/Lobby.tscn", 2, Vector2(180, 100), "Lobby viniendo de la oficina: junto a la puerta de la oficina"],
		["res://Scenes/World/Lobby.tscn", 0, Vector2(100, 100), "Lobby viniendo del apartamento: punto general"],
		["res://Scenes/World/Apartment.tscn", 1, Vector2(160, 100), "Apartamento viniendo del lobby: junto a la puerta"],
		["res://Scenes/World/Apartment.tscn", -1, Vector2(100, 100), "Apartamento al empezar: junto a la cama"],
		["res://Scenes/World/Office.tscn", 1, Vector2(100, 160), "Oficina: su unico punto"],
	]
	for c in casos:
		var escena = await _cargar(c[0], c[1])
		_check(c[3], pm.player.global_position.is_equal_approx(c[2]), str(pm.player.global_position))
		await _soltar(escena)

# ------------------------------------------------------------------ B. Mayui quieta con una UI abierta
func _t_bloqueo_con_ui() -> void:
	print("B. Mayui queda quieta con una UI abierta")
	var escena = await _cargar("res://Scenes/World/Office.tscn", 1)
	var mov = pm.player.movement
	gm.modal_count = 0
	_check("Sin UI abierta puede moverse", mov.can_move)
	escena.interaction_open_workspace()
	_check("PC abierto: Mayui queda quieta", not mov.can_move and gm.modal_count == 1 and gm.is_input_blocked())
	escena.interaction_open_workspace()
	_check("Abrir el PC otra vez no cuenta doble", gm.modal_count == 1)
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	escena._input(esc)
	_check("Esc cierra el PC y Mayui vuelve a moverse", mov.can_move and gm.modal_count == 0 and not escena.workspace.visible)
	gm.modal_count += 1
	gm.modal_count += 1
	gm.modal_count -= 1
	_check("Dos UIs y una cerrada: sigue quieta", not mov.can_move)
	gm.modal_count -= 1
	_check("Cerradas todas: vuelve a moverse", mov.can_move)
	gm.modal_count -= 1
	_check("El contador nunca baja de 0", gm.modal_count == 0)
	await _soltar(escena)

# ------------------------------------------------------------------ C. dialogos sin texto de relleno
## Reproduce un dialogo de verdad y devuelve [{quien, texto}, ...] con lo que Dialogic muestra.
func _jugar_dialogo(nombre: String) -> Array:
	var lineas : Array = []
	var cb := func(info) -> void:
		var ch = info.get("character", null)
		lineas.append({"quien": ch.get_display_name_translated() if ch != null else "", "texto": str(info.get("text", ""))})
	dlg.Text.text_started.connect(cb)
	dlg.start(nombre)
	for i in 80:
		await create_timer(0.12).timeout
		if dlg.current_timeline == null:
			break
		dlg.handle_next_event()
	if dlg.current_timeline != null:
		dlg.end_timeline()
	dlg.Text.text_started.disconnect(cb)
	return lineas

func _t_dialogos() -> void:
	print("C. Dialogos sin texto de relleno")
	var lineas : Array = await _jugar_dialogo("casero_rent_reminder")
	var textos : String = " | ".join(lineas.map(func(l): return l.texto))
	_check("El recordatorio del casero se reproduce completo", lineas.size() >= 8, textos)
	_check("Ya no aparece el 'Hola como estas' de prueba", not textos.contains("Hola como estas") and not textos.contains("Bien y tu"), textos)
	_check("El final es el escrito por ti", textos.contains("Hasta mañana") and textos.contains("Cuelga sin despedirse"), textos)
	var nombres : Array = lineas.map(func(l): return l.quien)
	_check("Mayui se llama Mayui (no 'test_char')", "Mayui" in nombres and not ("test_char" in nombres), str(nombres))
	_check("El casero tiene nombre", "Casero" in nombres, str(nombres))

# ------------------------------------------------------------------ D. historia de relleno apagada
func _t_historia() -> void:
	print("D. Historia de relleno apagada")
	var neh = root.get_node("NarrativeEventHandler")
	var flags = root.get_node("NarrativeFlags")
	var antes : bool = neh.story_enabled
	neh._pending.clear()
	neh.story_enabled = false
	neh._on_event_activated("DAY2_MADINA_CAFE")
	_check("Historia apagada: el evento de Madina ni queda pendiente", neh._pending.is_empty())
	neh._on_fired("EXCESSIVE_ABSENCES")
	_check("Historia apagada: el despido no pone bandera ni lanza dialogo", not flags.has_flag("fired") and dlg.current_timeline == null)
	neh.story_enabled = true
	neh._on_event_activated("DAY2_MADINA_CAFE")
	_check("Historia encendida: el evento de Madina espera su zona (la oficina)", neh._pending.size() == 1)
	neh._pending.clear()
	neh.story_enabled = false
	neh._on_event_activated("DAY1_CASERO_INTRO")
	_check("El casero NO es relleno: sigue su camino (espera el lobby)", neh._pending.size() == 1)
	neh._pending.clear()
	neh.story_enabled = antes

# ------------------------------------------------------------------ E. asistencia
func _t_asistencia() -> void:
	print("E. Asistencia: una falta por dia y un solo despido")
	var despidos := [0]
	var cb := func(_razon) -> void: despidos[0] += 1
	att.fired.connect(cb)
	att.absence_count = 0
	att.arrived_today = false
	att.absence_recorded_today = false
	tm.julian_day = 0                       # lunes
	tm.minutes = 17 * 60 + 5
	att.record_absence()
	att.record_absence()
	_check("Dos avisos de falta el mismo dia cuentan una sola vez", att.absence_count == 1, str(att.absence_count))
	tm.minutes = 23 * 60
	tm.add_to_current_time("02:00")         # cruza lunes -> martes
	_check("La medianoche no cuenta otra vez la falta ya anotada", att.absence_count == 1, str(att.absence_count))
	# martes, miercoles, jueves y viernes sin ir a trabajar: una falta por dia
	var esperadas := [2, 3, 4, 5]
	for i in 4:
		tm.add_to_current_time("12:00")
		tm.add_to_current_time("12:00")      # cruza a la medianoche siguiente
		_check("Dia laboral %d sin ir: %d faltas" % [i + 2, esperadas[i]], att.absence_count == esperadas[i], str(att.absence_count))
	_check("Despedida una sola vez (no se repite con cada falta nueva)", despidos[0] == 1, str(despidos[0]))
	tm.add_to_current_time("12:00")
	tm.add_to_current_time("12:00")          # sabado -> domingo
	_check("El fin de semana no cuenta como falta", att.absence_count == 5, str(att.absence_count))
	att.fired.disconnect(cb)
	att.absence_count = 0

# ------------------------------------------------------------------ F. apartamento
## Espera a que no haya ningun dialogo en curso (cierra los que Dialogic vaya arrancando con retraso).
func _esperar_calma() -> void:
	var tranquilo := 0
	for i in 40:
		await create_timer(0.2).timeout
		if dlg.current_timeline != null:
			dlg.end_timeline()
			tranquilo = 0
		else:
			tranquilo += 1
			if tranquilo >= 3:
				return

## Ejecuta una accion (como si Mayui pulsara Z) y devuelve lo que Mayui dice (hasta 2 s: Dialogic tarda en arrancar).
func _ejecutar_y_oir(accion) -> Array:
	await _esperar_calma()
	var dicho : Array = []
	var escuchar := func(info) -> void: dicho.append(str(info.get("text", "")))
	dlg.Text.text_started.connect(escuchar)
	accion.can_interact = true
	accion.execute()
	for i in 20:
		await create_timer(0.1).timeout
		if not dicho.is_empty():
			break
	dlg.Text.text_started.disconnect(escuchar)
	return dicho

func _t_apartamento() -> void:
	print("F. Apartamento: ducha con cooldown, lavamanos con requisito y nevera")
	gm.new_game()
	pm.reset_engine_state(true)
	var escena = await _cargar("res://Scenes/World/Apartment.tscn", -1)
	var ducha = escena.get_node("Shower")
	var usos_ducha := [0]
	ducha.executed.connect(func(): usos_ducha[0] += 1)
	await _esperar_calma()
	var hora0 : int = tm.minutes
	var energia0 : float = pm.get_stat_value("ENERGY")
	await _ejecutar_y_oir(ducha)
	_check("Ducha: cuesta 20 min y 10 de energia", tm.minutes - hora0 == 20 and absf((energia0 - pm.get_stat_value("ENERGY")) - 10.0) < 0.01, "%d min, %.1f de energia" % [tm.minutes - hora0, energia0 - pm.get_stat_value("ENERGY")])
	_check("Ducha: cuenta como bano del dia y da Atenta (agua fria del tutorial)", pm.daily.bathed and pm.has_effect("ATENTA"))
	var hora1 : int = tm.minutes
	var dicho : Array = await _ejecutar_y_oir(ducha)
	_check("Segunda ducha seguida: no se repite ni pasa el tiempo", usos_ducha[0] == 1 and tm.minutes == hora1, "usos %d, +%d min" % [usos_ducha[0], tm.minutes - hora1])
	_check("...y Mayui avisa que ya se bano", dicho.size() > 0 and dicho[0].contains("bañé"), str(dicho))
	# salir y volver al apartamento: la ducha sigue en cooldown
	await _soltar(escena)
	escena = await _cargar("res://Scenes/World/Apartment.tscn", 1)
	var ducha2 = escena.get_node("Shower")
	var hora2 : int = tm.minutes
	dicho = await _ejecutar_y_oir(ducha2)
	_check("Al volver de otra zona la ducha SIGUE en cooldown", ducha2.cooldown_executed and tm.minutes == hora2 and dicho.size() > 0, "+%d min, dijo %s" % [tm.minutes - hora2, str(dicho)])
	tm.add_to_current_time("05:01")
	_check("Pasadas 5 h el cooldown termina y se puede volver a duchar", not ducha2.cooldown_executed and not ducha2.is_cooldown and ducha2.can_interact)
	# lavamanos: solo si hay suciedad
	var lavamanos = escena.get_node("Sink")
	var usos_lav := [0]
	lavamanos.executed.connect(func(): usos_lav[0] += 1)
	pm.remove_effect("SMELLY")
	dicho = await _ejecutar_y_oir(lavamanos)
	_check("Lavamanos sin suciedad: no se usa y Mayui avisa", usos_lav[0] == 0 and dicho.size() > 0 and dicho[0].contains("necesito"), str(dicho))
	pm.add_effect(load("res://Resources/Effects/Effects/smelly.tres").duplicate())
	await _ejecutar_y_oir(lavamanos)
	_check("Lavamanos con suciedad: se usa y la quita", usos_lav[0] == 1 and not pm.has_effect("SMELLY"))
	# nevera: la comida cuenta para la Rutina saludable
	var nevera = escena.get_node("Fridge")
	var comidas0 : int = pm.daily.home_meals
	await _ejecutar_y_oir(nevera)
	_check("Nevera: cuenta como comida casera", pm.daily.home_meals == comidas0 + 1, str(pm.daily.home_meals))
	await _esperar_calma()
	await _soltar(escena)
