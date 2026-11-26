extends Node

signal effect_added(effect : Effect)
signal effect_removed(effect : Effect)

signal stat_connection_added
signal sanity_changed(_new_value : float, old_value : float)

@warning_ignore_start("unused_signal")
signal stat_value_changed(stat : Stat, new_value : float)
signal stat_decrease(stat : Stat, lost_amount : float)
signal stat_increase(stat : Stat, gain_amount : float)

enum CONNECTION_PARAM {
	SIGNAL,
	CALLABLE,
	FLAGS
}

var player : Player
var energy_effects : Dictionary[String, Effect] = {}

const STATS_FOLDER_PATH : String = "res://Resources/Stats/stats/"

var stats : Array[Stat]
var effects : Array[Effect]
var sanity_value : float = 50.0 :
	set(_value) :
		var prev_san : float = sanity_value
		sanity_value = clamp(_value, 0, 100)
		sanity_changed.emit(sanity_value, prev_san)

var money: int:
	get:
		push_warning("PlayerManager.money is deprecated. Use EconomyManager.money instead.")
		return EconomyManager.money
	set(value):
		push_warning("PlayerManager.money is deprecated. Use EconomyManager.money instead.")
		EconomyManager.money = value

enum SANITY_STATES {
	DOCILE,
	NEUTRAL,
	DISTURBED
}

#region LOGIC

## Preload primary effect resources
const EFFECT_STRESS := preload("res://Resources/Effects/Effects/stress.tres")
const EFFECT_CALM := preload("res://Resources/Effects/Effects/calm.tres")
const EFFECT_INSOMNIA := preload("res://Resources/Effects/Effects/insomnia.tres")
const EFFECT_INAPETENCIA := preload("res://Resources/Effects/Effects/inapetencia.tres")
const EFFECT_HYPERSOMNIA := preload("res://Resources/Effects/Effects/hipersomnia.tres")
const EFFECT_ATENTA := preload("res://Resources/Effects/Effects/atenta.tres")

const SANITY_STRESS_T1_MAX : float = 40.0
const SANITY_STRESS_T2_MAX : float = 30.0
const SANITY_STRESS_T3_MAX : float = 20.0
const SANITY_CALM_T1_MIN : float = 60.0
const SANITY_CALM_T2_MIN : float = 70.0
const SANITY_CALM_T3_MIN : float = 80.0

const PRIMARY_SPAWN_LOW_CHANCE : float = 0.25
const PRIMARY_SPAWN_HIGH_CHANCE : float = 0.50

const LV3_STRESS_SECONDARY_SPAWN_CHANCE : float = 0.50
const LV3_CALM_SECONDARY_SPAWN_CHANCE : float = 0.50

const STREET_RISK_ATENTA_MULTIPLIER : float = 0.5
const STREET_RISK_HYPERSOMNIA_MULTIPLIER : float = 2.0

const INSOMNIA_TRIGGER_SANITY_MAX : float = 30.0
const INSOMNIA_LEVEL3_SANITY_MAX : float = 15.0
const INSOMNIA_LEVEL2_MIN_BAD_SLEEP_DAYS : int = 2
const INSOMNIA_LEVEL1_SLEEP_MIN_HOURS : int = 4
const INSOMNIA_LEVEL1_SLEEP_MAX_HOURS : int = 7
const INSOMNIA_LEVEL2_SLEEP_MIN_HOURS : int = 2
const INSOMNIA_LEVEL2_SLEEP_MAX_HOURS : int = 6
const INSOMNIA_LEVEL3_SLEEP_MIN_HOURS : int = 0
const INSOMNIA_LEVEL3_SLEEP_MAX_HOURS : int = 3
const INSOMNIA_RECOVERY_REQUIRED_PROPER_SLEEPS : int = 2
const SLEEP_STRESS_BASE_REDUCTION_PERCENT : float = 8.0
const SLEEP_STRESS_BED_A_BONUS_PERCENT : float = 6.0
const SLEEP_STRESS_BED_B_BONUS_PERCENT : float = 2.0
const SLEEP_ALARM_OVERRIDE_FLAG : String = "sleep_alarm_hours_override"
const SLEEP_ALARM_ACCESS_FLAGS : Array[String] = ["has_alarm_clock", "has_alarm_phone"]

## INSOMNIA trigger constants (from design doc)
const INSOMNIA_COFFEE_ENERGY_THRESHOLD : float = 90.0
const INSOMNIA_HYPERACTIVE_HEALTH_PENALTY : float = 5.0
const SLEEPY_LEVEL3_FOR_INSOMNIA : int = 2  # 0-indexed, so level 2 = Lv3

## Hyperactive stacking tracker
var hyperactive_stack_count : int = 0

enum BED_TYPE {
	TYPE_C,
	TYPE_B,
	TYPE_A
}

var primary_reached_lv3 : Dictionary[String, bool] = {
	"STRESS": false,
	"CALM": false,
}
var insomnia_days_active : int = 0
var insomnia_bad_sleep_days : int = 0
var insomnia_proper_sleep_streak : int = 0
var slept_today : bool = false

## Generador de azar del sistema de efectos. Sin tipo a proposito: las pruebas automaticas
## (Tools/probar_efectos.gd) lo sustituyen por un objeto con randf() / randi_range().
var rng = RandomNumberGenerator.new()

#region Constantes del motor de efectos (Docs/Design/SISTEMA_EFECTOS.md)
## Cordura: bucle cerrado y estabilizadores (§2)
const SANITY_GAIN_ROUTINE : float = 3.0
const SANITY_GAIN_FREE_DAY : float = 3.0
const SANITY_SUNDAY_PULL : float = 0.25
const SANITY_LOSS_DAMPING : float = 0.75
const SANITY_LOSS_DAILY_CAP : float = 10.0
const SANITY_REBOUND_BELOW_30 : float = 2.0
const SANITY_REBOUND_BELOW_40 : float = 1.5
const SANITY_FLOOR_PROLOGUE : float = 10.0
const CALM_LOSS_PROTECTION : Array[float] = [0.05, 0.08, 0.12]
const SLEEPY_SANITY_LOSS : Array[float] = [3.0, 5.0, 8.0]
const WEAK_SANITY_LOSS : float = 5.0
const STREET_SANITY_LOSS : float = 5.0
## Mitigacion, niveles internos y topes de modificadores
const MITIGATION_DAILY_CAP : int = 2
const LEVEL_SCALE : Array[float] = [0.4, 0.7, 1.0]
const COST_FACTOR_MIN : float = 0.25
const COST_FACTOR_MAX : float = 2.0
const TIME_FACTOR_MIN : float = 0.5
const TIME_FACTOR_MAX : float = 3.0
## Sueno
const SLEEP_DEBT_CAP : String = "36:00"
const SLEEP_DEBT_VIGIL : String = "12:00"
const SLEEP_AGAIN_AFTER : String = "12:00"
## Efectos derivados (probabilidades por nivel I / II / III)
const DERIVED_SPAWN_CHANCE : float = 0.5
const INAPETENCIA_EAT_FAIL : Array[float] = [0.20, 0.35, 0.50]
const INAPETENCIA_ENERGY_MULT : Array[float] = [0.90, 0.82, 0.75]
const INAPETENCIA_HUNGER_ROLL : Array[float] = [0.15, 0.35, 0.70]
const HIPERSOMNIA_SLEEPY_ROLL : Array[float] = [0.15, 0.30, 0.60]
const HIPERSOMNIA_ACTION_STRESS : Array[float] = [0.04, 0.07, 0.10]
const HIPERSOMNIA_STREET_MULT : Array[float] = [1.4, 1.7, 2.0]
const ATENTA_HYPERACTIVE_ROLL : Array[float] = [0.10, 0.25, 0.50]
const ATENTA_STREET_MULT : Array[float] = [0.8, 0.65, 0.5]
const STRESS_HYPERACTIVE_ROLL : Array[float] = [0.15, 0.30, 0.60]
## Energia
const WEAK_FROM_TIRED_CHANCE : float = 0.30
const WEAK_FROM_TIRED_ACTIONS : int = 4
const WEAK_FROM_TIRED_ACTION_CHANCE : float = 0.50
const TIMED_HYPERACTIVE_DURATION : String = "02:00"
## Causas activas de Estres
const INSTANT_MEAL_STRESS_CHANCE : float = 0.5
const COLD_WATER_STRESS_CHANCE : float = 0.5
const COLD_WATER_ATENTA_DURATION : String = "01:00"   ## agua fria -> Atenta I durante 1 h (tu FJ7)
#endregion

# --- Estado del motor ---
var sanity_floor : float = SANITY_FLOOR_PROLOGUE
var daily : Dictionary = _new_daily()
var last_night_proper : bool = true
var last_routine_full : bool = false
var proper_nights_in_row : int = 0
var tired_actions : int = 0
var internal_levels : Dictionary = {}
var _internal_days : Dictionary = {}
var _sleeping : bool = false
var _wake_checks_pending : bool = false
var hyperactive_timed : bool = false
var atenta_from_cold_water : bool = false ## true mientras la Atenta activa viene del agua fria (dura 1 h)

