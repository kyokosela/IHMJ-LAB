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
	

func auto_energy_effects(_new_value : float) -> void :
	var nothing : bool = true
	if _new_value >= 90 :
		add_effect(energy_effects.hyperactive)
		clear_energy_effects(energy_effects.hyperactive.effect_unique_name)
		nothing = false
	elif _new_value <= 0 :
		nothing = false
		sleep()
		add_effect(load("res://Resources/Effects/Effects/weak.tres"))
	elif _new_value <= 15 :
		nothing = false
		add_effect(energy_effects.tired)
		clear_energy_effects(energy_effects.tired.effect_unique_name)
	
	
	if nothing : clear_energy_effects("")

func clear_energy_effects(_exception : String) : 
	for x in energy_effects : 
		if energy_effects[x].effect_unique_name != _exception : 
			remove_effect(energy_effects[x].effect_unique_name)

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
	return total

func get_time_cost_with_effects(base_time: String) -> String:
	if not TimeUtils.is_valid_format(base_time):
		return base_time

	var adjusted_time : String = base_time

	for effect in effects:
		if effect.time_changes != null and effect.time_changes.OPERATION == TimeChanger.OPERATION_CASE.MULTIPLIER:
			var time_factor : float = maxf(0.0, 1.0 + effect.time_changes.time_value)
			adjusted_time = TimeUtils.multiply_time(adjusted_time, time_factor)

		if effect is EffectLevel:
			var level_effect : EffectLevel = effect as EffectLevel
			var level_time_factor : float = maxf(0.0, 1.0 + level_effect.get_time_cost_multiplier())
			adjusted_time = TimeUtils.multiply_time(adjusted_time, level_time_factor)

	return adjusted_time

func get_street_risk_chance(base_chance: float) -> float:
	var chance : float = clampf(base_chance, 0.0, 1.0)

	if has_effect("ATENTA"):
		chance *= STREET_RISK_ATENTA_MULTIPLIER

	if has_effect("HIPERSOMNIA"):
		chance *= STREET_RISK_HYPERSOMNIA_MULTIPLIER

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

func sleep(hour_deal : String = "00:00", bed_type: int = BED_TYPE.TYPE_C) -> void :
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
	
	if !has_effect("SLEEPY") and !has_effect("INSOMNIA") : 
		hour_debt = TimeUtils.increase_time(hour_debt, TimeUtils.decrease_time(minimun_hours, actual_sleep))
	
	var base_energy : float = _get_base_energy_for_hours(actual_sleep)
	var energy_deal : float = base_energy * _get_bed_energy_multiplier(bed_type)

	TransitionManager.fadeIn(3)
	await TransitionManager.transition_finished
	TimeManager.add_to_current_time(actual_sleep)
	TransitionManager.fadeOut(3)
	
	increase_stat("ENERGY", energy_deal)
	_apply_sleep_stress_reduction(bed_type)
	if !has_effect("INSOMNIA") :
		decrease_control_effect_hour("SLEEPY", actual_sleep)
	else:
		_register_insomnia_sleep_quality(minimun_hours, actual_sleep)

	if !has_effect("INSOMNIA") and !TimeUtils.is_greater_or_equal(minimun_hours, actual_sleep):
		add_effect(EFFECT_INSOMNIA.duplicate())
	EventManager.reset_lapse_event("AUTO_SLEEPY_LAPSE")
	
	if TimeUtils.is_greater_or_equal("06:00", hour_debt) and !has_effect("SLEEPY") and !has_effect("INSOMNIA"): # las 6 horas indican cuanto se debe acumular para aplicar sueño
		add_effect(load("res://Resources/Effects/Effects/sleepy.tres"))
		var sleepy : EffectHourControl = get_effect_res("SLEEPY")
		sleepy.time = hour_debt
		hour_debt = "00:00"
		
	
	await TransitionManager.transition_finished

func _roll_insomnia_sleep_cap(insomnia_level: int) -> String:
	var range := _get_insomnia_sleep_range(insomnia_level)
	var random_hours : int = randi_range(range.x, range.y)
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

