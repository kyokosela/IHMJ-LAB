extends Node

const DAY_MINUTES : int = 1440

enum TIMES {HOUR,MINUTE}

signal day_changed(day_value : int) ## se emite cuando el dia cambia
signal time_changed(time_value : int) ## se emite cuando el tiempo cambia
signal month_changed(month_value : int) ## se emite cada vez que el mes cambia, automaticamente los dias 30

var julian_day = 0
var scheduled_times : Dictionary[String, Callable]

var day : int = 1 :
	set(_value) : 
		day = _value
		day_changed.emit(day)
		if day == 30 :
			day = 0
			month += 1
		
var minutes : int = 0:
	set(_value) :
		minutes = clamp(_value, 0 , DAY_MINUTES)
		time_changed.emit(minutes)
		if minutes >= DAY_MINUTES:
			day +=1
			julian_day += 1
			minutes = 0

var month : int = 6 :
	set(_value) :
		month = _value
		month_changed.emit(_value)

var year : int = 2026

#region logic

func _ready() -> void:
	time_changed.connect(check_scheduled_times)

func check_scheduled_times(_new_time) -> void :
	for x in scheduled_times :
		if is_time_lower(x) or is_equal_time(x):
			scheduled_times[x].call()
			scheduled_times.erase(x)

#endregion

#region API

## Obtiene el [b]tiempo actual[/b] con el formato HH:MM
func get_current_time() -> String :
	return format_minutes(minutes)

## Retorna un tiempo formateado
func format_minutes(_minute : int) -> String :
	var hour : float = _minute / 60.0
	var minute : float = fmod(_minute,60)
	return "%02d:%02d" % [hour, minute]

## Establece el tiempo actual del juego, [b]con el formato HH:MM[/b]
func set_current_time(_target_time : String) -> void:
	assert(is_valid_time(_target_time), "Time should have a valid format")
	var times : int = get_minutes(_target_time)
	minutes = times
 
## Comprueba con el parametro si el tiempo establecido es superior al tiempo actual del juego
func is_time_higher(_query_time : String) -> bool:
	assert(is_valid_time(_query_time), "Time should have a valid format")
	var times : int = get_minutes(_query_time)
	print("comparando ", minutes, " con ", times, " da ", times > minutes)
	return times > minutes

## Comprueba con el parametro si el tiempo establecido es el mismo al tiempo actual del juego
func is_equal_time(_query_time : String) -> bool :
	assert(is_valid_time(_query_time), "Time should have a valid format")
	var times : int = get_minutes(_query_time)
	return times == minutes

## Comprueba con el parametro si el tiempo establecido es inferior al tiempo actual del juego
func is_time_lower(_query_time : String) -> bool :
	assert(is_valid_time(_query_time), "Time should have a valid format")
	var times : int = get_minutes(_query_time)
	return times < minutes

## Comprueba si el tiempo actual del juego esta dentro del rango start y end
func is_time_between(_query_start_time : String, _query_end_time : String) -> bool :
	assert(is_valid_time(_query_start_time), "Time should have a valid format")
	var start_query_minutes : int = get_minutes(_query_start_time)
	var end_query_minutes : int = get_minutes(_query_end_time)
	return minutes >= start_query_minutes and minutes <= end_query_minutes
	
## Conecta una funcion a un tiempo establecido, se ejecutara en cuanto sea superior
func connect_to_time(_query_time : String, callable : Callable) -> void :
	assert(is_valid_time(_query_time), "Time should have a valid format")
	scheduled_times[_query_time] = callable
	
## Retorna el tiempo restante para un tiempo objetivo
func time_left_to(_query_time : String) -> String :
	assert(is_valid_time(_query_time), "Time should have a valid format")
	var minute = get_minutes(_query_time)
	var left_time = minutes - minute
	return format_minutes(left_time)

#endregion

#region tools

## Dejarla sin static para evitar advertencias del motor
## Valida si el formato "HH:MM" es correcto
func is_valid_time(time_formated : String) -> bool :
	var splitted : PackedStringArray = time_formated.split(":")
	if splitted.size() <= 1 : return false
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

## [b]Suma[/b] el tiempo establecido al tiempo actual del juego
func add_to_current_time(_nest_time : String) -> void :
	assert(is_valid_time(_nest_time), "Time should have a valid format")
	var times : int = get_minutes(_nest_time)
	minutes += times

func substract_to_current_time(_nest_time : String) -> void :
	assert(is_valid_time(_nest_time), "Time should have a valid format")
	var times : int = get_minutes(_nest_time)
	minutes -= times
#endregion