func _ready() -> void:
	player = load("res://Prefabs/Player/Player.tscn").instantiate()
	add_child(player)
	load_default_stats()
	
	energy_effects = {
		"hyperactive" : load("res://Resources/Effects/Effects/hyperactive.tres"),
		"tired" : load("res://Resources/Effects/Effects/tired.tres"),
	}
	stat_decrease.connect(energy_spend_handler)
	TimeManager.day_changed.connect(_on_day_changed_primary_effects)
	TimeManager.minutes_delta.connect(_on_clothes_time)
	reset_outfits()
	effect_removed.connect(_on_effect_removed)

#recorre el recurso que contiene las stats y carga su valor
func load_default_stats() -> void :
	for stat_res in DirAccess.get_files_at(STATS_FOLDER_PATH):
		if not stat_res.ends_with("tres") and not stat_res.ends_with("res"):
			continue
		stats.append(load(STATS_FOLDER_PATH + stat_res))
	
	connect_to_stat("ENERGY", auto_energy_effects)
	
var hungry_energy_log : float = 0
var hungry_energy : float = 120

func energy_spend_handler(stat : Stat, _decrease_value : float) -> void :
	if stat.stat_unique_name == "ENERGY" :
		hungry_energy_log += _decrease_value
		if hungry_energy_log >= hungry_energy :
			add_effect(load("res://Resources/Effects/Effects/hunger.tres"))
			hungry_energy_log -= hungry_energy
		# Agotada (energia 1-15): cada 4 acciones seguidas hay 50 % de caer en Debilitamiento
		if has_effect("TIRED") and not has_effect("WEAK"):
			tired_actions += 1
			if tired_actions >= WEAK_FROM_TIRED_ACTIONS:
				tired_actions = 0
				if rng.randf() < WEAK_FROM_TIRED_ACTION_CHANCE:
					_acquire_weak()
		else:
			tired_actions = 0

func auto_energy_effects(_new_value : float) -> void :
	var nothing : bool = true
	if _new_value >= 90 :
		# Solo se agrega si no estaba activa: volver a agregarla en cada cambio de energia contaba como
		# "Hiperactividad reactivada" y disparaba Insomnio sin que el jugador hiciera nada.
		if not has_effect("HYPERACTIVE"):
			add_effect(energy_effects.hyperactive)
		clear_energy_effects(energy_effects.hyperactive.effect_unique_name)
		nothing = false
	elif _new_value <= 0 :
		nothing = false
		sleep()
		_acquire_weak()
	elif _new_value <= 15 :
		nothing = false
		add_effect(energy_effects.tired)
		clear_energy_effects(energy_effects.tired.effect_unique_name)

	if nothing : clear_energy_effects("")

func clear_energy_effects(_exception : String) :
	for x in energy_effects :
		var unique_name : String = energy_effects[x].effect_unique_name
		if unique_name == _exception : continue
		# la Hiperactividad temporal (cafe, Atenta, Estres) no se quita por un cambio de energia
		if unique_name == "HYPERACTIVE" and hyperactive_timed : continue
		remove_effect(unique_name)
#con la variable modifier, modifica el valor de cada stat recorriendo su recurso que se obtuvo antes
func apply_effects(_effect_name : String = "") -> void:
	for stat in stats:
		stat.value = get_stat_change_total(stat.stat_unique_name)

#endregion

#region EFFECTS API

func add_level_effect(effect : EffectLevel, chances : float) -> void :
	pass

func decrease_level_effect(unique_effect_name : String, _value : int) -> void : ## Disminuye el nivel de un efecto de tipo nivel
	var effect = get_effect_res(unique_effect_name)
	if effect is EffectLevel :
		effect.change_level_value(effect.level - _value)
	else : return

func increase_level_effect(unique_effect_name : String, _value : int) -> void : ## Aumenta el nivel de un efecto de tipo nivel
	var effect = get_effect_res(unique_effect_name)
	if effect is EffectLevel :
		effect.change_level_value(effect.level + _value)
	else : return

func get_effect_level(unique_effect_name : String) -> String : ## obten el nombre del efecto, sera el nombre de este
	var effect = get_effect_res(unique_effect_name)
	if effect is EffectLevel :
		return tr(effect.get_level_display())
	else : return ""

func get_effect_level_value(unique_effect_name : String) -> float : ## obten el valor numerico del efecto, no empieza en 0
	var effect = get_effect_res(unique_effect_name)
	if effect is EffectLevel :
		return effect.level + 1
	else : return -0.1

func get_cost_with_effects(unique_stat_name: String, _custom_num : float = 0) -> float :
	var total : float = _custom_num
	for effect in effects:
		total = effect.get_stat_change_total(unique_stat_name, total)
	if _custom_num > 0.0:   # tope de modificadores (R8)
		total = clampf(total, _custom_num * COST_FACTOR_MIN, _custom_num * COST_FACTOR_MAX)
	return total
func get_time_cost_with_effects(base_time: String) -> String:
	if not TimeUtils.is_valid_format(base_time):
		return base_time

	var factor : float = 1.0
	for effect in effects:
		if effect.time_changes != null and effect.time_changes.OPERATION == TimeChanger.OPERATION_CASE.MULTIPLIER:
			# los efectos con nivel interno (Atenta, Hipersomnia, Sueno) escalan su modificador por nivel
			var scaled_value : float = effect.time_changes.time_value * get_effect_scale(effect.effect_unique_name)
			factor *= maxf(0.0, 1.0 + scaled_value)

		if effect is EffectLevel:
			var level_effect : EffectLevel = effect as EffectLevel
			factor *= maxf(0.0, 1.0 + level_effect.get_time_cost_multiplier())

	# tope: los modificadores no se multiplican sin control (R8)
	return TimeUtils.multiply_time(base_time, clampf(factor, TIME_FACTOR_MIN, TIME_FACTOR_MAX))

func get_street_risk_chance(base_chance: float) -> float:
	var chance : float = clampf(base_chance, 0.0, 1.0)

	var atenta_level : int = get_internal_level("ATENTA")
	if atenta_level > 0:
		chance *= ATENTA_STREET_MULT[atenta_level - 1]

	var hipersomnia_level : int = get_internal_level("HIPERSOMNIA")
	if hipersomnia_level > 0:
		chance *= HIPERSOMNIA_STREET_MULT[hipersomnia_level - 1]

	return clampf(chance, 0.0, 1.0)
func add_effect(effect : Effect) -> void :
	if effect == null:
		return

	if _is_primary_effect_name(effect.effect_unique_name):
		var opposite_name : String = _get_opposite_primary_name(effect.effect_unique_name)
		if has_effect(opposite_name):
			var opposite_effect : EffectLevel = get_effect_res(opposite_name) as EffectLevel
			if opposite_effect != null:
				_reduce_or_remove_primary_effect(opposite_effect)
				return

	# HYPERACTIVE stacking trigger: two consecutive applications -> INSOMNIA
	if effect.effect_unique_name == "HYPERACTIVE":
		_handle_hyperactive_stacking()

	if has_effect(effect.effect_unique_name) :
		if effect is EffectLevel:
			if _is_primary_effect_name(effect.effect_unique_name):
				# R7: una nueva causa de un primario activo acelera su escalada (+1 dia), no lo sube de golpe
				(get_effect_res(effect.effect_unique_name) as EffectLevel).increment_days_active()
			else:
				increase_level_effect(effect.effect_unique_name, 1)
		return
	else :
		effect_added.emit(effect)
		effects.append(effect)
		
		# Check INSOMNIA + HYPERACTIVE combo -> health penalty
		if effect.effect_unique_name == "HYPERACTIVE" and has_effect("INSOMNIA"):
			_apply_insomnia_hyperactive_health_penalty()
		elif effect.effect_unique_name == "INSOMNIA" and has_effect("HYPERACTIVE"):
			_apply_insomnia_hyperactive_health_penalty()
		
		if effect is TemporalEffect :
			EventManager.create_lapse_event(effect.duration, remove_effect.bind(effect.effect_unique_name), "REMOVE_WEAK_AUTOMATICALLY", "", false, true, true)
	
func remove_effect(unique_effect_name : String) -> void : ## Remueve un efecto, usa el nombre unico/identificador
	var effect : Effect = get_effect_res(unique_effect_name)
	if effect == null or not effect : 
		return
	effect_removed.emit(effect)
	effects.erase(effect)

func has_effect(unique_effect_name : String) -> bool : ## Devuelve verdadero si el efecto existe, usa el nombre unico/identificador
	var effect : Effect = get_effect_res(unique_effect_name)
	if effect == null or not effect: 
		return false
	return effects.has(effect)

func get_effect_res(unique_effect_name : String) -> Effect : ## Obten el recurso tipo efecto, usa el nombre unico/identificador
	for effect : Effect in effects :
		if effect.effect_unique_name == unique_effect_name :
			return effect
	return null

