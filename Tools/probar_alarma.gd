extends SceneTree
## Pruebas del despertador de la cama: la pantalla de la alarma REAL y el PlayerManager REAL (SISTEMA_GAMEPLAY §5.4, D1 y P13).
## Uso (desde la carpeta del proyecto; tarda ~20 s):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_alarma.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

const INNER := "Center/Panel/VBox/Margin/Inner"

## Azar controlado: randf() siempre devuelve `v`; randi_range() el minimo, o el maximo con `usa_maximo`.
class FixedRng:
	var v : float = 0.99
	var usa_maximo : bool = false
	func randf() -> float:
		return v
	func randi_range(a: int, b: int) -> int:
		return b if usa_maximo else a

var pm
var tm
var gm
var evm
var passed := 0
var failed := 0

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	create_timer(120.0, true, false, true).timeout.connect(func(): print("  FALLA: la prueba se colgo (120 s)"); quit(2))
	pm = root.get_node("PlayerManager")
	tm = root.get_node("TimeManager")
	gm = root.get_node("GameManager")
	evm = root.get_node("EventManager")
	await create_timer(0.3).timeout
	Engine.time_scale = 30.0   # los fundidos de dormir duran 3 + 3 s

	print("A. Partida nueva")
	gm.new_game()
	_check("Todo jugador empieza con despertador (P13)", pm._can_use_alarm_override())
	_quitar_eventos()   # que los eventos del dia no se crucen con el reloj de la prueba

	await _t_pantalla()
	await _t_hora_elegida()
	await _t_horas_de_mas()
	await _t_insomnio()

	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
func _quitar_eventos() -> void:
	for event in evm.events.duplicate():
		evm.remove_event(event.event_unique_name)
	tm.scheduled_times.clear()
	# _finish_sleep reinicia este contador al despertar: uno vacio que no se cumple durante la prueba
	evm.create_lapse_event("99:00", func() -> void: pass, "AUTO_SLEEPY_LAPSE", "SLEEPY_TIMER", true)

func _minutos(hora: String) -> int:
	var partes : PackedStringArray = hora.split(":")
	return int(partes[0]) * 60 + int(partes[1])

func _preparar(hora: String, azar: float = 0.99, usa_maximo: bool = false) -> void:
	if evm.is_event_exist("SLEPT_TODAY_RESET"):
		evm.remove_event("SLEPT_TODAY_RESET")
	pm.reset_engine_state(true)   # sin efectos, energia 45 (minimo 8 h) y puede dormir
	var r := FixedRng.new()
	r.v = azar
	r.usa_maximo = usa_maximo
	pm.rng = r
	tm.minutes = _minutos(hora)

func _buscar_alarma() -> Node:
	for capa in root.get_children():
		var ui : Node = capa.get_node_or_null("AlarmUI")
		if ui != null and not ui.is_queued_for_deletion():
			return ui
	return null

## Abre la pantalla de la alarma por el mismo camino que la cama.
func _abrir(cama: int = 0) -> Node:
	pm.request_sleep(cama)
	await process_frame
	return _buscar_alarma()

func _hora_en_pantalla(ui: Node) -> String:
	return ui.get_node(INNER + "/AlarmSection/HourRow/HourLabel").text

func _pulsar(ui: Node, ruta: String) -> void:
	ui.get_node(INNER + ruta).pressed.emit()

## Pulsa "-" hasta que la pantalla marque `hora`.
func _poner_hora(ui: Node, hora: String) -> void:
	for i in 30:
		if _hora_en_pantalla(ui) == hora:
			return
		_pulsar(ui, "/AlarmSection/HourRow/MinusButton")

func _esperar_sueno() -> void:
	while pm._sleep_in_progress:
		await process_frame

## Acostarse a las `ahora`, dejar la alarma en `alarma` ("" = no tocarla) y pulsar el boton. Devuelve la hora al despertar.
func _acostarse(ahora: String, alarma: String, boton: String = "ConfirmButton", azar: float = 0.99, usa_maximo: bool = false) -> String:
	_preparar(ahora, azar, usa_maximo)
	return await _acostarse_ya(alarma, boton)

