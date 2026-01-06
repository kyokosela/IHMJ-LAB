extends Node

signal effect_added(effect : Effect)
signal effect_removed(effect : Effect)

signal stat_connection_added

@warning_ignore_start("unused_signal")
signal stat_value_changed(stat : Stat, new_value : float)

enum CONNECTION_PARAM {
	SIGNAL,
	CALLABLE,
	FLAGS
}

const ENERGY_EFFECTS : Dictionary[String, Effect] = {
	"hyperactive" : preload("res://Resources/Effects/Effects/hyperactive.tres"),
	"tired" : preload("res://Resources/Effects/Effects/tired.tres")
}

const STATS_FOLDER_PATH : String = "res://Resources/Stats/stats/"

var stats : Array[Stat]
var effects : Array[Effect]
var mood_value : float = 50.0
var money : int = 250

enum MOOD_STATES {
	HAPPY,
	NORMAL,
	BAD
}

#region LOGIC

func _ready() -> void:
	load_default_stats()

#recorre el recurso que contiene las stats y carga su valor
func load_default_stats() -> void :
	for stat_res in DirAccess.get_files_at(STATS_FOLDER_PATH):
		if not stat_res.ends_with("tres") and not stat_res.ends_with("res"):
			continue
		stats.append(load(STATS_FOLDER_PATH + stat_res))
	
	connect_to_stat("ENERGY", auto_energy_effects)

func auto_energy_effects(_new_value : float) -> void :
	if _new_value <= 1 :
		#TODO algo, el desmayo o algo creo aqui va esa monda
		return
	
	if _new_value <= 15 :
		add_effect(ENERGY_EFFECTS.tired)
		clear_energy_effects(ENERGY_EFFECTS.tired.effect_unique_name)
		return
	
	if _new_value >= 90 :
		add_effect(ENERGY_EFFECTS.hyperactive)
		clear_energy_effects(ENERGY_EFFECTS.hyperactive.effect_unique_name)
		return

func clear_energy_effects(_exception : String) : 
	for x in ENERGY_EFFECTS : if ENERGY_EFFECTS[x].effect_unique_name != _exception : remove_effect(ENERGY_EFFECTS[x].effect_unique_name)

#con la variable modifier, modifica el valor de cada stat recorriendo su recurso que se obtuvo antes
func apply_effects(_effect_name : String = "") -> void:
	for stat in stats:
		stat.value += stat_change_total(stat.stat_unique_name)

func stat_change_total(unique_stat_name: String) -> float:
	var total : float = 0
	for effect in effects:
		total += effect.stat_change_total(unique_stat_name)
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

func get_stat_connections(unique_stat_name : String, connection_parameter: CONNECTION_PARAM = CONNECTION_PARAM) -> Array:
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

func get_mood_state() -> MOOD_STATES : ## Obten el estado mental del jugador, ENUM MOOD_STATES, ejemplo MOOD_STATES.SAD
	return MOOD_STATES[MOOD_STATES.keys()[mood_value / MOOD_STATES.size()]]

func decrease_stat(unique_stat_name : String, value : float) -> void : ## Disminuye una estadistica, usa el nombre unico/identificador
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null or not stat: 
		return
	stat.value -= value

func increase_stat(unique_stat_name : String, value : float) -> void : ## Aumenta una estadistica, usa el nombre unico/identificador
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null or not stat: 
		return
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
