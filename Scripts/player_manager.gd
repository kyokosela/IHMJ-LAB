extends Node

signal effect_added(effect : Effect)
signal effect_removed(effect : Effect)

signal stat_connection_added

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
var sanity_value : float = 50.0
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
		"tired" : load("res://Resources/Effects/Effects/tired.tres")
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
			PlayerManager.add_effect(load("res://Resources/Effects/Effects/hunger.tres"))
			hungry_energy_log -= hungry_energy
	

func auto_energy_effects(_new_value : float) -> void :
	"""
	ESTE SCRIPT DISPARA :
		topes:
		cansacion/tired cuando la energia es menor a 15
		hiperactiva cuando la energia es superior a 90
		
		lapsos:
		hambre cada 120 de energia gastado
	"""

	if _new_value >= 90 :
		add_effect(energy_effects.hyperactive)
		clear_energy_effects(energy_effects.hyperactive.effect_unique_name)
	elif _new_value <= 0 :
		TransitionManager.fadeIn(5)
		await TransitionManager.transition_finished
		TimeManager.add_to_current_time("08:00")
		TransitionManager.fadeOut(5)
		await TransitionManager.transition_finished
		## TODO aplicar efecto debilitambiento
		
	elif _new_value <= 15 :
		add_effect(energy_effects.tired)
		clear_energy_effects(energy_effects.tired.effect_unique_name)
	
	
	clear_energy_effects("")

func clear_energy_effects(_exception : String) : 
	for x in energy_effects : 
		if energy_effects[x].effect_unique_name != _exception : 
			remove_effect(energy_effects[x].effect_unique_name)

#con la variable modifier, modifica el valor de cada stat recorriendo su recurso que se obtuvo antes
func apply_effects(_effect_name : String = "") -> void:
	for stat in stats:
		stat.value = get_stat_change_total(stat.stat_unique_name)

func get_stat_change_total(unique_stat_name: String) -> float:
	var total : float = 0
	for effect in effects:
		total += effect.stat_change_total(unique_stat_name)
	return total

func get_cost_with_effects(unique_stat_name: String, _custom_num : float = 0) -> float :
	var total : float = _custom_num
	for effect in effects:
		total = effect.get_stat_change_total(unique_stat_name, _custom_num)
	return total

#endregion

#region EFFECTS API

func add_effect(effect : Effect) -> void :
	if has_effect(effect.effect_unique_name) :
		# TODO probablemente manejo de niveles, no puede ser una variable de level por si acaso, usa el nombre unico/identificador
		return
	else :
		effect_added.emit(effect)
		effects.append(effect)
		if effect is TemporalEffect :
			TimeManager.connect_with_res(effect.duration, remove_effect.bind(effect.effect_unique_name))
	
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

#endregion

#region STATS API

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
