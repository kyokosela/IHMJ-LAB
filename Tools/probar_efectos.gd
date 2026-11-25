extends SceneTree
## Pruebas automaticas del motor de efectos (PlayerManager) contra Docs/Design/SISTEMA_EFECTOS.md.
## Ejecuta el PlayerManager REAL con un azar controlado (FixedRng) para que cada regla sea determinista.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_efectos.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

## Sustituye al generador de azar de PlayerManager: randf() siempre devuelve `v`.
## v = 0.0 -> toda tirada "con probabilidad p > 0" tiene EXITO;  v = 0.99 -> toda tirada FALLA.
class FixedRng:
	var v : float = 0.0
	func randf() -> float:
		return v
	func randi_range(a: int, _b: int) -> int:
		return a

const STRESS := "res://Resources/Effects/Effects/stress.tres"
const CALM := "res://Resources/Effects/Effects/calm.tres"
const INSOMNIA := "res://Resources/Effects/Effects/insomnia.tres"
const HUNGER := "res://Resources/Effects/Effects/hunger.tres"
const HYPER := "res://Resources/Effects/Effects/hyperactive.tres"
const TIRED := "res://Resources/Effects/Effects/tired.tres"
const WEAK := "res://Resources/Effects/Effects/weak.tres"
const ATENTA := "res://Resources/Effects/Effects/atenta.tres"
const HIPERSOMNIA := "res://Resources/Effects/Effects/hipersomnia.tres"
const INAPETENCIA := "res://Resources/Effects/Effects/inapetencia.tres"

var pm
var tm
var att
var evm
var gm
var passed := 0
var failed := 0