func decrease_control_effect_hour(effect_unique_name : String, decrease_time : String) -> void : ## usar el formato HH:MM
	var effect : Effect = get_effect_res(effect_unique_name)
	if effect == null : return
	if effect is EffectHourControl and TimeUtils.is_valid_format(decrease_time):
		effect.substract_time(decrease_time)
	else : return

func increase_control_effect_hour(effect_unique_name : String, increase_time : String) -> void : ## usar el formato HH:MM
	var effect : Effect = get_effect_res(effect_unique_name)
	if effect == null : return
	if effect is EffectHourControl and TimeUtils.is_valid_format(increase_time):
		effect.add_time(increase_time)
	else : return

#endregion

#region STATS API

func get_stat_change_total(unique_stat_name: String) -> float:
	var total : float = 0
	for effect in effects:
		total += effect.stat_change_total(unique_stat_name)
	return total

func get_stat_connections(unique_stat_name : String, connection_parameter: CONNECTION_PARAM = CONNECTION_PARAM.SIGNAL) -> Array:
	var stat : Stat = get_stat_res(unique_stat_name)
	var connections = stat.value_changed.get_connections()
	var parameter = CONNECTION_PARAM.find_key(connection_parameter).to_lower()
	if !stat or connections.is_empty(): return []
	var value : Array = []
	for connection in connections:
		value.append(connection[parameter])
	return value
	
func is_callable_connected(unique_stat_name : String, callable: Callable) -> bool:
	var stat : Stat = get_stat_res(unique_stat_name)
	return stat.value_changed.is_connected(callable)

func connect_to_stat(unique_stat_name : String, callable : Callable) -> void : ## Conecta una funcion al cambio de una estadistica, usa el nombre unico/identificador, Esta señal retornara el valor nuevo de la estadistica
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null :
		return
	stat.value_changed.connect(callable)
	stat_connection_added.emit()

func get_sanity_state() -> SANITY_STATES : ## Obten el estado mental del jugador, ENUM SANITY_STATES, ejemplo SANITY_STATES.DOCILE
	if sanity_value >= 60 :
		return SANITY_STATES.DOCILE
	elif sanity_value >= 40 :
		return SANITY_STATES.NEUTRAL
	else :
		return SANITY_STATES.DISTURBED

func get_sanity_value() -> float :
	return sanity_value

func is_on_sanity_range(_min : float, _max : float) -> bool : ## Retorna verdadero si el nivel de cordura se encuentra dentro de el rango enviado
	return sanity_value >= _min and sanity_value <= _max

func decrease_stat(unique_stat_name : String, value : float) -> void : ## Disminuye una estadistica, usa el nombre unico/identificador
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null or not stat: 
		return
	stat_decrease.emit(stat, value)
	stat.value -= value

func increase_stat(unique_stat_name : String, value : float) -> void : ## Aumenta una estadistica, usa el nombre unico/identificador
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null or not stat: 
		return
	stat_increase.emit(stat, value)
	stat.value += value

func get_stat_res(unique_stat_name : String) -> Stat : ## Obten el recurso tipo Stat, usa el nombre unico/identificador
	for stat : Stat in stats :
		if stat.stat_unique_name == unique_stat_name :
			return stat
	return null

func get_stat_value(unique_stat_name : String) -> float : ## Obten el valor de una Stat, usa el nombre unico/identificador
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null or not stat: 
		return -1.0
	return stat.value

#endregion

#region ACTIONS

var minimun_hours_ranges := [
	{ "energy": 15, "hours": "10:00" },
	{ "energy": 30, "hours": "09:00" },
	{ "energy": 50, "hours": "08:00" },
	{ "energy": 70, "hours": "07:00" },
	{ "energy": 100, "hours": "06:00" }
]

var mininum_energy_ranges : Dictionary = {
	"01:00" : 5, "02:00" : 8, "03:00" : 10,
	"04:00" : 12,"05:00" : 15,"06:00" : 20,
	"07:00" : 30,"08:00" : 35,"09:00" : 38,
	"10:00" : 40
}

var hour_debt : String = "00:00"

const ALARM_UI_SCENE := preload("res://UI/Sleep/AlarmUI.tscn")

## Punto de entrada para camas/interactables. Muestra AlarmUI y luego llama sleep().
var _sleep_in_progress : bool = false ## evita abrir varias alarmas / dormir varias veces a la vez

func request_sleep(bed_type: int = BED_TYPE.TYPE_C) -> void:
	if _sleep_in_progress:
		return
	if slept_today:
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "Ya dormí lo suficiente por hoy.")
		return
	_sleep_in_progress = true
	GameManager.modal_count += 1
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	get_tree().root.add_child(canvas)
	var ui : Control = ALARM_UI_SCENE.instantiate()
	canvas.add_child(ui)
	ui.setup(bed_type)
	var result : Array = await ui.sleep_confirmed
	canvas.queue_free()
	if result[0] == "":   # Cancelar / Esc: no duerme ni pasa el tiempo
		GameManager.modal_count -= 1
		_sleep_in_progress = false
		return
	await sleep(result[0], result[1])
	GameManager.modal_count -= 1
	_sleep_in_progress = false
	if not slept_today:
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "No tengo sueño todavía.")

func sleep(hour_deal : String = "00:00", bed_type: int = BED_TYPE.TYPE_C) -> void :
	if slept_today:
		return
	AudioManager.play_sleep()

	var minimun_hours : String = "00:00"

	var current_energy : float = get_stat_value("ENERGY")

	for r in minimun_hours_ranges:
		if current_energy <= r.energy:
			minimun_hours = r.hours
			break
	
	if minimun_hours == "00:00" :
		return

	minimun_hours = _get_adjusted_minimum_sleep(minimun_hours, bed_type)

	var requested_sleep : String = hour_deal
	if requested_sleep == "00:00" and _can_use_alarm_override():
		var override_hours : Variant = NarrativeFlags.get_value(SLEEP_ALARM_OVERRIDE_FLAG, "00:00")
		if override_hours is String and TimeUtils.is_valid_format(override_hours):
			requested_sleep = override_hours

	if requested_sleep != "00:00" and !_can_use_alarm_override():
		requested_sleep = "00:00"

	if requested_sleep == "00:00":
		requested_sleep = minimun_hours

	if TimeUtils.is_greater_or_equal(minimun_hours, requested_sleep) :
		
		var debt_pay = TimeUtils.decrease_time(requested_sleep, minimun_hours)
		decrease_control_effect_hour("SLEEPY", debt_pay)
		
		requested_sleep = minimun_hours

	var actual_sleep : String = requested_sleep
	var insomnia_effect : EffectLevel = get_effect_res("INSOMNIA") as EffectLevel
	if insomnia_effect != null:
		var insomnia_cap : String = _roll_insomnia_sleep_cap(insomnia_effect.level)
		var sleep_minutes : int = mini(TimeUtils.get_minutes(requested_sleep), TimeUtils.get_minutes(insomnia_cap))
		actual_sleep = TimeManager.format_minutes(sleep_minutes)

	var slept_properly : bool = TimeUtils.is_greater_or_equal(minimun_hours, actual_sleep)
	# Se captura ANTES de avanzar el reloj: el cambio de dia (medianoche) reinicia arrived_today.
	var worked_today : bool = AttendanceManager.arrived_today
	if insomnia_effect == null:
		if slept_properly:
			insomnia_bad_sleep_days = 0
		else:
			insomnia_bad_sleep_days += 1
	
	var base_energy : float = _get_base_energy_for_hours(actual_sleep)
	var energy_deal : float = base_energy * _get_bed_energy_multiplier(bed_type)

	_sleeping = true   # mientras duerme, el cambio de dia cierra el dia pero los chequeos de la manana esperan
	TransitionManager.fadeIn(3)
	await TransitionManager.transition_finished
	TimeManager.add_to_current_time(actual_sleep)
	TransitionManager.fadeOut(3)

	_finish_sleep(actual_sleep, minimun_hours, bed_type, slept_properly, worked_today, energy_deal)

	await TransitionManager.transition_finished

## Efectos del sueno ya consumado (separado de las transiciones para poder probarlo). SISTEMA_EFECTOS §6.4.
func _finish_sleep(actual_sleep: String, minimun_hours: String, bed_type: int, slept_properly: bool, worked_today: bool, energy_deal: float) -> void:
	increase_stat("ENERGY", energy_deal)
	if slept_properly:
		proper_nights_in_row += 1
	else:
		proper_nights_in_row = 0
	_apply_sleep_stress_reduction(bed_type, slept_properly, worked_today)
	_pay_sleep_debt(actual_sleep)
	_accumulate_sleep_deficit(minimun_hours, actual_sleep)
	if has_effect("INSOMNIA"):
		_register_insomnia_sleep_quality(minimun_hours, actual_sleep)
	elif not slept_properly:
		add_effect(EFFECT_INSOMNIA.duplicate())
	EventManager.reset_lapse_event("AUTO_SLEEPY_LAPSE")
	slept_today = true
	# se puede volver a dormir 12 h despues: antes solo se reiniciaba a medianoche y, tras una noche
	# que cruza la medianoche, la cama quedaba bloqueada toda la tarde siguiente
	EventManager.create_lapse_event(SLEEP_AGAIN_AFTER, _allow_sleep_again, "SLEPT_TODAY_RESET", "", false, true, true)
	last_night_proper = slept_properly
	_sleeping = false
	if _wake_checks_pending:
		_run_wake_checks()