func _apply_sleep_stress_reduction(bed_type: int) -> void:
	## Deterministic stress reduction on sleep.
	## Design: base -8% + bed bonus (A: +6%, B: +2%, C: +0%).
	## Mapped to STRESS effect levels: always attempt to reduce 1 level.
	## Floor rule: if worked today, cannot remove STRESS entirely (keeps Lv1 minimum).
	var stress_effect : EffectLevel = get_effect_res("STRESS") as EffectLevel
	if stress_effect == null:
		return

	var worked_today : bool = AttendanceManager.arrived_today

	# Floor rule: if worked today and at Lv1, do not remove
	if worked_today and stress_effect.level <= 0:
		return

	# At Lv1 and did not work today -> remove entirely
	if stress_effect.level <= 0:
		remove_effect("STRESS")
		return

	# Reduce by 1 level
	stress_effect.change_level_value(stress_effect.level - 1)

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
	var sleepy_effect : EffectLevel = get_effect_res("SLEEPY") as EffectLevel
	if sleepy_effect == null:
		return
	
	if sleepy_effect.level >= SLEEPY_LEVEL3_FOR_INSOMNIA and insomnia_bad_sleep_days >= 1:
		if not has_effect("INSOMNIA"):
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

#region PRIMARY EFFECTS (STRESS / CALM)

## Called daily to handle primary effect spawning, escalation, and probability checks
func _on_day_changed_primary_effects(_day: int) -> void:
	_update_insomnia_days()

	var sanity : float = sanity_value
	var stress_effect : EffectLevel = get_effect_res("STRESS") as EffectLevel
	var calm_effect : EffectLevel = get_effect_res("CALM") as EffectLevel
	
	# Determine what the sanity level wants to trigger
	var wants_stress : bool = sanity < SANITY_STRESS_T1_MAX
	var wants_calm : bool = sanity > SANITY_CALM_T1_MIN
	
	# Case 1: STRESS is active
	if stress_effect != null:
		if wants_calm:
			# Sanity is high but STRESS is active -> reduce STRESS
			_reduce_or_remove_primary_effect(stress_effect)
		elif wants_stress:
			# Sanity still low -> escalate STRESS
			stress_effect.increment_days_active()
			_check_level_escalation(stress_effect)
			_roll_lv3_secondary_effect(stress_effect)
		# If neutral zone, STRESS just persists (no change)
		return
	
	# Case 2: CALM is active
	if calm_effect != null:
		if wants_stress:
			# Sanity is low but CALM is active -> reduce CALM
			_reduce_or_remove_primary_effect(calm_effect)
		elif wants_calm:
			# Sanity still high -> escalate CALM
			calm_effect.increment_days_active()
			_check_level_escalation(calm_effect)
			_roll_lv3_secondary_effect(calm_effect)
		# If neutral zone, CALM just persists (no change)
		return
	
	# Case 3: Neither effect active -> roll for probability-based spawn
	_roll_primary_effect_spawn()

## Reduce a primary effect by 1 level, or remove it if at Lv1
func _reduce_or_remove_primary_effect(effect: EffectLevel) -> void:
	if effect.level <= 0:
		# At Lv1, remove entirely
		var effect_name : String = effect.effect_unique_name
		var should_grant_opposite : bool = primary_reached_lv3.get(effect_name, false)
		remove_effect(effect.effect_unique_name)
		primary_reached_lv3[effect_name] = false
		if should_grant_opposite:
			_grant_opposite_primary_effect(effect_name)
	else:
		# Reduce level
		effect.change_level_value(effect.level - 1)

## Check if a level effect should escalate based on days active
func _check_level_escalation(effect: EffectLevel) -> void:
	# Escalation rules from design doc:
	# Lv1 -> Lv2: after 1 day
	# Lv2 -> Lv3: after 2 more days
	var current_level : int = effect.level
	var days : int = effect.days_active
	
	if current_level == 0 and days >= 1:
		# Lv1 -> Lv2
		effect.change_level_value(1)
	elif current_level == 1 and days >= 2:
		# Lv2 -> Lv3
		effect.change_level_value(2)
		primary_reached_lv3[effect.effect_unique_name] = true
	# Lv3 is max, no further escalation

func _roll_lv3_secondary_effect(primary_effect: EffectLevel) -> void:
	if primary_effect.level < 2:
		return

	var spawn_chance : float = LV3_STRESS_SECONDARY_SPAWN_CHANCE if primary_effect.effect_unique_name == "STRESS" else LV3_CALM_SECONDARY_SPAWN_CHANCE
	var roll : float = randf()
	if roll > spawn_chance:
		return

	if primary_effect.effect_unique_name == "STRESS" and not has_effect("INAPETENCIA"):
		add_effect(EFFECT_INAPETENCIA.duplicate())
	elif primary_effect.effect_unique_name == "CALM" and not has_effect("HIPERSOMNIA"):
		add_effect(EFFECT_HYPERSOMNIA.duplicate())