func _initialize() -> void:
	pm = root.get_node("PlayerManager")
	tm = root.get_node("TimeManager")
	att = root.get_node("AttendanceManager")
	evm = root.get_node("EventManager")
	gm = root.get_node("GameManager")
	await create_timer(0.3).timeout

	_t_valores()
	_t_modificadores()
	_t_cordura()
	_t_primarios()
	_t_cierre_del_dia()
	_t_chequeos_de_la_manana()
	_t_derivados()
	_t_sueno()
	_t_energia_e_hiperactividad()
	await _t_ganchos()
	await _t_reloj_real()
	_t_semana()

	print("\n=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
func _check(nombre: String, cond: bool, detalle: String = "") -> void:
	if cond:
		passed += 1
	else:
		failed += 1
		print("  FALLA: %s %s" % [nombre, detalle])

func _near(a: float, b: float, eps: float = 0.01) -> bool:
	return absf(a - b) <= eps

## "HH:MM" -> minutos (propio: nombrar TimeUtils aqui obligaria a compilarlo antes de que existan los autoloads)
func _minutes(t: String) -> int:
	var partes : PackedStringArray = t.split(":")
	return int(partes[0]) * 60 + int(partes[1])

func _reset(rng_value: float = 0.0) -> void:
	pm.reset_engine_state(true)
	var r := FixedRng.new()
	r.v = rng_value
	pm.rng = r
	tm.julian_day = 0   # lunes
	att.arrived_today = false
	for ev in ["TIMED_HYPERACTIVE", "TIMED_ATENTA", "SLEPT_TODAY_RESET", "REMOVE_WEAK_AUTOMATICALLY"]:
		if evm.is_event_exist(ev):
			evm.remove_event(ev)

func _add(path: String, level_index: int = -1):
	var e = load(path).duplicate()
	pm.add_effect(e)
	if level_index >= 0 and "level" in e:
		e.change_level_value(level_index)
	return e

func _has(name: String) -> bool:
	return pm.has_effect(name)

func _lvl(name: String) -> int:
	var e = pm.get_effect_res(name)
	return e.level if e != null and "level" in e else -1

func _set_energy(v: float) -> void:
	pm.get_stat_res("ENERGY").value = v

# ------------------------------------------------------------------ A. valores
func _t_valores() -> void:
	print("A. Valores de tus recursos")
	_check("Energia base = 45", _near(pm.get_stat_value("ENERGY"), 45.0), str(pm.get_stat_value("ENERGY")))
	_check("Almuerzo termina 13:45", att.LUNCH_END == "13:45")
	gm.new_game()
	var smelly = evm.get_event("AUTO_SMELLY_LAPSE")
	_check("Suciedad por tiempo: 24 h", smelly != null and smelly.time_lapse_value == "24:00", str(smelly.time_lapse_value if smelly else "sin evento"))
	var hunger = evm.get_event("AUTO_HUNGER_LAPSE")
	_check("Hambre por tiempo: 6 h", hunger != null and hunger.time_lapse_value == "06:00")
	var sleepy = evm.get_event("AUTO_SLEEPY_LAPSE")
	_check("Sueno por vigilia: 16 h", sleepy != null and sleepy.time_lapse_value == "16:00")
	# se quitan para que no se disparen solos (hambre, suciedad, sueno) cuando las pruebas muevan el reloj
	for ev in ["AUTO_SMELLY_LAPSE", "AUTO_HUNGER_LAPSE", "AUTO_SLEEPY_LAPSE"]:
		evm.remove_event(ev)

# ------------------------------------------------------------------ B. modificadores de los recursos
func _t_modificadores() -> void:
	print("B. Modificadores de energia y tiempo (recursos .tres)")
	_reset(); _add(HUNGER)
	_check("Hambre: energia x1,15", _near(pm.get_cost_with_effects("ENERGY", 10.0), 11.5), str(pm.get_cost_with_effects("ENERGY", 10.0)))
	_reset(); _add(HYPER)
	_check("Hiperactividad: energia x0,90", _near(pm.get_cost_with_effects("ENERGY", 10.0), 9.0), str(pm.get_cost_with_effects("ENERGY", 10.0)))
	_reset(); _add(TIRED)
	_check("Cansancio: energia x0,25", _near(pm.get_cost_with_effects("ENERGY", 10.0), 2.5))
	_check("Cansancio: tiempo x1,5", absi(_minutes(pm.get_time_cost_with_effects("01:00")) - 90) <= 1, pm.get_time_cost_with_effects("01:00"))
	_reset(); _add(WEAK)
	_check("Debilitamiento: tiempo x2", absi(_minutes(pm.get_time_cost_with_effects("01:00")) - 120) <= 1, pm.get_time_cost_with_effects("01:00"))
	_check("Debilitamiento: energia +1 %", _near(pm.get_cost_with_effects("ENERGY", 10.0), 10.1), str(pm.get_cost_with_effects("ENERGY", 10.0)))
	_reset(); _add(ATENTA)
	_check("Atenta (III): tiempo x0,75", absi(_minutes(pm.get_time_cost_with_effects("01:00")) - 45) <= 1)
	_reset(); _add(HIPERSOMNIA)
	_check("Hipersomnia (III): tiempo x1,25", absi(_minutes(pm.get_time_cost_with_effects("01:00")) - 75) <= 1)
	_reset(); _add(ATENTA); pm._set_internal_level("ATENTA", 1)
	_check("Atenta I escala su tiempo (-10 %)", absi(_minutes(pm.get_time_cost_with_effects("01:00")) - 54) <= 1, pm.get_time_cost_with_effects("01:00"))
	for par in [["12:00", 63], ["24:00", 66], ["30:00", 69]]:
		_reset(); pm._apply_sleepy(par[0])
		_check("Sueno con %s de deuda: tiempo por nivel" % par[0], absi(_minutes(pm.get_time_cost_with_effects("01:00")) - par[1]) <= 1, pm.get_time_cost_with_effects("01:00"))
	var estres := [61, 64, 69]
	var calma := [58, 56, 54]
	for i in 3:
		_reset(); _add(STRESS, i)
		_check("Estres %d: tiempo +3/+8/+15 %%" % (i + 1), absi(_minutes(pm.get_time_cost_with_effects("01:00")) - estres[i]) <= 1, pm.get_time_cost_with_effects("01:00"))
		_reset(); _add(CALM, i)
		_check("Calma %d: tiempo -3/-6/-10 %%" % (i + 1), absi(_minutes(pm.get_time_cost_with_effects("01:00")) - calma[i]) <= 1, pm.get_time_cost_with_effects("01:00"))
	_reset(); _add(WEAK); _add(TIRED); _add(HIPERSOMNIA); pm._apply_sleepy("30:00")
	_check("Tope de tiempo: nunca mas de x3", _minutes(pm.get_time_cost_with_effects("01:00")) == 180, pm.get_time_cost_with_effects("01:00"))
	_reset(); _add(TIRED); _add(ATENTA); _add(HYPER)
	_check("Tope de energia: nunca menos de x0,25", _near(pm.get_cost_with_effects("ENERGY", 10.0), 2.5), str(pm.get_cost_with_effects("ENERGY", 10.0)))

# ------------------------------------------------------------------ C. cordura
func _t_cordura() -> void:
	print("C. Cordura: estabilizadores")
	_reset(); pm.change_sanity(-10.0)
	_check("Perdida amortiguada x0,75 (-10 -> -7,5)", _near(pm.sanity_value, 42.5), str(pm.sanity_value))
	_reset(); pm.change_sanity(-20.0)
	_check("Tope diario: -10 como maximo", _near(pm.sanity_value, 40.0), str(pm.sanity_value))
	pm.change_sanity(-5.0)
	_check("Tope diario agotado: no pierde mas", _near(pm.sanity_value, 40.0), str(pm.sanity_value))
	_reset(); pm.sanity_value = 12.0; pm.change_sanity(-8.0)
	_check("Piso de cordura = 10", _near(pm.sanity_value, 10.0), str(pm.sanity_value))
	_reset(); pm.sanity_value = 5.0; pm.change_sanity(-8.0)
	_check("Bajo el piso: no sube ni baja", _near(pm.sanity_value, 5.0), str(pm.sanity_value))
	_reset(); pm.sanity_value = 25.0; pm.change_sanity(3.0)
	_check("Rebote x2 bajo 30 (+3 -> +6)", _near(pm.sanity_value, 31.0), str(pm.sanity_value))
	_reset(); pm.sanity_value = 35.0; pm.change_sanity(3.0)
	_check("Rebote x1,5 bajo 40 (+3 -> +4,5)", _near(pm.sanity_value, 39.5), str(pm.sanity_value))
	_reset(); pm.change_sanity(3.0)
	_check("Sin rebote con cordura normal", _near(pm.sanity_value, 53.0), str(pm.sanity_value))
	_reset(); _add(CALM, 2); pm.change_sanity(-10.0)
	_check("Calma III protege 12 % de la perdida", _near(pm.sanity_value, 43.4), str(pm.sanity_value))

# ------------------------------------------------------------------ D. primarios
func _t_primarios() -> void:
	print("D. Estres y Calma")
	_reset(); _add(CALM, 0); pm.add_stress_cause()
	_check("Estres no se activa con Calma; la reduce", not _has("STRESS") and not _has("CALM"))
	_reset(); _add(STRESS, 0); pm.add_stress_cause()
	_check("Causa sobre Estres activo: +1 dia, no sube de nivel", _lvl("STRESS") == 0 and pm.get_effect_res("STRESS").days_active == 1)
	_reset(0.0); var s = _add(STRESS, 0); s.days_active = 1; pm.sanity_value = 25.0; pm._check_level_escalation(s)
	_check("Escalada I->II (1 dia, cordura <30)", _lvl("STRESS") == 1)
	_reset(0.0); s = _add(STRESS, 0); s.days_active = 1; pm.sanity_value = 35.0; pm._check_level_escalation(s)
	_check("No escala con cordura 35 (>=30)", _lvl("STRESS") == 0)
	_reset(0.99); s = _add(STRESS, 0); s.days_active = 1; pm.sanity_value = 25.0; pm._check_level_escalation(s)
	_check("No escala si falla la tirada del 50 %", _lvl("STRESS") == 0)
	_reset(0.0); s = _add(STRESS, 1); s.days_active = 2; pm.sanity_value = 15.0; pm._check_level_escalation(s)
	_check("Escalada II->III (2 dias, cordura <20) marca el nivel III", _lvl("STRESS") == 2 and pm.primary_reached_lv3["STRESS"])
	_reset(0.0); s = _add(STRESS, 1); s.days_active = 1; pm.sanity_value = 15.0; pm._check_level_escalation(s)
	_check("II->III necesita 2 dias", _lvl("STRESS") == 1)
	_reset(0.0); var c = _add(CALM, 0); c.days_active = 1; pm.sanity_value = 75.0; pm._check_level_escalation(c)
	_check("Calma I->II (rutina, cordura >70)", _lvl("CALM") == 1)
	_reset(0.0); c = _add(CALM, 0); c.days_active = 1; pm.sanity_value = 65.0; pm._check_level_escalation(c)
	_check("Calma no escala con cordura 65", _lvl("CALM") == 0)
	_reset(0.0); c = _add(CALM, 1); c.days_active = 1; pm.sanity_value = 85.0; pm._check_level_escalation(c)
	_check("Calma II->III (cordura >80)", _lvl("CALM") == 2)

	_reset(); _add(STRESS, 2); pm.primary_reached_lv3["STRESS"] = true
	_check("Mitigar 3 niveles: el tope diario deja pasar solo 2", pm.mitigate_stress(3) == 2 and _lvl("STRESS") == 0)
	_check("Segunda mitigacion el mismo dia: 0", pm.mitigate_stress(1) == 0)
	pm._close_day()   # nuevo dia
	pm.mitigate_stress(1)
	_check("Estres III mitigado por completo -> Insomnio (no Calma)", not _has("STRESS") and _has("INSOMNIA") and not _has("CALM"))
	_reset(); _add(CALM, 2); pm.primary_reached_lv3["CALM"] = true
	pm._reduce_or_remove_primary_effect(pm.get_effect_res("CALM")); pm._reduce_or_remove_primary_effect(pm.get_effect_res("CALM")); pm._reduce_or_remove_primary_effect(pm.get_effect_res("CALM"))
	_check("Calma III anulada por completo -> Estres", not _has("CALM") and _has("STRESS"))

	_reset(0.0); pm.sanity_value = 25.0; pm._roll_primary_effect_spawn()
	_check("Cordura 25: aparece Estres", _has("STRESS") and not _has("CALM"))
	_reset(0.0); pm.sanity_value = 65.0; pm._roll_primary_effect_spawn()
	_check("Cordura 65: aparece Calma", _has("CALM") and not _has("STRESS"))
	_reset(0.0); pm.sanity_value = 50.0; pm._roll_primary_effect_spawn()
	_check("Cordura 50 (neutral): no aparece nada", not _has("CALM") and not _has("STRESS"))
	_reset(0.0); _add(CALM, 0); pm.sanity_value = 25.0; pm._roll_primary_effect_spawn()
	_check("Cordura baja con Calma: la Calma baja y no aparece Estres", not _has("CALM") and not _has("STRESS"))

# ------------------------------------------------------------------ E. cierre del dia
func _t_cierre_del_dia() -> void:
	print("E. Cierre del dia y Rutina saludable")
	_reset(); pm.daily.home_meals = 1; pm.daily.bathed = true; pm.last_night_proper = true; pm._close_day()
	_check("Rutina completa: nace Calma", _has("CALM") and pm.last_routine_full)
	_check("Rutina completa: +3 de cordura", _near(pm.sanity_value, 53.0), str(pm.sanity_value))
	_check("El cierre reinicia los contadores del dia", pm.daily.home_meals == 0 and not pm.daily.bathed)
	_reset(); _add(STRESS, 1); pm.daily.home_meals = 1; pm.daily.bathed = true; pm._close_day()
	_check("Rutina con Estres: lo baja 1 nivel en vez de dar Calma", _lvl("STRESS") == 0 and not _has("CALM"))
	_reset(); pm.daily.home_meals = 1; pm.daily.bathed = true; pm.daily.gambled = true; pm.last_night_proper = false; pm._close_day()
	_check("Jugar es comodin: 3 de 4 + jugar cuenta como rutina", pm.last_routine_full)
	_reset(); pm.last_night_proper = false; pm._close_day()
	_check("Dia desordenado (<=1 de 4): causa Estres", _has("STRESS") and not pm.last_routine_full)
	_reset(); tm.julian_day = 5; pm.daily.bathed = true; pm.last_night_proper = false; pm._close_day()
	_check("Sabado con 2 de 4: +3 de cordura", _near(pm.sanity_value, 53.0), str(pm.sanity_value))
	_reset(); tm.julian_day = 6; pm.sanity_value = 40.0; pm.last_night_proper = false; pm.daily.bathed = true; pm._close_day()
	_check("Domingo: rebalanceo semanal (+25 % de lo que falta, +3 dia libre)", _near(pm.sanity_value, 45.5), str(pm.sanity_value))
	_reset(); tm.julian_day = 6; pm.sanity_value = 40.0; pm.last_night_proper = false; pm._close_day()
	_check("Domingo con 1 de 4: solo el rebalanceo (+2,5), sin el +3 del dia libre", _near(pm.sanity_value, 42.5), str(pm.sanity_value))
	_reset(); pm._apply_sleepy("30:00"); pm.last_night_proper = true; pm._close_day()
	_check("Sueno III al cierre: -8 x0,75 = -6", _near(pm.sanity_value, 44.0), str(pm.sanity_value))
	_reset(); pm._apply_sleepy("12:00"); pm.last_night_proper = true; pm._close_day()
	_check("Sueno I al cierre: -3 x0,75 = -2,25", _near(pm.sanity_value, 47.75), str(pm.sanity_value))

# ------------------------------------------------------------------ F. chequeos de la manana
func _t_chequeos_de_la_manana() -> void:
	print("F. Chequeos de la manana")
	_reset(0.0); pm.sanity_value = 25.0; pm._run_wake_checks()
	_check("Al despertar con cordura 25: Estres, Insomnio e Inapetencia", _has("STRESS") and _has("INSOMNIA") and _has("INAPETENCIA"))
	_reset(0.99); pm.sanity_value = 25.0; pm._run_wake_checks()
	_check("Con las tiradas fallando solo queda el Insomnio (cordura <30 es automatico)", not _has("STRESS") and _has("INSOMNIA") and not _has("INAPETENCIA"))
	_reset(0.0); pm.sanity_value = 50.0; pm._run_wake_checks()
	_check("Cordura neutral: no pasa nada", pm.effects.is_empty())

# ------------------------------------------------------------------ G. derivados
func _t_derivados() -> void:
	print("G. Inapetencia, Atenta, Hipersomnia y tiradas por nivel")
	_reset(0.0); pm.sanity_value = 25.0
	pm._update_inapetencia()
	_check("Inapetencia nace en nivel I", pm.get_internal_level("INAPETENCIA") == 1)
	pm._update_inapetencia()
	_check("Inapetencia II tras 1 dia", pm.get_internal_level("INAPETENCIA") == 2)
	pm._update_inapetencia()
	_check("Inapetencia II sigue 1 dia mas", pm.get_internal_level("INAPETENCIA") == 2)
	pm._update_inapetencia()
	_check("Inapetencia III tras 2 dias mas", pm.get_internal_level("INAPETENCIA") == 3)
	pm.sanity_value = 50.0
	pm._update_inapetencia()
	_check("Inapetencia se va cuando desaparece su causa", not _has("INAPETENCIA"))
	_reset(0.0)
	_add(STRESS, 2); pm._update_inapetencia()
	_check("Estres III tambien causa Inapetencia", _has("INAPETENCIA"))

	_reset(0.0); _add(INAPETENCIA); pm._set_internal_level("INAPETENCIA", 3); pm._roll_level_dependent_effects()
	_check("Inapetencia III provoca Hambre (70 %)", _has("HUNGER"))
	_reset(0.99); _add(INAPETENCIA); pm._set_internal_level("INAPETENCIA", 3); pm._roll_level_dependent_effects()
	_check("...y no la provoca si falla la tirada", not _has("HUNGER"))
	var e = pm.get_inapetencia_eating()
	_check("Comer con Inapetencia III: falla 50 %, energia x0,75", _near(e.fail_chance, 0.5) and _near(e.energy_mult, 0.75))
	pm._set_internal_level("INAPETENCIA", 2); e = pm.get_inapetencia_eating()
	_check("Comer con Inapetencia II: falla 35 %, energia x0,82", _near(e.fail_chance, 0.35) and _near(e.energy_mult, 0.82))

	_reset(0.0); pm.sanity_value = 25.0; pm._update_insomnia_days()
	_check("Cordura <30: Insomnio I (automatico)", _has("INSOMNIA") and _lvl("INSOMNIA") == 0)
	_check("Dia 1 de Insomnio: aun sin Atenta", not _has("ATENTA"))
	pm._update_insomnia_days()
	_check("Insomnio + 2 dias: Atenta, mismo nivel (I)", _has("ATENTA") and pm.get_internal_level("ATENTA") == 1)
	pm.insomnia_bad_sleep_days = 2; pm._update_insomnia_days()
	_check("Insomnio II: Atenta sube a II", _lvl("INSOMNIA") == 1 and pm.get_internal_level("ATENTA") == 2)

	_reset(0.0); _add(CALM, 2); pm._update_hipersomnia()
	_check("Calma III: aparece Hipersomnia (nivel I)", pm.get_internal_level("HIPERSOMNIA") == 1)
	pm._update_hipersomnia(); pm._update_hipersomnia(); pm._update_hipersomnia()
	_check("Hipersomnia escala a III", pm.get_internal_level("HIPERSOMNIA") == 3)
	pm.get_effect_res("CALM").change_level_value(1); pm._update_hipersomnia()
	_check("Al bajar Calma de III, Hipersomnia se va", not _has("HIPERSOMNIA"))
	_reset(0.0); _add(CALM, 2); _add(ATENTA); pm._set_internal_level("ATENTA", 1); pm._update_hipersomnia()
	_check("Atenta e Hipersomnia son opuestas: la nueva reduce a la otra", not _has("ATENTA") and not _has("HIPERSOMNIA"))
	_reset(0.0); _add(HIPERSOMNIA); pm._set_internal_level("HIPERSOMNIA", 1); pm._roll_level_dependent_effects()
	_check("Hipersomnia provoca Sueno (nace con 12 h de deuda)", _has("SLEEPY") and pm.get_sleepy_level() == 1)
	_reset(0.0); _add(ATENTA); pm._set_internal_level("ATENTA", 1); pm._roll_level_dependent_effects()
	_check("Atenta provoca Hiperactividad temporal", _has("HYPERACTIVE") and pm.hyperactive_timed)
	_reset(0.0); _add(STRESS, 0); pm._roll_level_dependent_effects()
	_check("Estres provoca Hiperactividad temporal", _has("HYPERACTIVE") and pm.hyperactive_timed)

	_reset(); _add(ATENTA); pm._set_internal_level("ATENTA", 1)
	_check("Calle con Atenta I: riesgo x0,8", _near(pm.get_street_risk_chance(0.10), 0.08))
	_reset(); _add(HIPERSOMNIA)
	_check("Calle con Hipersomnia III: riesgo x2", _near(pm.get_street_risk_chance(0.10), 0.20))
	_reset(); _add(HIPERSOMNIA)
	_check("Hipersomnia III: 10 % de Estres por accion", _near(pm.get_action_stress_chance(), 0.10))
	pm._set_internal_level("HIPERSOMNIA", 1)
	_check("Hipersomnia I: 4 % de Estres por accion", _near(pm.get_action_stress_chance(), 0.04))
	_reset(0.0); _add(ATENTA)
	var accion = load("res://Prefabs/Interactable/Task/interactable_task.gd").new()
	accion._process_action_stress_risk()
	_check("Atenta ya NO suma riesgo de Estres por accion", not _has("STRESS"))
	_add(HIPERSOMNIA); accion._process_action_stress_risk()
	_check("Hipersomnia si puede causar Estres por accion", _has("STRESS"))
	accion.free()

# ------------------------------------------------------------------ H. sueno
func _t_sueno() -> void:
	print("H. Sueno: deuda, tope y noches")
	_reset(); pm._apply_sleepy("12:00"); pm._pay_sleep_debt("08:00")
	_check("Una noche de 8 h paga solo 6 h (12 -> 6)", pm.get_effect_res("SLEEPY").time == "06:00", pm.get_effect_res("SLEEPY").time)
	pm._pay_sleep_debt("07:00")
	_check("Segunda noche: Sueno desaparece (2 noches de >=6 h)", not _has("SLEEPY"))
	_reset(); pm._apply_sleepy("12:00"); pm._pay_sleep_debt("05:00")
	_check("Una noche de 5 h no paga deuda", pm.get_effect_res("SLEEPY").time == "12:00")
	_reset(); pm._accumulate_sleep_deficit("08:00", "04:00")
	_check("Deficit de 4 h: se acumula oculto", pm.hour_debt == "04:00" and not _has("SLEEPY"))
	pm._accumulate_sleep_deficit("08:00", "04:00")
	_check("Deficit de 8 h (>=6): aparece Sueno con esa deuda", _has("SLEEPY") and pm.get_effect_res("SLEEPY").time == "08:00" and pm.hour_debt == "00:00")
	_reset(); pm._apply_sleepy("34:00"); pm._accumulate_sleep_deficit("10:00", "04:00")
	_check("Tope de deuda de sueno: 36 h", pm.get_effect_res("SLEEPY").time == "36:00", pm.get_effect_res("SLEEPY").time)
	_reset(); _add(STRESS, 0); pm.insomnia_bad_sleep_days = 0
	pm._finish_sleep("05:00", "08:00", pm.BED_TYPE.TYPE_C, false, false, 10.0)
	_check("Dormir menos del minimo: Insomnio", _has("INSOMNIA"))
	_check("Noche mala: no baja el Estres", _lvl("STRESS") == 0 and _has("STRESS"))
	_check("Noche mala: last_night_proper = false", not pm.last_night_proper)
	_check("Despues de dormir: bloqueado para volver a dormir", pm.slept_today)
	_check("...pero se puede volver a dormir 12 h despues (evento creado)", evm.is_event_exist("SLEPT_TODAY_RESET"))
	pm._allow_sleep_again()
	_check("Tras el evento: se puede dormir otra vez", not pm.slept_today)
	_reset(); _add(STRESS, 2)
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_C, true, true, 30.0)
	_check("Noche apropiada tras jornada laboral: -1 nivel (III -> II)", _lvl("STRESS") == 1)
	_reset(); _add(STRESS, 0)
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_C, true, true, 30.0)
	_check("Piso: tras jornada laboral el Estres I no se quita durmiendo", _has("STRESS"))
	_reset(); _add(STRESS, 0)
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_C, true, false, 30.0)
	_check("Dia libre: dormir bien SI quita el Estres I", not _has("STRESS"))
	_reset(0.0); _add(STRESS, 2)
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_A, true, false, 30.0)
	_check("Cama A (75 %): -2 niveles esa noche (III -> I)", _lvl("STRESS") == 0)
	_reset(0.99); _add(STRESS, 2)
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_A, true, false, 30.0)
	_check("Cama A sin suerte: solo -1", _lvl("STRESS") == 1)
	_reset(); _add(STRESS, 0); pm.proper_nights_in_row = 1
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_C, true, false, 30.0)
	_check("2 noches apropiadas seguidas lo anulan", not _has("STRESS") and pm.proper_nights_in_row == 2)
	_reset(); _add(INSOMNIA, 0)
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_C, true, false, 30.0)
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_C, true, false, 30.0)
	_check("Insomnio: 2 noches apropiadas seguidas lo anulan", not _has("INSOMNIA"))
	# La marca de 16 h de vigilia NO cuenta mientras se duerme (lo encontro la prueba de la cama real)
	_reset()
	tm.minutes = 8 * 60                  # el reloj se pone ANTES de crear el contador: ese salto no es vigilia
	evm.create_lapse_event("16:00", pm.apply_vigil_sleepy, "AUTO_SLEEPY_LAPSE", "SLEEPY_TIMER", true)
	tm.add_to_current_time("14:00")      # 22:00, despierta
	pm._sleeping = true
	tm.add_to_current_time("10:00")      # duerme y cruza la marca de 16 h a media noche
	_check("Dormir cruzando la marca de 16 h de vigilia NO da Sueno", not _has("SLEEPY"))
	pm._finish_sleep("10:00", "10:00", pm.BED_TYPE.TYPE_C, true, false, 40.0)
	tm.add_to_current_time("10:00")      # 10 h despierta desde que desperto
	_check("Al despertar la cuenta de vigilia empieza de nuevo", not _has("SLEEPY"))
	tm.add_to_current_time("07:00")      # 17 h despierta
	_check("Despierta mas de 16 h: Sueno con 12 h de deuda", _has("SLEEPY") and pm.get_effect_res("SLEEPY").time == "12:00", str(pm.get_effect_res("SLEEPY").time if _has("SLEEPY") else "sin Sueno"))
	if evm.is_event_exist("AUTO_SLEEPY_LAPSE"):
		evm.remove_event("AUTO_SLEEPY_LAPSE")