func _allow_sleep_again() -> void:
	slept_today = false

## Cada noche de 6 h o mas paga hasta 6 h de deuda de sueno (12 h = 2 noches).
func _pay_sleep_debt(actual_sleep: String) -> void:
	if not has_effect("SLEEPY"):
		return
	var minutes : int = TimeUtils.get_minutes(actual_sleep)
	if minutes < 6 * 60:
		return
	decrease_control_effect_hour("SLEEPY", TimeManager.format_minutes(mini(minutes, 6 * 60)))

## Dormir menos del minimo acumula deficit oculto; al llegar a 6 h aparece el Sueno con esa deuda.
## Ahora se acumula SIEMPRE (antes se ignoraba con Insomnio o Sueno activos).
func _accumulate_sleep_deficit(minimun_hours: String, actual_sleep: String) -> void:
	var deficit : String = TimeUtils.decrease_time(minimun_hours, actual_sleep)
	if deficit == "00:00":
		return
	if has_effect("SLEEPY"):
		increase_control_effect_hour("SLEEPY", deficit)
		_cap_sleep_debt()
		return
	hour_debt = TimeUtils.increase_time(hour_debt, deficit)
	if TimeUtils.is_greater_or_equal("06:00", hour_debt):
		_apply_sleepy(hour_debt)
		hour_debt = "00:00"
func _roll_insomnia_sleep_cap(insomnia_level: int) -> String:
	var range := _get_insomnia_sleep_range(insomnia_level)
	var random_hours : int = rng.randi_range(range.x, range.y)
	return TimeManager.format_minutes(random_hours * 60)

func _get_insomnia_sleep_range(insomnia_level: int) -> Vector2i:
	match insomnia_level:
		0:
			return Vector2i(INSOMNIA_LEVEL1_SLEEP_MIN_HOURS, INSOMNIA_LEVEL1_SLEEP_MAX_HOURS)
		1:
			return Vector2i(INSOMNIA_LEVEL2_SLEEP_MIN_HOURS, INSOMNIA_LEVEL2_SLEEP_MAX_HOURS)
		2:
			return Vector2i(INSOMNIA_LEVEL3_SLEEP_MIN_HOURS, INSOMNIA_LEVEL3_SLEEP_MAX_HOURS)
	return Vector2i(INSOMNIA_LEVEL1_SLEEP_MIN_HOURS, INSOMNIA_LEVEL1_SLEEP_MAX_HOURS)

func _register_insomnia_sleep_quality(minimum_hours: String, actual_sleep: String) -> void:
	var slept_properly : bool = TimeUtils.is_greater_or_equal(minimum_hours, actual_sleep)
	if slept_properly:
		insomnia_proper_sleep_streak += 1
		insomnia_bad_sleep_days = 0
		if insomnia_proper_sleep_streak >= INSOMNIA_RECOVERY_REQUIRED_PROPER_SLEEPS:
			remove_effect("INSOMNIA")
		return

	insomnia_bad_sleep_days += 1
	insomnia_proper_sleep_streak = 0

func _get_adjusted_minimum_sleep(base_minimum_hours: String, bed_type: int) -> String:
	var reduction_minutes : int = _get_bed_time_reduction_minutes(bed_type)
	if reduction_minutes <= 0:
		return base_minimum_hours

	var reduced_minutes : int = maxi(TimeUtils.get_minutes(base_minimum_hours) - reduction_minutes, 0)
	return TimeManager.format_minutes(reduced_minutes)

func _get_bed_time_reduction_minutes(bed_type: int) -> int:
	match bed_type:
		BED_TYPE.TYPE_A:
			return 60
		BED_TYPE.TYPE_B:
			return 30
	return 0

func _get_bed_energy_multiplier(bed_type: int) -> float:
	match bed_type:
		BED_TYPE.TYPE_A:
			return 1.10
		BED_TYPE.TYPE_B:
			return 1.05
	return 1.0

func _get_base_energy_for_hours(sleep_time: String) -> float:
	var sleep_minutes : int = TimeUtils.get_minutes(sleep_time)
	if sleep_minutes <= 0:
		return 0.0

	var sleep_hours : float = float(sleep_minutes) / 60.0
	if sleep_hours >= 10.0:
		return 40.0

	var lower_hour : int = maxi(int(floor(sleep_hours)), 1)
	var upper_hour : int = mini(int(ceili(sleep_hours)), 10)
	var lower_key : String = "%02d:00" % lower_hour
	var upper_key : String = "%02d:00" % upper_hour
	var lower_value : float = float(mininum_energy_ranges.get(lower_key, 0.0))
	var upper_value : float = float(mininum_energy_ranges.get(upper_key, lower_value))

	if lower_hour == upper_hour:
		return lower_value

	var t : float = clamp(sleep_hours - float(lower_hour), 0.0, 1.0)
	return lerpf(lower_value, upper_value, t)

func _get_sleep_stress_reduction_percent(bed_type: int) -> float:
	var reduction : float = SLEEP_STRESS_BASE_REDUCTION_PERCENT
	match bed_type:
		BED_TYPE.TYPE_A:
			reduction += SLEEP_STRESS_BED_A_BONUS_PERCENT
		BED_TYPE.TYPE_B:
			reduction += SLEEP_STRESS_BED_B_BONUS_PERCENT
	return reduction

## Dormir apropiadamente baja el Estres: -1 nivel (la cama A suma 75 % de un -1 extra y la B 25 %).
## Si hubo jornada laboral ese dia el piso es el nivel I; 2 noches apropiadas seguidas lo anulan
## (solo si no hubo jornada). SISTEMA_EFECTOS §3.1.
func _apply_sleep_stress_reduction(bed_type: int, slept_properly: bool, worked_today: bool) -> void:
	var stress_effect : EffectLevel = get_effect_res("STRESS") as EffectLevel
	if stress_effect == null or not slept_properly:
		return

	var current_levels : int = stress_effect.level + 1
	var floor_levels : int = 1 if worked_today else 0
	var reduction : int = 1
	if bed_type == BED_TYPE.TYPE_A and rng.randf() < 0.75:
		reduction += 1
	elif bed_type == BED_TYPE.TYPE_B and rng.randf() < 0.25:
		reduction += 1
	reduction = mini(reduction, current_levels - floor_levels)
	if proper_nights_in_row >= 2 and not worked_today:
		reduction = current_levels   # anula
	if reduction > 0:
		mitigate_stress(reduction, "SLEEP")
func _can_use_alarm_override() -> bool:
	return NarrativeFlags.has_any_flag(SLEEP_ALARM_ACCESS_FLAGS)

#region INSOMNIA TRIGGER MATRIX

## Hyperactive stacking: two consecutive HYPERACTIVE applications trigger INSOMNIA
func _handle_hyperactive_stacking() -> void:
	if has_effect("HYPERACTIVE"):
		# Already have hyperactive, this is second application
		hyperactive_stack_count += 1
		if hyperactive_stack_count >= 2 and not has_effect("INSOMNIA"):
			add_effect(EFFECT_INSOMNIA.duplicate())
			hyperactive_stack_count = 0
	else:
		hyperactive_stack_count = 1

## Reset hyperactive stack when effect is removed
func _reset_hyperactive_stack() -> void:
	hyperactive_stack_count = 0

## INSOMNIA + HYPERACTIVE combo: apply health penalty
func _apply_insomnia_hyperactive_health_penalty() -> void:
	var health_stat : Stat = get_stat_res("HEALTH")
	if health_stat != null:
		decrease_stat("HEALTH", INSOMNIA_HYPERACTIVE_HEALTH_PENALTY)

## Coffee at high energy (>= 90%) triggers INSOMNIA
## Call this when coffee is consumed
func check_coffee_insomnia_trigger() -> void:
	var current_energy : float = get_stat_value("ENERGY")
	if current_energy >= INSOMNIA_COFFEE_ENERGY_THRESHOLD and not has_effect("INSOMNIA"):
		add_effect(EFFECT_INSOMNIA.duplicate())

## SLEEPY III + day without proper sleep triggers INSOMNIA
func _check_sleepy_insomnia_trigger() -> void:
	if get_sleepy_level() >= 3 and insomnia_bad_sleep_days >= 1 and not has_effect("INSOMNIA"):
		add_effect(EFFECT_INSOMNIA.duplicate())
#endregion

#region WORK TASK SUCCESS PENALTY