func _grant_opposite_primary_effect(removed_effect_name: String) -> void:
	if removed_effect_name == "STRESS" and not has_effect("CALM"):
		add_effect(EFFECT_CALM.duplicate())
	elif removed_effect_name == "CALM" and not has_effect("STRESS"):
		add_effect(EFFECT_STRESS.duplicate())

func _update_insomnia_days() -> void:
	var insomnia_effect : EffectLevel = get_effect_res("INSOMNIA") as EffectLevel

	# Trigger insomnia from low sanity if not active (design: Cordura < 30%)
	if insomnia_effect == null and sanity_value < INSOMNIA_TRIGGER_SANITY_MAX:
		add_effect(EFFECT_INSOMNIA.duplicate())
		insomnia_effect = get_effect_res("INSOMNIA") as EffectLevel

	# Trigger insomnia from SLEEPY III + bad sleep day
	if insomnia_effect == null:
		_check_sleepy_insomnia_trigger()
		insomnia_effect = get_effect_res("INSOMNIA") as EffectLevel

	if insomnia_effect == null:
		insomnia_days_active = 0
		return

	insomnia_days_active += 1
	_update_insomnia_level(insomnia_effect)

	if insomnia_days_active >= 2 and not has_effect("ATENTA"):
		add_effect(EFFECT_ATENTA.duplicate())

func _update_insomnia_level(insomnia_effect: EffectLevel) -> void:
	var target_level : int = 0
	if sanity_value < INSOMNIA_LEVEL3_SANITY_MAX and insomnia_bad_sleep_days >= INSOMNIA_LEVEL2_MIN_BAD_SLEEP_DAYS:
		target_level = 2
	elif sanity_value < INSOMNIA_TRIGGER_SANITY_MAX and insomnia_bad_sleep_days >= INSOMNIA_LEVEL2_MIN_BAD_SLEEP_DAYS:
		target_level = 1

	if insomnia_effect.level != target_level:
		insomnia_effect.change_level_value(target_level)

func _on_effect_removed(effect: Effect) -> void:
	if effect.effect_unique_name == "INSOMNIA":
		insomnia_days_active = 0
		insomnia_bad_sleep_days = 0
		insomnia_proper_sleep_streak = 0
		if has_effect("ATENTA"):
			remove_effect("ATENTA")

	if effect.effect_unique_name == "HYPERACTIVE":
		_reset_hyperactive_stack()

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

## Roll probability to spawn STRESS or CALM based on current sanity
func _roll_primary_effect_spawn() -> void:
	var sanity : float = sanity_value
	
	# Determine which effect to potentially spawn and at what probability
	var effect_to_spawn : Effect = null
	var probability : float = 0.0
	
	# STRESS spawns when sanity is LOW
	if sanity < SANITY_STRESS_T3_MAX:
		effect_to_spawn = EFFECT_STRESS
		probability = PRIMARY_SPAWN_HIGH_CHANCE
	elif sanity < SANITY_STRESS_T2_MAX:
		effect_to_spawn = EFFECT_STRESS
		probability = PRIMARY_SPAWN_HIGH_CHANCE
	elif sanity < SANITY_STRESS_T1_MAX:
		effect_to_spawn = EFFECT_STRESS
		probability = PRIMARY_SPAWN_LOW_CHANCE
	# CALM spawns when sanity is HIGH
	elif sanity > SANITY_CALM_T3_MIN:
		effect_to_spawn = EFFECT_CALM
		probability = PRIMARY_SPAWN_HIGH_CHANCE
	elif sanity > SANITY_CALM_T2_MIN:
		effect_to_spawn = EFFECT_CALM
		probability = PRIMARY_SPAWN_HIGH_CHANCE
	elif sanity > SANITY_CALM_T1_MIN:
		effect_to_spawn = EFFECT_CALM
		probability = PRIMARY_SPAWN_LOW_CHANCE
	
	# No spawn if sanity is in neutral zone (40-60)
	if effect_to_spawn == null:
		return
	
	# Roll the dice
	var roll : float = randf()
	if roll <= probability:
		add_effect(effect_to_spawn.duplicate())

#endregion