# ------------------------------------------------------------------ I. energia e hiperactividad
func _t_energia_e_hiperactividad() -> void:
	print("I. Energia, hiperactividad y debilitamiento")
	_reset(); _set_energy(95.0)
	_check("Energia 95: Hiperactividad", _has("HYPERACTIVE"))
	for i in 4:
		pm.decrease_stat("ENERGY", 1.0)
	_check("BUG corregido: gastar energia estando hiperactiva NO da Insomnio", not _has("INSOMNIA"))
	pm.apply_timed_hyperactive("COFFEE")
	_check("Cafe con Hiperactividad ya activa: Insomnio", _has("INSOMNIA"))
	_reset(); _set_energy(50.0); pm.apply_timed_hyperactive("COFFEE")
	_check("Cafe: Hiperactividad temporal", _has("HYPERACTIVE") and pm.hyperactive_timed and not _has("INSOMNIA"))
	pm.decrease_stat("ENERGY", 1.0)
	_check("Un cambio de energia no quita la Hiperactividad temporal", _has("HYPERACTIVE"))
	pm._end_timed_hyperactive()
	_check("Al vencer el cafe se va (energia <90)", not _has("HYPERACTIVE"))

	_reset(0.0); _set_energy(10.0)
	_check("Energia 10: Cansancio", _has("TIRED"))
	pm._run_wake_checks()
	_check("Agotada: 30 % diario de caer en Debilitamiento", _has("WEAK"))
	_check("Debilitamiento: -5 de cordura (x0,75)", _near(pm.sanity_value, 46.25), str(pm.sanity_value))
	_reset(0.0); _set_energy(10.0)
	for i in 3:
		pm.decrease_stat("ENERGY", 0.5)
	_check("Agotada: 3 acciones aun no", not _has("WEAK"))
	pm.decrease_stat("ENERGY", 0.5)
	_check("Agotada: la 4.a accion (50 %) causa Debilitamiento", _has("WEAK"))
	_reset(0.99); _set_energy(10.0)
	for i in 4:
		pm.decrease_stat("ENERGY", 0.5)
	_check("...y no si falla la tirada", not _has("WEAK"))

