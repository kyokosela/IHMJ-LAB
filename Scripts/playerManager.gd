extends Node

const STATS_FOLDER_PATH : String = "res://Resources/Stats/stats/"

var stats : Array[Stat]
var effects : Array[Effect]
var mood_value : float = 50.0
var money : int = 1000

enum MOOD_STATES {
	HAPPY,
	NORMAL,
	BAD
}

#region LOGIC

func _ready() -> void:
	load_default_stats()
	print(stats)

func load_default_stats() -> void :
	for stat_res in DirAccess.get_files_at(STATS_FOLDER_PATH) :
		stats.append(load(STATS_FOLDER_PATH + stat_res))

#endregion

#region EFFECTS API

func add_effect(effect : Effect) -> void :
	if has_effect(effect.effect_unique_name) :
		##TODO probablemente manejo de niveles, no puede ser una variable de level por si acaso, usa el nombre unico/identificador
		pass
	else :
		effects.append(effect)
	
func remove_effect(unique_effect_name : String) -> void : ## Remueve un efecto, usa el nombre unico/identificador
	var effect : Effect = get_effect_res(unique_effect_name)
	if effect == null : return
	effects.erase(effect)

func has_effect(unique_effect_name : String) -> bool : ## Devuelve verdadero si el efecto existe, usa el nombre unico/identificador
	var effect : Effect = get_effect_res(unique_effect_name)
	if effect == null : return false
	return effects.has(effect)

func get_effect_value(unique_effect_name : String) -> float : ## Obten el valor de un efecto, usa el nombre unico/identificador
	var effect : Effect = get_effect_res(unique_effect_name)
	if effect == null : return -1.0
	return effect.value

func get_effect_res(unique_effect_name : String) -> Effect : ## Obten el recurso tipo efecto, usa el nombre unico/identificador
	for effect : Effect in effects :
		if effect.effect_unique_name == unique_effect_name :
			return effect
	return null

#endregion

#region STATS API

func connect_to_stat(unique_stat_name : String, callable : Callable) -> void : ## Conecta una funcion al cambio de una estadistica, usa el nombre unico/identificador, Esta señal retornara el valor nuevo de la estadistica
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null : return
	stat.value_changed.connect(callable)

func get_mood_state() -> MOOD_STATES : ## Obten el estado mental del jugador, ENUM MOOD_STATES, ejemplo MOOD_STATES.SAD
	return MOOD_STATES[MOOD_STATES.keys()[mood_value / MOOD_STATES.size()]]

func decrease_stat(unique_stat_name : String, value : float) -> void : ## Disminuye una estadistica, usa el nombre unico/identificador
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null : return
	stat.value -= value

func increase_stat(unique_stat_name : String, value : float) -> void : ## Aumenta una estadistica, usa el nombre unico/identificador
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null : return
	stat.value += value

func get_stat_res(unique_stat_name : String) -> Stat : ## Obten el recurso tipo Stat, usa el nombre unico/identificador
	for stat : Stat in stats :
		if stat.stat_unique_name == unique_stat_name :
			return stat
	return null

func get_stat_value(unique_stat_name : String) -> float : ## Obten el valor de una Stat, usa el nombre unico/identificador
	var stat : Stat = get_stat_res(unique_stat_name)
	if stat == null : return -1.0
	return stat.value

#endregion
