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

var money : int = 250

enum SANITY_STATES {
	DOCILE,
	NEUTRAL,
	DISTURBED
}

#region LOGIC

func _ready() -> void:
	player = load("res://Prefabs/Player/Player.tscn").instantiate()
	add_child(player)
	load_default_stats()
	
	energy_effects = {
		"hyperactive" : load("res://Resources/Effects/Effects/hyperactive.tres"),
		"tired" : load("res://Resources/Effects/Effects/tired.tres"),
	}
	stat_decrease.connect(energy_spend_handler)

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
	if effect.

func decrease_level_effect(unique_effect_name : String, _value : int) -> void : ## Disminuye el nivel de un efecto de tipo nivel
	var effect = get_effect_res(unique_effect_name)
	if effect is EffectLevel :
		effect.change_level_value(effect.level + 1)
	else : return

func increase_level_effect(unique_effect_name : String, _value : int) -> void : ## Aumenta el nivel de un efecto de tipo nivel
	var effect = get_effect_res(unique_effect_name)
	if effect is EffectLevel :
		effect.change_level_value(effect.level - 1)
	else : return

func get_effect_level(unique_effect_name : String) -> String : ## obten el nombre del efecto, sera el nombre de este
	var effect = get_effect_res(unique_effect_name)
	if effect is EffectLevel :
		return tr(effect.get_level_display())
	else : return ""

func get_effect_level_value(unique_effect_name : String) -> float : ## obten el valor numerico del efecto, no empieza en 0
	var effect = get_effect_res(unique_effect_name)
	if effect is EffectLevel :
		return effect.level
	else : return -0.1

func get_cost_with_effects(unique_stat_name: String, _custom_num : float = 0) -> float :
	var total : float = _custom_num
	for effect in effects:
		total = effect.get_stat_change_total(unique_stat_name, _custom_num)
	return total

func add_effect(effect : Effect) -> void :
	if has_effect(effect.effect_unique_name) :
		# TODO probablemente manejo de niveles, no puede ser una variable de level por si acaso, usa el nombre unico/identificador
		return
	else :
		effect_added.emit(effect)
		effects.append(effect)
		
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
	"07:00" : 30,"08:00" : 35,"09:00" : 40,
	"10:00" : 42
}

var hour_debt : String = "00:00"

func sleep(hour_deal : String = "00:00") -> void :
	var minimun_hours : String = "00:00"
	
	var current_energy : float = get_stat_value("ENERGY")

	for r in minimun_hours_ranges:
		if current_energy <= r.energy:
			minimun_hours = r.hours
			break
	
	if TimeUtils.is_greater_or_equal(minimun_hours, hour_deal) :
		
		var debt_pay = TimeUtils.decrease_time(hour_deal, minimun_hours)
		decrease_control_effect_hour("SLEEPY", debt_pay)
		
		hour_deal = minimun_hours
	
	if minimun_hours == "00:00" : return #prevencion de error aunque lo veo imposible
	if hour_deal == "00:00" : hour_deal = minimun_hours
	
	if !has_effect("SLEEPY") and !has_effect("INSOMNIA") : 
		hour_debt = TimeUtils.increase_time(hour_debt, TimeUtils.decrease_time(minimun_hours, hour_deal))
	
	var base_energy = mininum_energy_ranges[minimun_hours]
	var hour_deal_value = TimeUtils.get_minutes(hour_deal)
	var minimun_hour_value = TimeUtils.get_minutes(minimun_hours)
	
	var ratio := float(hour_deal_value) / float(minimun_hour_value)
	ratio = clamp(ratio, 0.0, 1.0)

	var energy_deal = base_energy * ratio

	TransitionManager.fadeIn(3)
	await TransitionManager.transition_finished
	TimeManager.add_to_current_time(hour_deal)
	TransitionManager.fadeOut(3)
	
	increase_stat("ENERGY", energy_deal)
	if !has_effect("INSOMNIA") :
		decrease_control_effect_hour("SLEEPY", hour_deal)
	EventManager.reset_lapse_event("AUTO_SLEEPY_LAPSE")
	
	if TimeUtils.is_greater_or_equal("06:00", hour_debt) and !has_effect("SLEEPY") and !has_effect("INSOMNIA"): # las 6 horas indican cuanto se debe acumular para aplicar sueño
		add_effect(load("res://Resources/Effects/Effects/sleepy.tres"))
		var sleepy : EffectHourControl = get_effect_res("SLEEPY")
		sleepy.time = hour_debt
		hour_debt = "00:00"
		
	
	await TransitionManager.transition_finished
#endregion