# ------------------------------------------------------------------ J. ganchos
func _t_ganchos() -> void:
	print("J. Ganchos de habitos")
	_reset(0.0); _add(STRESS, 1); pm.register_meal("HOME", true)
	_check("Comida casera caliente: cuenta y baja 1 nivel de Estres", pm.daily.home_meals == 1 and _lvl("STRESS") == 0)
	_reset(0.0); pm.register_meal("INSTANT")
	_check("Comida instantanea (50 %): causa Estres", pm.daily.instant_meals == 1 and _has("STRESS"))
	_reset(0.99); pm.register_meal("INSTANT")
	_check("...y no siempre", not _has("STRESS"))
	_reset(0.0); _add(STRESS, 1); pm.register_bath(false)
	_check("Bano con agua caliente: -1 nivel de Estres", pm.daily.bathed and _lvl("STRESS") == 0)
	_reset(0.0); pm.register_bath(true)
	_check("Bano con agua fria (tutorial): puede causar Estres", pm.daily.bathed and _has("STRESS"))
	_check("Agua fria: Atenta I por 1 h", _has("ATENTA") and pm.get_internal_level("ATENTA") == 1 and pm.atenta_from_cold_water and evm.is_event_exist("TIMED_ATENTA"))
	tm.add_to_current_time("00:50")
	_check("...sigue antes de cumplirse la hora", _has("ATENTA"))
	tm.add_to_current_time("00:20")
	_check("...y se va pasada 1 h", not _has("ATENTA") and not pm.atenta_from_cold_water)
	_reset(0.99); _add(ATENTA); pm._set_internal_level("ATENTA", 2); pm.register_bath(true)
	_check("Agua fria con Atenta ya activa (Insomnio): no la cambia ni la quita despues", pm.get_internal_level("ATENTA") == 2 and not pm.atenta_from_cold_water)
	_reset(0.99); _add(HIPERSOMNIA); pm._set_internal_level("HIPERSOMNIA", 2); pm.register_bath(true)
	_check("Agua fria con Hipersomnia (opuesta): la reduce 1 nivel y no da Atenta", pm.get_internal_level("HIPERSOMNIA") == 1 and not _has("ATENTA"))
	_reset(0.99); pm.register_bath(true); _add(INSOMNIA, 0); pm.insomnia_days_active = 2
	tm.add_to_current_time("01:10")
	_check("Atenta de agua fria + Insomnio de 2 dias: se queda permanente", _has("ATENTA"))
	_reset(0.99)
	_reset(); _add(STRESS, 1); pm.register_gamble(true)
	_check("Apostar y ganar: anula el Estres", not _has("STRESS") and pm.daily.gambled)
	_reset(); _add(CALM, 1); pm.register_gamble(false)
	_check("Apostar y perder: anula la Calma y causa Estres", not _has("CALM") and _has("STRESS"))
	_reset(); _add(CALM, 0); pm.register_street_event()
	_check("Sorpresa en la calle: -3,75 de cordura, anula Calma, causa Estres", _near(pm.sanity_value, 46.25) and not _has("CALM") and _has("STRESS"), str(pm.sanity_value))
	_reset(); _add(HIPERSOMNIA); pm._set_internal_level("HIPERSOMNIA", 2); pm.coffee_relieves_hipersomnia()
	_check("Cafe: Hipersomnia baja 1 nivel", pm.get_internal_level("HIPERSOMNIA") == 1)
	pm.coffee_relieves_hipersomnia()
	_check("...solo una vez al dia", pm.get_internal_level("HIPERSOMNIA") == 1)
	_reset(); _add(CALM, 1); _add(STRESS, 0)
	_check("Reporte de depuracion se genera", pm.get_debug_report().contains("CORDURA"))
	# el panel de depuracion REAL muestra el reporte del motor
	var panel = load("res://UI/Debug/debug_panel.tscn").instantiate()
	root.add_child(panel)
	await process_frame
	panel.game_info_update(0.1)
	_check("Panel de depuracion: el motor muestra CORDURA y los efectos activos", panel.engine_info.text.contains("CORDURA") and panel.engine_info.text.contains("EFECTOS"))
	var n_lista : int = panel.get_node("%EffectsList").get_child_count()
	_check("Panel de depuracion: lista los efectos que ya estaban activos al abrirlo", n_lista >= 1 and n_lista == pm.effects.size(), "lista %d / activos %d" % [n_lista, pm.effects.size()])
	panel.queue_free()
	# F3 en el juego: crea el panel la primera vez, despues lo alterna
	gm.toggle_debug_panel()
	await process_frame
	var abierto : bool = gm._debug_panel != null and gm._debug_panel.visible
	gm.toggle_debug_panel()
	var cerrado : bool = not gm._debug_panel.visible
	gm.toggle_debug_panel()
	_check("F3: abre, cierra y vuelve a abrir el panel", abierto and cerrado and gm._debug_panel.visible)
	gm._debug_panel.queue_free()

