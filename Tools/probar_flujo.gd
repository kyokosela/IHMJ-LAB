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
	await _t_madina()
	_t_asistencia()
	await _t_transicion()
	await _t_apartamento()
	await _t_cocina()
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
		["res://Scenes/World/Apartment.tscn", 1, Vector2(120, 8), "Apartamento viniendo del lobby: junto a la puerta"],
		["res://Scenes/World/Apartment.tscn", -1, Vector2(88, 120), "Apartamento al empezar: junto a la cama"],
		["res://Scenes/World/Apartment.tscn", 4, Vector2(88, 24), "Apartamento viniendo del bano: junto a la puerta del bano"],
		["res://Scenes/World/Bathroom.tscn", 0, Vector2(72, 40), "Bano: junto a su puerta"],
		["res://Scenes/World/Apartment.tscn", 5, Vector2(56, 136), "Apartamento viniendo del balcon: junto a la puerta del balcon"],
		["res://Scenes/World/Balcony.tscn", 0, Vector2(40, 8), "Balcon: junto a su puerta"],
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

## Hablar con Madina con la historia apagada no debe soltar sus dialogos de relleno.
func _t_madina() -> void:
	var neh = root.get_node("NarrativeEventHandler")
	var antes : bool = neh.story_enabled
	neh.story_enabled = false
	var escena = await _cargar("res://Scenes/World/Office.tscn", 1)
	tm.day = 2   # el dia en que antes salia su historia de la cafeteria
	var dicho : Array = await _ejecutar_y_oir(escena.get_node("MadinaNPC"))
	_check("Historia apagada: Madina solo responde '...'", dicho.size() > 0 and dicho[0].strip_edges() == "...", str(dicho))
	await _esperar_calma()
	await _soltar(escena)
	tm.day = 1
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