## Work task success modifiers based on STRESS level
## STRESS Lv1: -10% success, STRESS Lv2: -25% success, STRESS Lv3: -50% success
const WORK_SUCCESS_PENALTY_LV1 : float = 0.10
const WORK_SUCCESS_PENALTY_LV2 : float = 0.25
const WORK_SUCCESS_PENALTY_LV3 : float = 0.50

## Get the success rate modifier for work tasks (emails, minigames)
## Returns 1.0 if no penalty, or reduced value if STRESS is active
func get_work_success_rate() -> float:
	if not has_effect("STRESS"):
		return 1.0
	
	var stress_level : int = int(get_effect_level_value("STRESS"))
	match stress_level:
		1:
			return 1.0 - WORK_SUCCESS_PENALTY_LV1  # 0.90
		2:
			return 1.0 - WORK_SUCCESS_PENALTY_LV2  # 0.75
		3:
			return 1.0 - WORK_SUCCESS_PENALTY_LV3  # 0.50
	return 1.0

## Roll to check if a work task action succeeds despite STRESS
## Returns true if action succeeds, false if STRESS causes failure
func roll_work_task_success() -> bool:
	var success_rate : float = get_work_success_rate()
	return randf() <= success_rate

## Get the failure chance for work tasks (inverse of success rate)
func get_work_failure_chance() -> float:
	return 1.0 - get_work_success_rate()

#endregion

#region PRIMARY EFFECTS (STRESS / CALM) + MOTOR DIARIO  (Docs/Design/SISTEMA_EFECTOS.md)

## Cambio de dia (medianoche): cierra el dia que termino y, si Mayui NO esta durmiendo, corre los
## chequeos de la manana. Si esta durmiendo, esperan al final del sueno (ver _finish_sleep) para
## resolverse DESPUES de pagar deuda de sueno, recuperar energia, etc. (SISTEMA_EFECTOS §6).
func _on_day_changed_primary_effects(_day: int) -> void:
	slept_today = false
	_close_day()
	if _sleeping:
		_wake_checks_pending = true
	else:
		_run_wake_checks()

#region Estado y utilidades del motor
func _new_daily() -> Dictionary:
	return {"home_meals": 0, "instant_meals": 0, "bathed": false, "gambled": false,
		"sanity_loss": 0.0, "mitigated": 0, "street_events": 0, "brushed": false}

## Reinicia los contadores del motor. Con full = true tambien limpia efectos, cordura y sueno
## (lo usan las pruebas automaticas y las partidas nuevas).
func reset_engine_state(full: bool = false) -> void:
	daily = _new_daily()
	last_night_proper = true
	last_routine_full = false
	proper_nights_in_row = 0
	tired_actions = 0
	internal_levels.clear()
	_internal_days.clear()
	_sleeping = false
	_wake_checks_pending = false
	hyperactive_timed = false
	atenta_from_cold_water = false
	if not full:
		return
	for e : Effect in effects.duplicate():
		remove_effect(e.effect_unique_name)
	sanity_value = 50.0
	sanity_floor = SANITY_FLOOR_PROLOGUE
	hour_debt = "00:00"
	slept_today = false
	insomnia_days_active = 0
	insomnia_bad_sleep_days = 0
	insomnia_proper_sleep_streak = 0
	hyperactive_stack_count = 0
	hungry_energy_log = 0.0
	primary_reached_lv3 = {"STRESS": false, "CALM": false}
	var energy : Stat = get_stat_res("ENERGY")
	if energy != null:
		energy.value = 45.0
	reset_outfits()

func _stress_level() -> int:
	var e : EffectLevel = get_effect_res("STRESS") as EffectLevel
	return (e.level + 1) if e != null else 0

func _calm_level() -> int:
	var e : EffectLevel = get_effect_res("CALM") as EffectLevel
	return (e.level + 1) if e != null else 0

## Nivel interno (1..3) de un efecto con un solo icono. Un efecto sin nivel registrado se trata
## como de nivel III (valores completos), que es como se comportaba antes.
func get_internal_level(effect_name: String) -> int:
	if not has_effect(effect_name):
		return 0
	return int(internal_levels.get(effect_name, 3))

func _set_internal_level(effect_name: String, level: int) -> void:
	internal_levels[effect_name] = clampi(level, 1, 3)
	_internal_days[effect_name] = 0

## Escalada uniforme de un efecto con nivel interno: II tras 1 dia, III tras 2 dias mas.
func _advance_internal_level(effect_name: String) -> void:
	_internal_days[effect_name] = int(_internal_days.get(effect_name, 0)) + 1
	var level : int = get_internal_level(effect_name)
	if level == 1 and _internal_days[effect_name] >= 1:
		_set_internal_level(effect_name, 2)
	elif level == 2 and _internal_days[effect_name] >= 2:
		_set_internal_level(effect_name, 3)

## Atenta e Hipersomnia son opuestas: la que llega baja 1 nivel de la otra.
func _reduce_internal_effect(effect_name: String) -> void:
	var level : int = get_internal_level(effect_name)
	if level <= 1:
		remove_effect(effect_name)
	else:
		_set_internal_level(effect_name, level - 1)

## Factor para escalar los modificadores de un efecto segun su nivel (el nivel III es el valor completo).
func get_effect_scale(effect_name: String) -> float:
	var level : int = get_sleepy_level() if effect_name == "SLEEPY" else get_internal_level(effect_name)
	if level <= 0:
		return 1.0
	return LEVEL_SCALE[clampi(level, 1, 3) - 1]

func get_sleepy_level() -> int:
	var sleepy : EffectHourControl = get_effect_res("SLEEPY") as EffectHourControl
	if sleepy == null:
		return 0
	var minutes : int = TimeUtils.get_minutes(sleepy.time)
	if minutes <= 0:
		return 0
	if minutes <= 12 * 60:
		return 1
	if minutes <= 24 * 60:
		return 2
	return 3

## Probabilidad de que una accion cause Estres por Hipersomnia (4 / 7 / 10 % segun el nivel).
func get_action_stress_chance() -> float:
	var level : int = get_internal_level("HIPERSOMNIA")
	return HIPERSOMNIA_ACTION_STRESS[level - 1] if level > 0 else 0.0

## Penalizaciones de Inapetencia al comer (segun su nivel): probabilidad de fallar y energia recuperada.
func get_inapetencia_eating() -> Dictionary:
	var level : int = get_internal_level("INAPETENCIA")
	if level <= 0:
		return {"fail_chance": 0.0, "energy_mult": 1.0}
	return {"fail_chance": INAPETENCIA_EAT_FAIL[level - 1], "energy_mult": INAPETENCIA_ENERGY_MULT[level - 1]}
#endregion

#region Cordura: bucle cerrado y estabilizadores (§2)
## UNICA puerta para cambiar la cordura en el juego. Aplica los estabilizadores:
## ganancias x2 bajo 30 y x1.5 bajo 40; perdidas x0.75, protegidas por Calma, con tope diario y piso.
## (Las pruebas y el panel de depuracion pueden seguir asignando sanity_value directamente.)
func change_sanity(delta: float, _source: String = "") -> float:
	if delta == 0.0:
		return 0.0
	var before : float = sanity_value
	if delta > 0.0:
		var rebound : float = 1.0
		if sanity_value < 30.0:
			rebound = SANITY_REBOUND_BELOW_30
		elif sanity_value < 40.0:
			rebound = SANITY_REBOUND_BELOW_40
		sanity_value = minf(100.0, sanity_value + delta * rebound)
	else:
		var loss : float = -delta * SANITY_LOSS_DAMPING
		var calm : EffectLevel = get_effect_res("CALM") as EffectLevel
		if calm != null:
			loss *= 1.0 - CALM_LOSS_PROTECTION[clampi(calm.level, 0, 2)]
		loss = minf(loss, maxf(0.0, SANITY_LOSS_DAILY_CAP - float(daily.sanity_loss)))
		daily.sanity_loss += loss
		# nunca baja del piso; si ya estaba por debajo (p. ej. por el panel de depuracion), no la sube
		sanity_value = maxf(minf(sanity_value, sanity_floor), sanity_value - loss)
	return sanity_value - before
#endregion

#region Causas, mitigacion y habitos (§3 y §5)
## Una causa ACTIVA de Estres: lo crea; si ya existe, acelera su escalada (+1 dia) en vez de subir
## de nivel de golpe; si hay Calma, esta baja 1 nivel y el Estres no se activa (add_effect).
func add_stress_cause(_source: String = "") -> void:
	if has_effect("STRESS"):
		(get_effect_res("STRESS") as EffectLevel).increment_days_active()
	else:
		add_effect(EFFECT_STRESS.duplicate())