# ------------------------------------------------------------------ L. una semana completa con el reloj real
## Juega 7 dias con el reloj, el cambio de dia y las noches reales (sin transiciones). El azar es real
## (con semilla): se comprueba la DIRECCION de la cordura y los efectos esperados, no cifras exactas.
func _semana(perfil: String) -> Dictionary:
	_reset()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261121
	pm.rng = rng
	tm.julian_day = 0
	tm.minutes = 6 * 60          # lunes 06:00
	var visto := {"CALM": false, "STRESS": false, "INSOMNIA": false, "SLEEPY": false}
	for dia in 7:
		if perfil == "modelo":
			pm.register_bath(false)
			pm.register_meal("HOME", true)
			pm.register_meal("HOME", true)
			tm.add_to_current_time("16:00")                    # 22:00
			_noche("08:00", "08:00")                           # duerme lo necesario, cruza la medianoche
		else:
			tm.add_to_current_time("17:00")                    # 23:00, sin banarse ni comer
			tm.add_to_current_time("04:00")                    # 03:00: cruza la medianoche DESPIERTA
			_noche("04:00", "08:00")                           # duerme 4 h en vez de 8
		for e in visto:
			if pm.has_effect(e):
				visto[e] = true
		pm.sanity_value = pm.sanity_value   # (sin efecto: fuerza una lectura limpia)
	visto["cordura"] = pm.sanity_value
	return visto

