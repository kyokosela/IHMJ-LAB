extends SceneTree
## Pruebas de la paga semanal (D7: viernes 17:00, una sola vez) con el reloj, los eventos de la agenda y la asistencia REALES.
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_paga.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

const INICIAL := 350   ## EconomyManager.STARTING_MONEY
const DIA := 200       ## EconomyManager.DAILY_SALARY

var tm
var gm
var att
var eco
var pagos : Array[int] = []   ## cada pago que anuncia la economia
var passed := 0
var failed := 0

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	create_timer(120.0).timeout.connect(func(): print("  FALLA: la prueba se colgo (120 s)"); quit(2))
	tm = root.get_node("TimeManager")
	gm = root.get_node("GameManager")
	att = root.get_node("AttendanceManager")
	eco = root.get_node("EconomyManager")
	await create_timer(0.3).timeout
	gm.new_game()   # carga la agenda real (paga, jornada laboral, renta...)
	eco.salary_paid.connect(func(neto: int, _detalle: Dictionary) -> void: pagos.append(neto))

	await _t_semana_completa()
	await _t_falta_el_viernes()
	await _t_sin_marcar_salida()
	await _t_reloj_salta_las_17()
	await _t_descuentos()

	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
func _minutos(hora: String) -> int:
	var partes : PackedStringArray = hora.split(":")
	return int(partes[0]) * 60 + int(partes[1])

## Lunes 06:00 con la economia y la asistencia como en una partida nueva.
func _semana_nueva() -> void:
	tm.julian_day = 0
	tm.day = 1
	tm.minutes = 6 * 60
	eco.load_save_data({})
	att.load_save_data({})
	await process_frame
	pagos.clear()

## Avanza el reloj hasta `hora` de hoy (dispara lo agendado en el camino).
func _a_las(hora: String) -> void:
	tm.minutes = _minutos(hora)
	await process_frame

## Avanza hasta `hora` del dia siguiente (cruza la medianoche).
func _manana_a_las(hora: String) -> void:
	tm.add_to_current_time(tm.format_minutes(1440 - tm.minutes + _minutos(hora)))
	await process_frame

## Un dia de trabajo: entra a `entrada` y marca la salida a `salida`.
func _trabajar(entrada: String = "08:00", salida: String = "17:05") -> void:
	await _a_las(entrada)
	att.clock_in()
	await _a_las(salida)
	att.clock_out()
	await process_frame

## De lunes 06:00 a viernes 06:00 trabajando los cuatro dias.
func _lunes_a_jueves() -> void:
	for i in 4:
		await _trabajar()
		await _manana_a_las("06:00")

# ------------------------------------------------------------------ A. semana completa
func _t_semana_completa() -> void:
	print("A. Semana completa de trabajo")
	await _semana_nueva()
	await _lunes_a_jueves()
	await _a_las("08:00")
	att.clock_in()
	await _a_las("16:59")
	_check("El viernes antes de las 17:00 todavia no se paga", pagos.is_empty() and eco.money == INICIAL, "pagos %s, S/%d" % [str(pagos), eco.money])
	await _a_las("17:05")
	att.clock_out()
	await process_frame
	_check("5 dias trabajados: la paga del viernes es S/1000", eco.money == INICIAL + 5 * DIA, "S/%d (esperado %d)" % [eco.money, INICIAL + 5 * DIA])
	_check("...en un solo pago", pagos == [5 * DIA], str(pagos))
	await _manana_a_las("06:00")   # sabado
	await _manana_a_las("06:00")   # domingo
	await _manana_a_las("06:00")   # lunes: cambia la semana
	_check("Al cambiar de semana no se vuelve a pagar", pagos == [5 * DIA] and eco.money == INICIAL + 5 * DIA, "pagos %s, S/%d" % [str(pagos), eco.money])
	# segunda semana, sin ir el viernes: la paga cae igual, a las 17:00 en punto
	pagos.clear()
	var antes : int = eco.money
	await _lunes_a_jueves()
	await _a_las("17:00")
	_check("Segunda semana: la paga del viernes vuelve a caer a las 17:00", pagos == [4 * DIA] and eco.money == antes + 4 * DIA, "pagos %s, S/%d" % [str(pagos), eco.money])

# ------------------------------------------------------------------ B. no fue el viernes
func _t_falta_el_viernes() -> void:
	print("B. Falta el viernes")
	await _semana_nueva()
	await _lunes_a_jueves()
	await _a_las("16:59")
	_check("Antes de las 17:00 no se paga", pagos.is_empty(), str(pagos))
	await _a_las("17:00")
	_check("A las 17:00 se pagan los 4 dias (S/800)", pagos == [4 * DIA] and eco.money == INICIAL + 4 * DIA, "pagos %s, S/%d" % [str(pagos), eco.money])

# ------------------------------------------------------------------ C. no marco la salida
func _t_sin_marcar_salida() -> void:
	print("C. El viernes no marca la salida")
	await _semana_nueva()
	await _lunes_a_jueves()
	await _a_las("08:00")
	att.clock_in()
	await _a_las("19:00")
	_check("Sigue fichada: la paga espera a que marque la salida", pagos.is_empty(), str(pagos))
	await _manana_a_las("06:00")
	_check("Si nunca la marca, al acabar el viernes cobra los dias completos (S/800)", pagos == [4 * DIA] and eco.money == INICIAL + 4 * DIA, "pagos %s, S/%d" % [str(pagos), eco.money])

# ------------------------------------------------------------------ D. el reloj pasa de largo (dormir)
func _t_reloj_salta_las_17() -> void:
	print("D. Duerme y se salta las 17:00 del viernes")
	await _semana_nueva()
	await _lunes_a_jueves()
	await _a_las("15:00")
	await _manana_a_las("01:00")
	_check("La paga no se pierde: llega al cambiar de dia", pagos == [4 * DIA] and eco.money == INICIAL + 4 * DIA, "pagos %s, S/%d" % [str(pagos), eco.money])

# ------------------------------------------------------------------ E. descuentos
func _t_descuentos() -> void:
	print("E. Descuentos de la semana")
	await _semana_nueva()
	await _trabajar("08:30")   # lunes tarde: -20
	await _manana_a_las("06:00")
	for i in 4:
		await _trabajar()
		if i < 3:
			await _manana_a_las("06:00")
	_check("Una tardanza descuenta S/20 (S/980)", pagos == [5 * DIA - 20], str(pagos))
	await _semana_nueva()
	await _trabajar()
	await _manana_a_las("06:00")
	await _trabajar()
	await _manana_a_las("06:00")   # miercoles y jueves sin ir: faltas 1 y 2
	await _manana_a_las("06:00")
	await _manana_a_las("06:00")
	await _a_las("17:00")          # viernes sin ir: 3.a falta a las 17:00, con recorte de S/100
	_check("La 3.a falta, anotada el viernes a las 17:00, entra en esa paga (400 - 100)", pagos == [2 * DIA - 100], str(pagos))