# ------------------------------------------------------------------ G. cambio de zona
func _t_transicion() -> void:
	print("G. Cambio de zona: Mayui quieta y 2 s en total")
	var tr = root.get_node("TransitionManager")
	# un solo fundido a la vez
	var emitidos := [0]
	var cb := func() -> void: emitidos[0] += 1
	tr.transition_finished.connect(cb)
	tr.fadeIn(0.4)
	await create_timer(0.1).timeout
	tr.fadeOut(0.4)
	await create_timer(0.7).timeout
	tr.transition_finished.disconnect(cb)
	_check("Dos fundidos seguidos: solo el ultimo avisa y la pantalla queda clara", emitidos[0] == 1 and tr.color_rect.color.a < 0.01, "avisos %d, alfa %.2f" % [emitidos[0], tr.color_rect.color.a])
	# cambio de zona de verdad: Apartamento -> Lobby
	gm.modal_count = 0
	zm.current_zone = 0
	zm.previous_zone = -1
	var escena : Node = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(escena)
	current_scene = escena
	await create_timer(1.3).timeout          # que termine el fundido de entrada de la escena
	var mov = pm.player.movement
	# entre cuartos de la casa (Apartamento <-> Bano) no es viajar: ni energia, ni tiempo
	var energia_casa : float = pm.get_stat_value("ENERGY")
	var hora_casa : int = tm.minutes
	zm.change_zone(4)
	_check("Al entrar al bano Mayui queda quieta durante el cambio", not mov.can_move and gm.modal_count == 1)
	await _esperar_zona(4)
	_check("Llega al bano sin gastar energia ni tiempo y puede moverse", current_scene.zone_id == 4 and pm.get_stat_value("ENERGY") == energia_casa and tm.minutes == hora_casa and mov.can_move, "zona %d, energia %.1f, +%d min" % [current_scene.zone_id, pm.get_stat_value("ENERGY"), tm.minutes - hora_casa])
	zm.change_zone(0)
	await _esperar_zona(0)
	_check("Vuelve al cuarto junto a la puerta del bano, tambien sin costo", current_scene.zone_id == 0 and pm.player.global_position.is_equal_approx(Vector2(88, 24)) and pm.get_stat_value("ENERGY") == energia_casa and tm.minutes == hora_casa, str(pm.player.global_position))
	var energia_pie : float = pm.get_stat_value("ENERGY")
	var t0 := Time.get_ticks_msec()
	zm.change_zone(1)
	_check("Al tocar la puerta Mayui queda quieta", not mov.can_move and gm.modal_count == 1)
	_check("A pie (Apartamento -> Lobby) se gasta energia", pm.get_stat_value("ENERGY") < energia_pie, "%.1f -> %.1f" % [energia_pie, pm.get_stat_value("ENERGY")])
	zm.change_zone(2)                         # una puerta pisada otra vez durante el viaje no cuenta
	_check("Una segunda puerta durante el viaje se ignora", gm.modal_count == 1 and zm.current_zone == 1, "zona %d" % zm.current_zone)
	await create_timer(1.3).timeout           # ya oscuro y con la escena cambiada: sigue quieta
	_check("A mitad del viaje sigue quieta", not mov.can_move and gm.modal_count == 1)
	while gm.modal_count > 0 and Time.get_ticks_msec() - t0 < 5000:
		await create_timer(0.05).timeout
	var total : float = (Time.get_ticks_msec() - t0) / 1000.0
	_check("El viaje dura 2 s en total (1 s oscurece, 1 s aclara)", total > 1.9 and total < 2.6, "%.2f s" % total)
	_check("Al terminar Mayui vuelve a moverse", mov.can_move and gm.modal_count == 0)
	_check("Llego al lobby viniendo del apartamento", current_scene != null and current_scene.zone_id == 1 and pm.player.global_position.is_equal_approx(Vector2(100, 100)), str(pm.player.global_position))
	# en bus: se paga con dinero, no con energia
	var economia = root.get_node("EconomyManager")
	var energia_bus : float = pm.get_stat_value("ENERGY")
	var dinero : int = economia.money
	zm.change_zone(2)
	_check("En bus (Lobby -> Oficina) cuesta S/10 y no gasta energia", pm.get_stat_value("ENERGY") == energia_bus and economia.money == dinero - 10, "energia %.1f -> %.1f, dinero %d -> %d" % [energia_bus, pm.get_stat_value("ENERGY"), dinero, economia.money])
	t0 = Time.get_ticks_msec()
	await create_timer(1.3).timeout
	while gm.modal_count > 0 and Time.get_ticks_msec() - t0 < 5000:
		await create_timer(0.05).timeout
	# ir y volver a pie no acumula cansancio, aunque se pase por el bano entremedio
	zm.current_zone = 0
	zm.previous_zone = -1
	zm.change_zone(1)
	await _esperar_zona(1)
	zm.change_zone(0)
	await _esperar_zona(0)
	zm.change_zone(4)
	await _esperar_zona(4)
	zm.change_zone(0)
	await _esperar_zona(0)
	zm.change_zone(1)
	await _esperar_zona(1)
	_check("Salir otra vez tras pasar por el bano cuesta lo basico (el bano no cuenta como viaje)", zm.energy_cost_incremental == zm.energy_cost_base, "%.1f" % zm.energy_cost_incremental)
	if current_scene != null:
		current_scene.release_player()
		current_scene.queue_free()
	zm.zone_node = null
	zm.current_zone = 0
	zm.previous_zone = -1
	await process_frame

## Espera a que Mayui este en la zona pedida y ya pueda moverse.
func _esperar_zona(zona: int) -> void:
	for i in 80:
		await create_timer(0.1).timeout
		if zm.zone_node != null and is_instance_valid(zm.zone_node) and zm.zone_node.zone_id == zona and not zm._changing_zone:
			return

# ------------------------------------------------------------------ dibujos de las casillas
## La casilla de la UI para ese indice (o null).
func _casilla(casillas: Node, indice: int) -> Node:
	for c in casillas.get_children():
		if not c.is_queued_for_deletion() and c.get("slot_index") == indice:
			return c
	return null