## Una noche: avanza el reloj y aplica los efectos del sueno, como hace sleep() sin las transiciones.
func _noche(horas: String, minimo: String) -> void:
	var propia : bool = _minutes(horas) >= _minutes(minimo)
	pm._sleeping = true
	tm.add_to_current_time(horas)
	pm._finish_sleep(horas, minimo, pm.BED_TYPE.TYPE_C, propia, false, pm._get_base_energy_for_hours(horas))

func _t_semana() -> void:
	print("L. Una semana completa con el reloj real")
	var modelo : Dictionary = _semana("modelo")
	_check("Semana modelo: la cordura sube (>= 60)", modelo.cordura >= 60.0, "cordura final %.1f" % modelo.cordura)
	_check("Semana modelo: aparece Calma", modelo.CALM)
	_check("Semana modelo: sin Insomnio", not modelo.INSOMNIA)
	var caos : Dictionary = _semana("caotico")
	_check("Semana caotica: la cordura cae (<= 40)", caos.cordura <= 40.0, "cordura final %.1f" % caos.cordura)
	_check("Semana caotica: aparecen Estres, Insomnio y Sueno", caos.STRESS and caos.INSOMNIA and caos.SLEEPY)
	_check("El caotico termina claramente por debajo del modelo", modelo.cordura - caos.cordura >= 25.0, "modelo %.1f / caotico %.1f" % [modelo.cordura, caos.cordura])
	print("   (modelo: cordura %.1f | caotico: cordura %.1f)" % [modelo.cordura, caos.cordura])

