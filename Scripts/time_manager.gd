extends Node

const DAY_MINUTES : int = 1440

enum TIMES {HOUR,MINUTE}

signal day_changed(day_value : int) ## se emite cuando el dia cambia
signal time_changed(time_value : int) ## se emite cuando el tiempo cambia

var day : int = 0 :
	set(_value) : 
		day = _value
		day_changed.emit(day)
		
var minutes : int = 0 :
	set(_value) :
		minutes = _value
		time_changed.emit(minutes)
		if minutes >= DAY_MINUTES:
			day +=1
			minutes = 0

#region API

## Obtiene el [b]tiempo actual[/b] con el formato HH:MM
func get_current_time() -> String :
	var hour : float = minutes / 60.0
	var minute : float = fmod(minutes,60)
	return "%02d:%02d" % [hour, minute]

## Establece el tiempo actual del juego, [b]con el formato HH:MM[/b]
func set_current_time(_target_time : String) -> void : 
	var times : int = get_minutes(_target_time)
	minutes = times

## [b]Suma[/b] el tiempo establecido al tiempo actual del juego
func add_to_current_time(_nest_time : String) -> void :
	var times : int = get_minutes(_nest_time)
	minutes += times

## Comprueba con el parametro si el tiempo establecido es superior al tiempo actual del juego
func is_time_higher(_query_time : String) -> bool :
	var times : int = get_minutes(_query_time)
	return times > minutes

## Comprueba con el parametro si el tiempo establecido es inferior al tiempo actual del juego
func is_time_lower(_query_time : String) -> bool :
	var times : int = get_minutes(_query_time)
	return times < minutes

	## Comprueba si el tiempo actual del juego esta dentro del rango start y end
func is_time_between(_query_start_time : String, _query_end_time : String) -> bool :
	var start_query_minutes : int = get_minutes(_query_start_time)
	var end_query_minutes : int = get_minutes(_query_end_time)
	
	return minutes >= start_query_minutes and minutes <= end_query_minutes

#endregion

#region tools

## Valida si el formato "HH:MM" es correcto
func is_valid_time(time_formated : String) -> bool :
	var splitted : PackedStringArray = time_formated.split(":")
	if splitted.size() < 1 : return false
	if splitted[TIMES.HOUR].length() != 2 or splitted[TIMES.MINUTE].length() != 2 : return false
	return true

func get_time_values(_custom_target_time : String = get_current_time()) -> Array[int] :
	if is_valid_time(_custom_target_time) : 
		var splitted : PackedStringArray = _custom_target_time.split(":")
		var hour : int = int(splitted[TIMES.HOUR])
		var minute : int = int(splitted[TIMES.MINUTE])
		return [hour, minute]
	return []

func get_minutes(_query_time : String = get_current_time()) -> int :
	var times = get_time_values(_query_time)
	if times.is_empty() : return -1
	times[0] = times[0] * 60
	return times[0] + times[1]

func substract_to_current_time(_nest_time : String) -> void :
	var times : Array[int] = get_time_values(_nest_time)
	minutes -= (times[TIMES.HOUR] + times[TIMES.MINUTE])

#endregion