## Nombre del dibujo que muestra la casilla de la UI para ese indice.
func _dibujo(casillas: Node, indice: int) -> String:
	var c : Node = _casilla(casillas, indice)
	if c == null: return "(sin casilla)"
	var t = c.get_node("Icon").texture
	return t.resource_path.get_file() if t != null else "(nada)"

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
	print("F. Apartamento: ducha con cooldown y lavamanos (espejo)")
	gm.new_game()
	pm.reset_engine_state(true)
	var escena = await _cargar("res://Scenes/World/Bathroom.tscn", 0)
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
	_check("...y Mayui avisa que ya se bano", dicho.size() > 0 and dicho[0].strip_edges() == "Ya estoy limpia.", str(dicho))
	# salir y volver al bano: la ducha sigue en cooldown
	await _soltar(escena)
	escena = await _cargar("res://Scenes/World/Bathroom.tscn", 0)
	var ducha2 = escena.get_node("Shower")
	var hora2 : int = tm.minutes
	dicho = await _ejecutar_y_oir(ducha2)
	_check("Al volver de otra zona la ducha SIGUE en cooldown", ducha2.cooldown_executed and tm.minutes == hora2 and dicho.size() > 0, "+%d min, dijo %s" % [tm.minutes - hora2, str(dicho)])
	tm.add_to_current_time("05:01")
	_check("Pasadas 5 h el cooldown termina y se puede volver a duchar", not ducha2.cooldown_executed and not ducha2.is_cooldown and ducha2.can_interact)
	pm.increase_stat("ENERGY", 100)
	await _ejecutar_y_oir(ducha2)             # otro bano: enfriamiento nuevo
	dicho = await _ejecutar_y_oir(ducha2)     # insistir
	_check("Con otro bano las frases al insistir vuelven a la primera", dicho.size() > 0 and dicho[0].strip_edges() == "Ya estoy limpia.", str(dicho))
	# lavamanos (pantalla del espejo): antes de comer Mayui avisa; despues de comer se abre
	var lavamanos = escena.get_node("Sink")
	var espejo = escena.get_node("UILayer/MirrorUI")
	var usos_lav := [0]
	lavamanos.executed.connect(func(): usos_lav[0] += 1)
	var cocinar = root.get_node("TaskManager").get_task_list_res("TUTORIAL_DOOR").get_task_res("COOK")
	cocinar.task_done = false
	dicho = await _ejecutar_y_oir(lavamanos)
	_check("Lavamanos antes de comer (tutorial): no abre el espejo y Mayui avisa que primero debe comer", usos_lav[0] == 0 and not espejo.visible and dicho.size() > 0 and dicho[0].contains("comer"), str(dicho))
	cocinar.task_done = true
	await _ejecutar_y_oir(lavamanos)
	_check("Lavamanos despues de comer: abre la pantalla del espejo y Mayui queda quieta", usos_lav[0] == 1 and espejo.visible and gm.modal_count == 1)
	espejo.close()
	cocinar.task_done = false
	await _esperar_calma()
	# cama: se puede salir de la pantalla de la alarma sin dormir (boton Cancelar o Esc). En la manana del tutorial la cama
	# no deja dormir (probar_tutorial.gd): aqui se prueba despues de ella.
	root.get_node("NarrativeFlags").set_flag("tutorial_door_done")
	await _soltar(escena)
	escena = await _cargar("res://Scenes/World/Apartment.tscn", -1)
	await _esperar_calma()
	var cama = escena.get_node("Bed")
	pm.slept_today = false
	for salida in ["Cancelar", "Esc"]:
		var hora3 : int = tm.minutes
		cama.can_interact = true
		cama.execute()
		await create_timer(0.3).timeout
		var alarma : Node = _buscar_alarma()
		_check("Dormir abre la pantalla de la alarma (%s)" % salida, alarma != null and gm.modal_count == 1)
		if alarma == null:
			continue
		if salida == "Cancelar":
			alarma.get_node("Center/Panel/VBox/Margin/Inner/Buttons/CancelButton").pressed.emit()
		else:
			var esc := InputEventAction.new()
			esc.action = "ui_cancel"
			esc.pressed = true
			alarma._unhandled_input(esc)
		await create_timer(0.3).timeout
		_check("%s: sale sin dormir, sin pasar el tiempo y Mayui vuelve a moverse" % salida, _buscar_alarma() == null and gm.modal_count == 0 and tm.minutes == hora3 and not pm.slept_today and dlg.current_timeline == null)
	await _soltar(escena)

func _buscar_alarma() -> Node:
	for capa in root.get_children():
		var ui : Node = capa.get_node_or_null("AlarmUI")
		if ui != null and not ui.is_queued_for_deletion():
			return ui
	return null

# ------------------------------------------------------------------ H. cocina real (tu sistema de contenedores)
## Mueve un objeto de un slot a otro del mismo inventario, igual que arrastrar en la UI (interact_inventory).
func _arrastrar(inv, destino: int, origen: int) -> void:
	inv.interact_inventory(destino, inv, origen)