# ------------------------------------------------------------------ K. reloj real
func _t_reloj_real() -> void:
	print("K. Reloj real: cruzar la medianoche")
	# El dia que termina es DOMINGO: dentro de day_changed, tm.week_day aun es el dia que termina.
	_reset(0.99)
	tm.julian_day = 6
	tm.minutes = 23 * 60 + 50
	pm.sanity_value = 40.0
	pm.last_night_proper = true
	tm.add_to_current_time("00:20")
	_check("Medianoche con Mayui despierta: se cierra el DOMINGO (+3 dia libre, +25 % rebalanceo)", _near(pm.sanity_value, 45.5), str(pm.sanity_value))
	_check("El cierre reinicio los contadores", pm.daily.home_meals == 0)

	_reset(0.0)
	tm.julian_day = 1
	tm.minutes = 23 * 60 + 50
	pm.sanity_value = 25.0
	pm._sleeping = true
	tm.add_to_current_time("00:20")
	_check("Cruzando la medianoche DURMIENDO: los chequeos de la manana esperan", pm._wake_checks_pending and not _has("STRESS"))
	pm._finish_sleep("08:00", "08:00", pm.BED_TYPE.TYPE_C, true, false, 30.0)
	_check("Al terminar de dormir se corren los chequeos pendientes (Estres por cordura baja)", not pm._wake_checks_pending and _has("STRESS") and not pm._sleeping)

	_reset(0.0)
	tm.julian_day = 1
	tm.minutes = 23 * 60 + 50
	pm.sanity_value = 25.0
	tm.add_to_current_time("00:20")
	_check("Cruzando la medianoche DESPIERTA: los chequeos corren al momento", _has("STRESS"))