## Mitiga el Estres hasta `levels` niveles, con el tope diario de MITIGATION_DAILY_CAP.
## Devuelve cuantos niveles quito.
func mitigate_stress(levels: int = 1, _source: String = "") -> int:
	var removed : int = 0
	var allowed : int = mini(levels, MITIGATION_DAILY_CAP - int(daily.mitigated))
	while removed < allowed and has_effect("STRESS"):
		_reduce_or_remove_primary_effect(get_effect_res("STRESS") as EffectLevel)
		removed += 1
	daily.mitigated += removed
	return removed

## Llamar al comer. kind = "HOME" (comida casera) o "INSTANT" (instantanea); hot = servida caliente.
func register_meal(kind: String, hot: bool = false) -> void:
	if kind == "HOME":
		daily.home_meals += 1
		if hot:
			mitigate_stress(1, "HOT_MEAL")
	else:
		daily.instant_meals += 1
		if has_effect("CALM"):   # la comida instantanea baja 1 nivel de Calma (SISTEMA_EFECTOS §3.1)
			_reduce_or_remove_primary_effect(get_effect_res("CALM") as EffectLevel)
		if rng.randf() < INSTANT_MEAL_STRESS_CHANCE:
			add_stress_cause("INSTANT_MEAL")

## Llamar al banarse. cold = agua fria (solo el tutorial): Atenta I durante 1 h y, con probabilidad,
## Estres; con agua caliente baja 1 nivel de Estres.
func register_bath(cold: bool = false) -> void:
	daily.bathed = true
	if cold:
		_apply_cold_water_atenta()
		if rng.randf() < COLD_WATER_STRESS_CHANCE:
			add_stress_cause("COLD_WATER")
	else:
		mitigate_stress(1, "HOT_BATH")

## Llamar al cepillarse los dientes en el espejo del lavamanos. La Suciedad de la boca (2.a capa de la Suciedad) aun no existe.
const BRUSH_TIME : String = "00:05"   ## propuesta (SISTEMA_GAMEPLAY: Cepillarse tarda 5 min)
func register_brush() -> void:
	daily.brushed = true

## Agua fria: Atenta I durante 1 h. Si ya habia Atenta (por Insomnio) no se toca; con Hipersomnia
## (su opuesta) solo la reduce 1 nivel.
func _apply_cold_water_atenta() -> void:
	if has_effect("HIPERSOMNIA"):
		_reduce_internal_effect("HIPERSOMNIA")
		return
	if has_effect("ATENTA"):
		return
	add_effect(EFFECT_ATENTA.duplicate())
	_set_internal_level("ATENTA", 1)
	atenta_from_cold_water = true
	EventManager.create_lapse_event(COLD_WATER_ATENTA_DURATION, _end_cold_water_atenta, "TIMED_ATENTA", "COLD_WATER", false, true, true)

func _end_cold_water_atenta() -> void:
	if not atenta_from_cold_water:
		return
	atenta_from_cold_water = false
	# si mientras tanto el Insomnio (2 dias) la volvio permanente, se queda
	if not (has_effect("INSOMNIA") and insomnia_days_active >= 2):
		remove_effect("ATENTA")

## Llamar al apostar. Ganar anula el Estres; perder anula la Calma y causa Estres.
func register_gamble(won: bool) -> void:
	daily.gambled = true
	if won:
		remove_effect("STRESS")
	else:
		remove_effect("CALM")
		add_stress_cause("GAMBLE_LOSS")

## Llamar cuando la sorprenden en la calle: -5 cordura, anula la Calma, causa Estres.
func register_street_event() -> void:
	daily.street_events += 1
	remove_effect("CALM")   # primero se anula la Calma: asi no amortigua el golpe que la anula
	change_sanity(-STREET_SANITY_LOSS, "STREET")
	add_stress_cause("STREET")

## Hiperactividad por una causa temporal (cafe, Atenta, Estres). Dura 2 h. Si ya estaba activa
## (por energia o por otra causa) cuenta como "reactivada": _handle_hyperactive_stacking -> Insomnio.
func apply_timed_hyperactive(source: String) -> void:
	hyperactive_timed = true
	add_effect(energy_effects.hyperactive)
	EventManager.create_lapse_event(TIMED_HYPERACTIVE_DURATION, _end_timed_hyperactive, "TIMED_HYPERACTIVE", source, false, true, true)

## El cafe quita 1 nivel de Hipersomnia (una vez al dia).
func coffee_relieves_hipersomnia() -> void:
	if has_effect("HIPERSOMNIA") and not daily.get("coffee_relief", false):
		daily["coffee_relief"] = true
		_reduce_internal_effect("HIPERSOMNIA")

func _end_timed_hyperactive() -> void:
	hyperactive_timed = false
	if get_stat_value("ENERGY") < 90.0:
		remove_effect("HYPERACTIVE")

## Sueno por vigilia (>16 h despierta): nace con 12 h de deuda. Lo llama el evento AUTO_SLEEPY_LAPSE.
## Dormir no cuenta como vigilia: si la marca de 16 h cae a mitad de la noche no se aplica, y el evento
## se reinicia al despertar (_finish_sleep). Se vio probando la cama real: una noche entera daba Sueno.
func apply_vigil_sleepy() -> void:
	if _sleeping:
		return
	_apply_sleepy(SLEEP_DEBT_VIGIL)

func _apply_sleepy(debt: String) -> void:
	if has_effect("SLEEPY"):
		increase_control_effect_hour("SLEEPY", debt)
	else:
		var sleepy : EffectHourControl = (load("res://Resources/Effects/Effects/sleepy.tres") as EffectHourControl).duplicate()
		sleepy.time = debt
		add_effect(sleepy)
	_cap_sleep_debt()

func _cap_sleep_debt() -> void:
	var sleepy : EffectHourControl = get_effect_res("SLEEPY") as EffectHourControl
	if sleepy != null and TimeUtils.get_minutes(sleepy.time) > TimeUtils.get_minutes(SLEEP_DEBT_CAP):
		sleepy.time = SLEEP_DEBT_CAP

## Debilitamiento por agotamiento o energia 0: el efecto mas -5 de cordura al adquirirlo.
func _acquire_weak() -> void:
	if has_effect("WEAK"):
		return
	add_effect(load("res://Resources/Effects/Effects/weak.tres"))
	change_sanity(-WEAK_SANITY_LOSS, "WEAK")
	tired_actions = 0
#endregion

#region Ropa puesta (armario)
## La ropa vive aqui (PlayerManager persiste entre zonas): lo que lleva puesto Mayui y las prendas colgadas en el armario.
## Cada prenda es un Item del dev (ItemData tipo CLOTH + ClothBehavior) con las condiciones `cleanliness` (<= 50 = sucia) y
## `wetness` (> 30 = mojada). Los numeros marcados "propuesta" son mios: ajustalos.
signal outfit_changed(item: Item)

const HOME_CLOTHES_DATA : String = "res://Resources/Items/Data/home_cloth.tres"
const WORK_CLOTHES_DATA : String = "res://Resources/Items/Data/work_cloth.tres"
const TOWEL_DATA : String = "res://Resources/Items/Data/towel_cloth.tres"
const CHANGE_CLOTHES_TIME : String = "00:02"            ## vestirse tarda 2 min (tu especificacion)
const CLOTHES_DIRT_PER_HOUR : float = 2.0               ## propuesta: limpieza que pierde la ropa puesta por hora (sucia a las ~25 h)
const CLOTHES_DRY_PER_HOUR : float = 10.0               ## propuesta: humedad que pierde por hora (mojada unas 7 h)
const DIRTY_CLOTHES_BODY_DIRT_RATE : float = 2.0        ## propuesta: con ropa sucia puesta la Suciedad del cuerpo (24 h) corre al doble
const WET_CLOTHES_DIRT_MINUTES : int = 360              ## ropa mojada mas de 6 h = Suciedad (SISTEMA_EFECTOS)
const WET_CLOTHES_WEAK_CHANCE : float = 0.25            ## propuesta: al ponerse ropa mojada, Debilitamiento
const WET_CLOTHES_STRESS_CHANCE : float = 0.50          ## propuesta: al ponerse ropa mojada, Estres

var outfit : Item = null                 ## lo que lleva puesto Mayui (puede ser la toalla)
var wardrobe : Array[Item] = []          ## prendas colgadas en el armario
var _wet_minutes : int = 0               ## minutos seguidos con la ropa mojada puesta

## Ropa inicial: ropa de casa puesta y el uniforme colgado (la toalla aparece al banarse).
func reset_outfits() -> void:
	wardrobe.clear()
	_wet_minutes = 0
	outfit = Item.new(load(HOME_CLOTHES_DATA))
	wardrobe.append(Item.new(load(WORK_CLOTHES_DATA)))
	_apply_outfit_sprite()
	outfit_changed.emit(outfit)

## Id de outfit ("home", "work", "outfit1", "towel") de una prenda; "" si no tiene arte asociado.
func outfit_id_of(item: Item) -> String:
	if item == null or item.data == null: return ""
	var behavior = item.data.behavior as ClothBehavior
	return behavior.clothing.outfit_id if behavior != null and behavior.clothing != null else ""