## Saca la olla de la cocina (donde este) o de las manos de Mayui.
func _tomar_olla(kc):
	var inv = kc.inventory
	for s in inv.slots:
		if not s.is_empty() and s.item.data.item_unique_name == "cooking_pot":
			var o = s.item
			s.clear()
			return o
	var manos = pm.player.inventory
	for o in manos.get_hands_items():
		if o.data.item_unique_name == "cooking_pot":
			manos.remove_from_hands(o)
			return o
	return null

## Una comida completa con tu cocina: bolsa -> tabla de picar -> olla + ingredientes en "Combinar" -> estufa 45 min.
## Devuelve la olla con la comida dentro (ya fuera de la cocina) o null si algo falla.
func _cocinar_una(kc):
	var inv = kc.inventory
	var bolsa_idx : int = -1
	for i in kc.get_storage_indices():
		if not inv.slots[i].is_empty() and inv.slots[i].item.data.item_unique_name == "ingredients_bag":
			bolsa_idx = i
			break
	if bolsa_idx == -1:
		return null
	_arrastrar(inv, kc.get_station_slot_index("cutting"), bolsa_idx)
	if not kc.start_manual_station_craft("cutting"):
		return null
	var olla = _tomar_olla(kc)
	if olla == null:
		return null
	var entradas : Array = kc.get_simple_craft_input_indices()
	inv.slots[entradas[0]].item = olla
	_arrastrar(inv, entradas[1], kc.get_station_slot_index("cutting"))
	if kc.check_simple_craft() == null:
		return null
	var llena = kc.execute_simple_craft()
	if llena == null:
		return null
	inv.slots[kc.get_station_slot_index("stove")].item = llena
	inv.inventory_changed.emit()
	if not kc.start_manual_station_craft("stove"):
		return null
	tm.minutes_delta.emit(45)
	return _tomar_olla(kc)