func _acostarse_ya(alarma: String, boton: String = "ConfirmButton") -> String:
	var ui : Node = await _abrir()
	if ui == null:
		_check("La pantalla de la alarma se abre", false)
		return ""
	if alarma != "":
		_poner_hora(ui, alarma)
		_check("La pantalla deja elegir las %s" % alarma, _hora_en_pantalla(ui) == alarma, _hora_en_pantalla(ui))
	_pulsar(ui, "/Buttons/" + boton)
	await _esperar_sueno()
	return tm.get_current_time()

# ------------------------------------------------------------------ B. la pantalla
func _t_pantalla() -> void:
	print("B. La pantalla de la alarma")
	# [hora actual, cama, hora propuesta]: la primera hora en punto en la que ya habra dormido su minimo
	var casos := [["22:00", 0, "06:00"], ["22:40", 0, "07:00"], ["08:00", 0, "16:00"], ["22:00", 2, "05:00"]]
	for caso in casos:
		_preparar(caso[0])
		var ui : Node = await _abrir(caso[1])
		_check("A las %s (cama %d) propone las %s" % caso, _hora_en_pantalla(ui) == caso[2], _hora_en_pantalla(ui))
		_pulsar(ui, "/Buttons/CancelButton")
		await _esperar_sueno()
	_preparar("15:00")
	var ui2 : Node = await _abrir()
	_poner_hora(ui2, "00:00")
	_pulsar(ui2, "/AlarmSection/HourRow/MinusButton")
	_check("Bajar desde las 00:00 da las 23:00", _hora_en_pantalla(ui2) == "23:00", _hora_en_pantalla(ui2))
	_pulsar(ui2, "/AlarmSection/HourRow/PlusButton")
	_check("Subir desde las 23:00 da las 00:00", _hora_en_pantalla(ui2) == "00:00", _hora_en_pantalla(ui2))
	_pulsar(ui2, "/Buttons/CancelButton")
	await _esperar_sueno()

# ------------------------------------------------------------------ C. la hora elegida manda
func _t_hora_elegida() -> void:
	print("C. Despierta a la hora elegida")
	var hora : String = await _acostarse("22:00", "05:00")
	_check("A las 22:00, alarma a las 05:00: despierta a las 05:00", hora == "05:00", hora)
	_check("...durmio menos de lo que necesita: noche mala e Insomnio", not pm.last_night_proper and pm.has_effect("INSOMNIA"))
	hora = await _acostarse("18:00", "00:00")
	_check("Alarma a las 00:00 (no es lo mismo que sin alarma): despierta a las 00:00", hora == "00:00", hora)
	hora = await _acostarse("22:00", "", "NoAlarmButton")
	_check("Sin alarma: duerme su minimo (8 h) y despierta a las 06:00", hora == "06:00", hora)
	_check("...noche apropiada y sin Insomnio", pm.last_night_proper and not pm.has_effect("INSOMNIA"))
	hora = await _acostarse("22:00", "")
	_check("Con la hora propuesta: despierta a las 06:00, noche apropiada", hora == "06:00" and pm.last_night_proper, hora)

# ------------------------------------------------------------------ D. pedir mas horas
func _t_horas_de_mas() -> void:
	print("D. Alarma mas tarde de lo necesario")
	_preparar("22:00")
	pm._apply_sleepy("30:00")
	var hora : String = await _acostarse_ya("09:00")
	_check("Noche apropiada", pm.last_night_proper, hora)
	var deuda : String = pm.get_effect_res("SLEEPY").time if pm.has_effect("SLEEPY") else "sin Sueno"
	_check("La noche paga 6 h de deuda de sueno y ni una mas (30 -> 24)", deuda == "24:00", deuda)

# ------------------------------------------------------------------ E. insomnio (D1)
func _t_insomnio() -> void:
	print("E. Con Insomnio el despertador puede fallar")
	_preparar("22:00", 0.0, true)   # la tirada del despertador acierta; el Insomnio deja dormir como maximo 7 h
	pm.add_effect(pm.EFFECT_INSOMNIA.duplicate())
	var hora : String = await _acostarse_ya("03:00")
	_check("Si funciona: despierta a la hora elegida (03:00)", hora == "03:00", hora)
	_preparar("22:00", 0.99, true)  # la tirada falla
	pm.add_effect(pm.EFFECT_INSOMNIA.duplicate())
	hora = await _acostarse_ya("03:00")
	_check("Si falla: ignora la alarma y duerme lo que le deja el Insomnio (7 h)", hora == "05:00", hora)