func get_outfit_id() -> String:
	return outfit_id_of(outfit)

## Mayui se pone una prenda del armario: la que llevaba vuelve a colgarse (la toalla no), cambia su sprite y, si la ropa esta
## mojada, hay probabilidad de Debilitamiento y de Estres. Quien llame debe sumar CHANGE_CLOTHES_TIME al reloj.
func wear_clothes(item: Item) -> void:
	if item == null: return
	var previous : Item = outfit
	wardrobe.erase(item)
	if previous != null and previous != item and outfit_id_of(previous) != "towel":
		wardrobe.append(previous)
	outfit = item
	_wet_minutes = 0
	_apply_outfit_sprite()
	if item.data.behavior != null:
		item.data.behavior.use(item)
	if item.has_state("wet"):
		if rng.randf() < WET_CLOTHES_WEAK_CHANCE:
			_acquire_weak()
		if rng.randf() < WET_CLOTHES_STRESS_CHANCE:
			add_stress_cause("WET_CLOTHES")
	outfit_changed.emit(item)

## Al salir de la ducha Mayui queda con la toalla hasta que vaya al armario.
func wear_towel() -> void:
	wear_clothes(Item.new(load(TOWEL_DATA)))

## Ensucia la ropa puesta (lluvia, comida dificil de comer, lugares sucios...). amount = puntos de limpieza que pierde.
func soil_clothes(amount: float) -> void:
	_change_outfit_condition("cleanliness", -amount)

## Moja la ropa puesta (lluvia...). amount = puntos de humedad que gana (100 = empapada).
func wet_clothes(amount: float = 100.0) -> void:
	_change_outfit_condition("wetness", amount)

func _change_outfit_condition(condition_name: String, delta: float) -> void:
	if outfit == null: return
	var cc : CustomCondition = outfit.get_custom_condition(condition_name)
	if cc == null: return
	cc.value = clampf(cc.value + delta, 0.0, 100.0)
	outfit.update_states()
	outfit_changed.emit(outfit)

func _apply_outfit_sprite() -> void:
	if player == null or outfit == null: return
	var behavior = outfit.data.behavior as ClothBehavior
	if behavior != null and behavior.preset != null:
		player.change_preset(behavior.preset)

## Con el paso del tiempo la ropa puesta se ensucia y se seca. Ropa sucia = el cuerpo se ensucia mas rapido; ropa mojada
## mas de 6 h seguidas = Suciedad.
func _on_clothes_time(delta_minutes: int) -> void:
	if outfit == null or delta_minutes <= 0: return
	var hours : float = delta_minutes / 60.0
	var clean : CustomCondition = outfit.get_custom_condition("cleanliness")
	var wet : CustomCondition = outfit.get_custom_condition("wetness")
	if clean != null:
		clean.value = maxf(0.0, clean.value - CLOTHES_DIRT_PER_HOUR * hours)
	if wet != null and wet.value > 0.0:
		wet.value = maxf(0.0, wet.value - CLOTHES_DRY_PER_HOUR * hours)
	outfit.update_states()
	if outfit.has_state("wet"):
		_wet_minutes += delta_minutes
		if _wet_minutes >= WET_CLOTHES_DIRT_MINUTES and not has_effect("SMELLY"):
			add_effect(load("res://Resources/Effects/Effects/smelly.tres"))
	else:
		_wet_minutes = 0
	if outfit.has_state("dirty"):
		var smelly_event := EventManager.get_event("AUTO_SMELLY_LAPSE") as LapseEvent
		if smelly_event != null:
			smelly_event.check_timer(int(round(delta_minutes * (DIRTY_CLOTHES_BODY_DIRT_RATE - 1.0))))
#endregion
#region Cierre del dia (§6.3)
## Cierra el dia que termino: evalua la Rutina saludable, aplica el balance de cordura y reinicia
## los contadores. Corre a medianoche, ANTES de los chequeos de la manana.
func _close_day() -> void:
	# dentro de day_changed TimeManager.week_day todavia es el dia que termina
	var weekday : int = int(TimeManager.week_day)
	var free_day : bool = weekday >= TimeUtils.WEEKDAY.SABADO
	var items : int = 1   # dinero minimo para comida y deudas: se asume cumplido hasta definir las deudas (P10)
	if daily.home_meals > 0:
		items += 1
	if daily.bathed:
		items += 1
	if last_night_proper:
		items += 1
	var full : bool = items >= 4 or (items == 3 and daily.gambled)   # jugar es comodin
	last_routine_full = full

	if full:
		if has_effect("STRESS"):
			mitigate_stress(1, "ROUTINE")
		elif has_effect("CALM"):
			(get_effect_res("CALM") as EffectLevel).increment_days_active()
		else:
			add_effect(EFFECT_CALM.duplicate())
	elif items <= 1:
		add_stress_cause("DISORDERED_ROUTINE")

	var gain : float = 0.0
	if full:
		gain += SANITY_GAIN_ROUTINE
	if free_day and items >= 2:
		gain += SANITY_GAIN_FREE_DAY
	if weekday == TimeUtils.WEEKDAY.DOMINGO and sanity_value < 50.0:
		gain += SANITY_SUNDAY_PULL * (50.0 - sanity_value)
	if gain > 0.0:
		change_sanity(gain, "DAY_CLOSE")

	var sleepy_level : int = get_sleepy_level()
	if sleepy_level > 0:
		change_sanity(-SLEEPY_SANITY_LOSS[sleepy_level - 1], "SLEEPY")

	daily = _new_daily()
#endregion

#region Chequeos de la manana (§6.1)
## Se corren al despertar (o a medianoche si Mayui sigue despierta), en este orden.
func _run_wake_checks() -> void:
	_wake_checks_pending = false
	# 1) escalada de lo que ya existe
	var stress : EffectLevel = get_effect_res("STRESS") as EffectLevel
	if stress != null:
		stress.increment_days_active()
		_check_level_escalation(stress)
	var calm : EffectLevel = get_effect_res("CALM") as EffectLevel
	if calm != null:
		_check_level_escalation(calm)
	# 2) aparicion o reduccion por cordura (Estres <-> Calma)
	_roll_primary_effect_spawn()
	# 3) insomnio y atenta
	_update_insomnia_days()
	# 4) derivados
	_update_inapetencia()
	_update_hipersomnia()
	# 5) tiradas que dependen del nivel de otro efecto
	_roll_level_dependent_effects()
	# 6) agotamiento -> debilitamiento
	var energy : float = get_stat_value("ENERGY")
	if energy > 0.0 and energy <= 15.0 and not has_effect("WEAK") and rng.randf() < WEAK_FROM_TIRED_CHANCE:
		_acquire_weak()

## Reduce 1 nivel de un primario, o lo quita si estaba en el nivel I.
func _reduce_or_remove_primary_effect(effect: EffectLevel) -> void:
	if effect.level <= 0:
		var effect_name : String = effect.effect_unique_name
		var should_grant_opposite : bool = primary_reached_lv3.get(effect_name, false)
		remove_effect(effect_name)
		primary_reached_lv3[effect_name] = false
		if should_grant_opposite:
			_grant_opposite_primary_effect(effect_name)
	else:
		effect.change_level_value(effect.level - 1)

## Escalada de los primarios (D9): pasa de nivel si se cumplen los dias Y el umbral de cordura,
## con una tirada del 50 %. Estres: I->II tras 1 dia y cordura <30; II->III tras 2 dias y cordura <20.
## Calma: I->II tras 1 dia con rutina y cordura >70; II->III tras otro y cordura >80.
func _check_level_escalation(effect: EffectLevel) -> void:
	var sanity : float = sanity_value
	if effect.effect_unique_name == "STRESS":
		if effect.level == 0 and effect.days_active >= 1 and sanity < SANITY_STRESS_T2_MAX \
				and rng.randf() < PRIMARY_SPAWN_HIGH_CHANCE:
			effect.change_level_value(1)
		elif effect.level == 1 and effect.days_active >= 2 and sanity < SANITY_STRESS_T3_MAX \
				and rng.randf() < PRIMARY_SPAWN_HIGH_CHANCE:
			effect.change_level_value(2)
			primary_reached_lv3["STRESS"] = true
	elif effect.effect_unique_name == "CALM":
		if effect.level == 0 and effect.days_active >= 1 and sanity > SANITY_CALM_T2_MIN \
				and rng.randf() < PRIMARY_SPAWN_HIGH_CHANCE:
			effect.change_level_value(1)
		elif effect.level == 1 and effect.days_active >= 1 and sanity > SANITY_CALM_T3_MIN \
				and rng.randf() < PRIMARY_SPAWN_HIGH_CHANCE:
			effect.change_level_value(2)
			primary_reached_lv3["CALM"] = true

## Al mitigar por completo un primario que llego al nivel III, aparece una secuela:
## Estres III -> Insomnio (tu tabla); Calma III -> Estres.
func _grant_opposite_primary_effect(removed_effect_name: String) -> void:
	if removed_effect_name == "STRESS" and not has_effect("INSOMNIA"):
		add_effect(EFFECT_INSOMNIA.duplicate())
	elif removed_effect_name == "CALM" and not has_effect("STRESS"):
		add_effect(EFFECT_STRESS.duplicate())