func _t_cocina() -> void:
	print("H. Cocina real: nevera, tabla de picar, olla, estufa y comer")
	root.get_node("ContainerManager").container_states.clear()
	gm.new_game()
	pm.reset_engine_state(true)
	var tarea = root.get_node("TaskManager").get_task_list_res("TUTORIAL_DOOR").get_task_res("COOK")
	tarea.task_done = false
	var escena = await _cargar("res://Scenes/World/Apartment.tscn", -1)
	await _esperar_calma()
	var cocina = escena.get_node("Kitchen")
	var kc = cocina.container
	var inv = kc.inventory
	var ui = escena.get_node("UILayer/KitchenMultiUI")
	var mov = pm.player.movement
	# 1) la nevera: 2 bolsas de ingredientes en el ALMACENAMIENTO (no en las estaciones)
	var guardados : Array = kc.get_storage_indices().filter(func(i): return not inv.slots[i].is_empty())
	_check("La nevera trae 2 bolsas de ingredientes y la olla en el almacenamiento", guardados.size() == 3 and inv.slots[guardados[0]].item.data.item_unique_name == "ingredients_bag" and inv.slots[guardados[1]].item.data.item_unique_name == "ingredients_bag" and inv.slots[guardados[2]].item.data.item_unique_name == "cooking_pot", str(guardados))
	_check("Las estaciones empiezan vacias", kc.get_station_item("cutting") == null and kc.get_station_item("stove") == null and kc.get_station_item("sink") == null)
	# 2) abrir la cocina: la UI se ve y Mayui queda quieta
	cocina.can_interact = true
	cocina.execute()
	_check("Abrir la cocina: se ve la UI y Mayui queda quieta", ui.visible and not mov.can_move and gm.modal_count == 1)
	# 2b) la cocina ilustrada (arte de IHMJ ART): alacena que abre y cierra; olla, fuego y humo segun la estacion
	var alacena = ui.get_node("Panel/MainContainer/StorageSection")
	var boton_alacena = ui.get_node("Panel/MainContainer/ShelfButton")
	_check("La alacena empieza cerrada (sus casillas no se ven)", not alacena.visible)
	boton_alacena.button_pressed = true
	_check("Clic en la alacena: se abre y se ven sus casillas", alacena.visible)
	boton_alacena.button_pressed = false
	_check("Otro clic: se cierra", not alacena.visible)
	var alacena2 = ui.get_node("Panel/MainContainer/StorageSectionLeft")
	var boton_alacena2 = ui.get_node("Panel/MainContainer/ShelfLeftButton")
	_check("La segunda alacena tambien empieza cerrada", not alacena2.visible)
	boton_alacena2.button_pressed = true
	_check("Clic en la segunda alacena: se abre", alacena2.visible)
	boton_alacena2.button_pressed = false
	_check("Otro clic: se cierra la segunda", not alacena2.visible)
	var vivos = func(g): return g.get_children().filter(func(c): return not c.is_queued_for_deletion()).size()
	_check("Cada alacena muestra 6 casillas (el almacenamiento tiene 12)", vivos.call(ui.storage_grid) == 6 and vivos.call(ui.storage_grid_2) == 6, "%d y %d" % [vivos.call(ui.storage_grid), vivos.call(ui.storage_grid_2)])
	var olla_estufa = ui.station_item_props["stove"]
	var fuego_estufa = ui.station_active_props["stove"]
	_check("Sin objeto en la estufa no hay olla, fuego ni humo", not olla_estufa.visible and not fuego_estufa.visible)
	var idx_estufa : int = kc.get_station_slot_index("stove")
	inv.slots[idx_estufa].item = load("res://Resources/Items/item.gd").new(load("res://Resources/Items/Data/KitchenUtils/cooking_pot.tres"))
	inv.inventory_changed.emit()
	_check("Con una olla en la estufa se ve la olla (sin fuego)", olla_estufa.visible and not fuego_estufa.visible)
	kc.get_station("stove").is_locked = true
	ui._update_stations_ui()
	_check("Mientras la estufa cocina se ven el fuego y el humo", fuego_estufa.visible)
	kc.get_station("stove").is_locked = false
	inv.slots[idx_estufa].item = null
	inv.inventory_changed.emit()
	_check("Estufa vacia y libre: vuelve a no haber olla ni fuego", not olla_estufa.visible and not fuego_estufa.visible)
	# 3) bolsa -> tabla de picar -> ingredientes
	var bolsa_idx : int = guardados[0]
	_arrastrar(inv, kc.get_station_slot_index("cutting"), bolsa_idx)
	_check("Con la bolsa en la tabla hay receta (picar)", kc.has_valid_station_craft("cutting"))
	_check("Se puede picar", kc.start_manual_station_craft("cutting"))
	var resultado = kc.get_station_item("cutting")
	_check("Picar da ingredientes y se quedan en la tabla", resultado != null and resultado.data.item_unique_name == "ingredients" and inv.slots[kc.get_simple_craft_result_index()].is_empty(), str(resultado))
	# 4) olla + ingredientes en "Combinar" -> olla con ingredientes -> estufa 45 min -> olla con la comida caliente
	var olla = _tomar_olla(kc)
	_check("La olla esta en la alacena y se puede sacar", olla != null)
	var entradas : Array = kc.get_simple_craft_input_indices()
	var res_idx : int = kc.get_simple_craft_result_index()
	inv.slots[entradas[0]].item = olla
	_arrastrar(inv, entradas[1], kc.get_station_slot_index("cutting"))
	_check("Olla vacia + ingredientes en 'Combinar' ofrecen meter los ingredientes", kc.check_simple_craft() != null and not ui.craft_button.disabled)
	var en_manos : int = pm.player.inventory.get_hands_items().size()
	ui.craft_button.pressed.emit()
	var olla_llena = inv.slots[res_idx].item
	_check("Boton Combinar: la olla con los ingredientes queda en la casilla de resultado", olla_llena != null and olla_llena.data.item_unique_name == "cooking_pot" and olla_llena.held_item != null and olla_llena.held_item.data.item_unique_name == "ingredients")
	_check("...y no salta sola a las manos", pm.player.inventory.get_hands_items().size() == en_manos)
	_check("La casilla muestra el dibujo de la olla con ingredientes", _dibujo(ui.simple_craft_result_grid, res_idx) == "cooking_pot_ingredients.png", _dibujo(ui.simple_craft_result_grid, res_idx))
	var Obj = load("res://Resources/Items/item.gd")
	var sin_dibujo := ["ingredients_bag", "ingredients_unpack", "home_meal", "KitchenUtils/cooking_pot", "KitchenUtils/water_cooking_pot", "KitchenUtils/mug", "Coffee/coffee_mug", "Coffee/coffee_bag"].filter(func(n): return load("res://Resources/Items/Data/%s.tres" % n).texture == null)
	_check("Los objetos de la cocina tienen dibujo", sin_dibujo.is_empty(), str(sin_dibujo))
	var taza = Obj.new(load("res://Resources/Items/Data/KitchenUtils/mug.tres"))
	taza.hold(Obj.new(load("res://Resources/Items/Data/Liquids/coffee.tres")))
	var olla_agua = Obj.new(load("res://Resources/Items/Data/KitchenUtils/cooking_pot.tres"))
	olla_agua.hold(Obj.new(load("res://Resources/Items/Data/Liquids/water.tres")))
	_check("La taza con cafe y la olla con agua cambian de dibujo", taza.get_display_texture().resource_path.get_file() == "coffee_mug.png" and olla_agua.get_display_texture().resource_path.get_file() == "water_pot.png")
	var casilla = _casilla(ui.simple_craft_result_grid, res_idx)
	_check("Sin nombre encima del dibujo: sale en espanol al pasar el cursor", casilla != null and not casilla.name_label.visible and casilla.tooltip_text == "Olla", casilla.tooltip_text if casilla != null else "sin casilla")
	var suelta = load("res://UI/Containers/InventorySlot.tscn").instantiate()
	root.add_child(suelta)
	suelta.set_item(Obj.new(load("res://Resources/Items/Data/Coffee/coffee_pot.tres")))
	_check("Un objeto sin dibujo (cafetera) conserva el nombre escrito", suelta.name_label.visible and suelta.tooltip_text == "Cafetera", suelta.tooltip_text)
	suelta.set_item(Obj.new(load("res://Resources/Items/Data/home_meal.tres")))
	_check("La comida casera se llama en espanol", suelta.tooltip_text == "Comida casera" and not suelta.name_label.visible, suelta.tooltip_text)
	suelta.queue_free()
	inv.slots[entradas[0]].item = Obj.new(load("res://Resources/Items/Data/KitchenUtils/cooking_pot.tres"))
	inv.slots[entradas[1]].item = Obj.new(load("res://Resources/Items/Data/ingredients_unpack.tres"))
	inv.inventory_changed.emit()
	_check("Con un resultado sin sacar, Combinar se apaga", ui.craft_button.disabled)
	ui.craft_button.pressed.emit()
	_check("...y apretarlo no gasta ingredientes ni pisa el resultado", inv.slots[res_idx].item == olla_llena and not inv.slots[entradas[0]].is_empty() and not inv.slots[entradas[1]].is_empty())
	inv.slots[entradas[0]].clear()
	inv.slots[entradas[1]].clear()
	_arrastrar(inv, idx_estufa, res_idx)
	inv.inventory_changed.emit()
	_check("La olla con ingredientes en la estufa tiene receta (cocinar)", kc.has_valid_station_craft("stove"))
	_check("Se puede cocinar", kc.start_manual_station_craft("stove"))
	_check("La estufa trabaja: se ven el fuego y el humo", kc.get_station("stove").is_locked and fuego_estufa.visible)
	# boton Esperar: avisa cuanto tiempo pasara y solo adelanta el reloj si se acepta
	var esperar = ui.station_wait_buttons["stove"]
	var aviso = ui.wait_dialog
	_check("Mientras cocina aparece 'Esperar' en la estufa", esperar.visible and not aviso.visible)
	var hora_cocina : int = tm.minutes
	esperar.pressed.emit()
	_check("'Esperar' avisa cuanto tiempo pasara (45 min) sin adelantar nada todavia", aviso.visible and aviso.dialog_text.contains("45 min") and tm.minutes == hora_cocina and kc.get_station("stove").is_locked, aviso.dialog_text)
	aviso.hide()
	_check("Si se cancela no pasa el tiempo", tm.minutes == hora_cocina and kc.get_station("stove").is_locked)
	esperar.pressed.emit()
	aviso.confirmed.emit()
	_check("Si se acepta pasan justo los 45 min, la comida queda lista y se quita 'Esperar'", (tm.minutes - hora_cocina + 1440) % 1440 == 45 and not kc.get_station("stove").is_locked and not esperar.visible and not aviso.visible, "paso %d min" % ((tm.minutes - hora_cocina + 1440) % 1440))
	var comida_olla = _tomar_olla(kc)
	var comida = comida_olla.held_item if comida_olla != null else null
	_check("A los 45 min la estufa se libera y la olla trae la comida casera", not kc.get_station("stove").is_locked and comida != null and comida.data.item_unique_name == "home_meal")
	_check("La comida esta cocinada y caliente", comida != null and comida.has_state("cooked") and comida.has_state("hot"))
	# 5) a las manos y comer desde la olla (clic derecho en la UI = use_item_at)
	var manos = pm.player.inventory
	manos.add_item(comida_olla)
	pm.add_effect(load("res://Resources/Effects/Effects/hunger.tres").duplicate())
	var energia0 : float = pm.get_stat_value("ENERGY")
	var mano_idx : int = -1
	for i in manos.get_hands_indices():
		if manos.get_slot(i).item == comida_olla:
			mano_idx = i
	_check("En la mano se ve la olla con comida", _dibujo(ui.player_hands_grid, mano_idx) == "cooking_pot_food.png", _dibujo(ui.player_hands_grid, mano_idx))
	manos.use_item_at(mano_idx)
	_check("Despues de comer la casilla pasa a la olla vacia", _dibujo(ui.player_hands_grid, mano_idx) == "cooking_pot.png", _dibujo(ui.player_hands_grid, mano_idx))
	_check("Comer: sube la energia, quita el Hambre y cuenta como comida casera", pm.get_stat_value("ENERGY") > energia0 and not pm.has_effect("HUNGER") and pm.daily.home_meals == 1, "energia %.1f -> %.1f" % [energia0, pm.get_stat_value("ENERGY")])
	_check("Comer marca la tarea COOK del tutorial", tarea.task_done)
	_check("La comida se gasta, la olla queda vacia en las manos y el ItemData compartido no se gasta", comida_olla.held_item == null and manos.get_hands_items().size() == 1 and comida.data.uses == 1, "uses del dato: %d" % comida.data.uses)	# 6) Esc cierra la UI y Mayui vuelve a moverse
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	ui._unhandled_input(esc)
	_check("Esc cierra la cocina y Mayui vuelve a moverse", not ui.visible and mov.can_move and gm.modal_count == 0)
	# 7) la cocina se puede abrir otra vez
	cocina.execute()
	_check("La cocina se puede abrir mas de una vez", ui.visible and gm.modal_count == 1)
	# lo que se deja en "Combinar" se queda ahi al salir (no salta a las manos)
	var olla_dejada = load("res://Resources/Items/item.gd").new(load("res://Resources/Items/Data/KitchenUtils/cooking_pot.tres"))
	inv.slots[entradas[0]].item = olla_dejada
	inv.inventory_changed.emit()
	var manos_antes : int = pm.player.inventory.get_hands_items().size()
	ui._unhandled_input(esc)
	_check("Al salir, lo que quedo en 'Combinar' sigue ahi y las manos no cambian", not ui.visible and inv.slots[entradas[0]].item == olla_dejada and pm.player.inventory.get_hands_items().size() == manos_antes)
	inv.slots[entradas[0]].clear()
	# 8) salir y volver: lo guardado se conserva y no se vuelve a llenar la nevera
	await _soltar(escena)
	escena = await _cargar("res://Scenes/World/Apartment.tscn", 1)
	await _esperar_calma()
	kc = escena.get_node("Kitchen").container
	inv = kc.inventory
	var quedan : int = kc.get_storage_indices().filter(func(i): return not inv.slots[i].is_empty()).size()
	_check("Al volver queda 1 bolsa (no se rellena la nevera ni se borra) y la olla sigue en las manos", quedan == 1 and pm.player.inventory.get_hands_items().size() == 1, "objetos guardados: %d" % quedan)
	# 9) la segunda comida: los usos son de cada objeto, no del dato compartido
	var olla2 = _cocinar_una(kc)
	_check("Se puede cocinar una segunda comida con la misma olla", olla2 != null and olla2.held_item != null and olla2.held_item.data.item_unique_name == "home_meal")
	manos = pm.player.inventory
	manos.add_item(olla2)
	var energia1 : float = pm.get_stat_value("ENERGY")
	for i in manos.get_hands_indices():
		if manos.get_slot(i).item == olla2:
			manos.use_item_at(i)
	_check("La segunda comida tambien se puede comer", pm.get_stat_value("ENERGY") > energia1 and pm.daily.home_meals == 2, "energia %.1f -> %.1f, comidas %d" % [energia1, pm.get_stat_value("ENERGY"), pm.daily.home_meals])
	await _esperar_calma()
	await _soltar(escena)