## Aparicion por cordura (tirada diaria). Si ya hay un primario y se cumple la condicion del
## opuesto, el opuesto no se activa y reduce 1 nivel del existente.
func _roll_primary_effect_spawn() -> void:
	var sanity : float = sanity_value
	var p_stress : float = 0.0
	if sanity < SANITY_STRESS_T2_MAX:
		p_stress = PRIMARY_SPAWN_HIGH_CHANCE   # cordura <30 (y <20): 50 %
	elif sanity < SANITY_STRESS_T1_MAX:
		p_stress = PRIMARY_SPAWN_LOW_CHANCE    # cordura <40: 25 %
	var p_calm : float = 0.0
	if sanity > SANITY_CALM_T2_MIN:
		p_calm = PRIMARY_SPAWN_HIGH_CHANCE     # cordura >70 (y >80): 50 %
	elif sanity > SANITY_CALM_T1_MIN:
		p_calm = PRIMARY_SPAWN_LOW_CHANCE      # cordura >60: 25 %

	var stress : EffectLevel = get_effect_res("STRESS") as EffectLevel
	var calm : EffectLevel = get_effect_res("CALM") as EffectLevel
	if calm != null and rng.randf() < p_stress:
		_reduce_or_remove_primary_effect(calm)
	elif stress != null and rng.randf() < p_calm:
		_reduce_or_remove_primary_effect(stress)
	elif stress == null and calm == null:
		if rng.randf() < p_stress:
			add_effect(EFFECT_STRESS.duplicate())
		elif rng.randf() < p_calm:
			add_effect(EFFECT_CALM.duplicate())

func _update_insomnia_days() -> void:
	var insomnia_effect : EffectLevel = get_effect_res("INSOMNIA") as EffectLevel

	# Cordura <30 -> Insomnio
	if insomnia_effect == null and sanity_value < INSOMNIA_TRIGGER_SANITY_MAX:
		add_effect(EFFECT_INSOMNIA.duplicate())
		insomnia_effect = get_effect_res("INSOMNIA") as EffectLevel

	# Sueno III + un dia sin dormir bien -> Insomnio
	if insomnia_effect == null:
		_check_sleepy_insomnia_trigger()
		insomnia_effect = get_effect_res("INSOMNIA") as EffectLevel

	if insomnia_effect == null:
		insomnia_days_active = 0
		return

	insomnia_days_active += 1
	_update_insomnia_level(insomnia_effect)

	# Insomnio + 2 dias -> Atenta, con el mismo nivel que el Insomnio. Atenta e Hipersomnia son opuestas.
	if insomnia_days_active >= 2:
		if has_effect("HIPERSOMNIA"):
			_reduce_internal_effect("HIPERSOMNIA")
		else:
			if not has_effect("ATENTA"):
				add_effect(EFFECT_ATENTA.duplicate())
			_set_internal_level("ATENTA", insomnia_effect.level + 1)

func _update_insomnia_level(insomnia_effect: EffectLevel) -> void:
	var target_level : int = 0
	if sanity_value < INSOMNIA_LEVEL3_SANITY_MAX and insomnia_bad_sleep_days >= INSOMNIA_LEVEL2_MIN_BAD_SLEEP_DAYS:
		target_level = 2
	elif sanity_value < INSOMNIA_TRIGGER_SANITY_MAX and insomnia_bad_sleep_days >= INSOMNIA_LEVEL2_MIN_BAD_SLEEP_DAYS:
		target_level = 1

	if insomnia_effect.level != target_level:
		insomnia_effect.change_level_value(target_level)

## Inapetencia: causada por Cordura <30 o Estres III (50 % por dia). Escala por dias mientras siga la
## causa y se va cuando desaparece.
func _update_inapetencia() -> void:
	var cause : bool = sanity_value < INSOMNIA_TRIGGER_SANITY_MAX or _stress_level() >= 3
	if not cause:
		remove_effect("INAPETENCIA")
	elif not has_effect("INAPETENCIA"):
		if rng.randf() < DERIVED_SPAWN_CHANCE:
			add_effect(EFFECT_INAPETENCIA.duplicate())
			_set_internal_level("INAPETENCIA", 1)
	else:
		_advance_internal_level("INAPETENCIA")

## Hipersomnia: causada por Calma III (50 % por dia). Misma escalada; se va al bajar Calma de III.
func _update_hipersomnia() -> void:
	if _calm_level() < 3:
		remove_effect("HIPERSOMNIA")
	elif not has_effect("HIPERSOMNIA"):
		if has_effect("ATENTA"):
			_reduce_internal_effect("ATENTA")   # opuestos
		elif rng.randf() < DERIVED_SPAWN_CHANCE:
			add_effect(EFFECT_HYPERSOMNIA.duplicate())
			_set_internal_level("HIPERSOMNIA", 1)
	else:
		_advance_internal_level("HIPERSOMNIA")

## Tiradas que dependen del nivel de otro efecto.
func _roll_level_dependent_effects() -> void:
	var inap : int = get_internal_level("INAPETENCIA")
	if inap > 0 and rng.randf() < INAPETENCIA_HUNGER_ROLL[inap - 1]:
		add_effect(load("res://Resources/Effects/Effects/hunger.tres"))
	var hip : int = get_internal_level("HIPERSOMNIA")
	if hip > 0 and rng.randf() < HIPERSOMNIA_SLEEPY_ROLL[hip - 1] and not has_effect("SLEEPY"):
		_apply_sleepy(SLEEP_DEBT_VIGIL)
	var ate : int = get_internal_level("ATENTA")
	if ate > 0 and rng.randf() < ATENTA_HYPERACTIVE_ROLL[ate - 1]:
		apply_timed_hyperactive("ATENTA")
	var stress_level : int = _stress_level()
	if stress_level > 0 and rng.randf() < STRESS_HYPERACTIVE_ROLL[stress_level - 1]:
		apply_timed_hyperactive("STRESS")
#endregion

func _on_effect_removed(effect: Effect) -> void:
	internal_levels.erase(effect.effect_unique_name)
	_internal_days.erase(effect.effect_unique_name)

	if effect.effect_unique_name == "INSOMNIA":
		insomnia_days_active = 0
		insomnia_bad_sleep_days = 0
		insomnia_proper_sleep_streak = 0
		if has_effect("ATENTA"):
			remove_effect("ATENTA")

	if effect.effect_unique_name == "HYPERACTIVE":
		hyperactive_timed = false
		_reset_hyperactive_stack()

	if effect.effect_unique_name == "ATENTA":
		atenta_from_cold_water = false

	if effect.effect_unique_name == "STRESS" or effect.effect_unique_name == "CALM":
		primary_reached_lv3[effect.effect_unique_name] = false

func _is_primary_effect_name(effect_name: String) -> bool:
	return effect_name == "STRESS" or effect_name == "CALM"

func _get_opposite_primary_name(effect_name: String) -> String:
	if effect_name == "STRESS":
		return "CALM"
	if effect_name == "CALM":
		return "STRESS"
	return ""

## Resumen del motor para el panel de depuracion (UI/Debug/debug.gd).
func get_debug_report() -> String:
	var lines : PackedStringArray = []
	lines.append("CORDURA %.1f (piso %.0f) | hoy: perdida %.1f/%.0f, mitigado %d/%d" % [
		sanity_value, sanity_floor, float(daily.sanity_loss), SANITY_LOSS_DAILY_CAP, int(daily.mitigated), MITIGATION_DAILY_CAP])
	var names : PackedStringArray = []
	for e : Effect in effects:
		var label : String = e.effect_unique_name
		if e is EffectLevel:
			label += " " + ["I", "II", "III"][clampi((e as EffectLevel).level, 0, 2)] + "(d%d)" % (e as EffectLevel).days_active
		elif internal_levels.has(e.effect_unique_name):
			label += " " + ["I", "II", "III"][clampi(int(internal_levels[e.effect_unique_name]) - 1, 0, 2)]
		elif e is EffectHourControl:
			label += " " + (e as EffectHourControl).time + " (nivel " + str(get_sleepy_level()) + ")"
		names.append(label)
	lines.append("EFECTOS: " + (" . ".join(names) if not names.is_empty() else "ninguno"))
	lines.append("HOY: comidas caseras %d | bano %s | juego %s | calle %d" % [
		int(daily.home_meals), "si" if daily.bathed else "no", "si" if daily.gambled else "no", int(daily.street_events)])
	lines.append("NOCHE ANTERIOR apropiada: %s | rutina de ayer: %s | deuda oculta %s | puede dormir: %s" % [
		"si" if last_night_proper else "no", "si" if last_routine_full else "no", hour_debt, "no" if slept_today else "si"])
	return "\n".join(lines)

#endregion
