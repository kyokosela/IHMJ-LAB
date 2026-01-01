extends Node

const DAY_MINUTES : int = 1440

enum TIMES {HOUR,MINUTE}

signal time_changed(months : int, week: int, day: int, minutes: int)

signal minutes_changed(time_value : int) ## se emite cuando el tiempo cambia
signal day_changed(day_value : int) ## se emite cuando el dia cambia
signal week_changed(week_value : int) ## se emite cada vez que la semana cambia, automaticamente los dias 7
signal month_changed(month_value : int) ## se emite cada vez que el mes cambia, automaticamente los dias 30

var julian_day = 0
var scheduled_times : Dictionary[ScheduleConfig, Callable]

var day : int = 1 :
	set(_value) : 
		day = _value
		day_changed.emit(day)
		if week_day == TimeUtils.WEEKDAY.DOMINGO: week += 1
		if day == 30:
			day = 0
			week = 0
			month += 1

var minutes : int = 0:
	set(_value) :
		minutes = clamp(_value, 0 , DAY_MINUTES)
		minutes_changed.emit(minutes)
		if minutes >= DAY_MINUTES:
			day +=1
			julian_day += 1
			minutes = 0
		time_changed.emit(month,week,day,minutes)

var week : int = 1:
	set(_value):
		week = _value
		week_changed.emit(week)

var week_day : TimeUtils.WEEKDAY = TimeUtils.WEEKDAY.LUNES:
	get: return julian_day % 7 as TimeUtils.WEEKDAY

var month : TimeUtils.MONTHS = TimeUtils.MONTHS.JUNIO :
	set(_value) :
		month = _value
		month_changed.emit(_value)

var year : int = 2026
#region logic

func _ready() -> void:
	week_changed.connect(func(_r): print("week changed: ", _r))
	minutes_changed.connect(check_scheduled_times)

func check_scheduled_times(months : TimeUtils.MONTHS, week: int, day: int, minutes: int) -> void :
	for x : ScheduleConfig in scheduled_times:
		if scheduled_times.
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
	assert(TimeUtils.is_valid_format(_target_time), "Time should have a valid format")
	var times : int = get_minutes(_target_time)
	minutes = times
 
## Comprueba con el parametro si el tiempo establecido es superior al tiempo actual del juego
func is_time_higher(_query_time : String) -> bool:
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var times : int = get_minutes(_query_time)
	print("comparando ", minutes, " con ", times, " da ", times > minutes)
	return times > minutes

## Comprueba con el parametro si el tiempo establecido es el mismo al tiempo actual del juego
func is_equal_time(_query_time : String) -> bool :
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var times : int = get_minutes(_query_time)
	return times == minutes

## Comprueba con el parametro si el tiempo establecido es inferior al tiempo actual del juego
func is_time_lower(_query_time : String) -> bool :
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var times : int = get_minutes(_query_time)
	return times < minutes

## Comprueba si el tiempo actual del juego esta dentro del rango start y end
func is_time_between(_query_start_time : String, _query_end_time : String) -> bool :
	assert(TimeUtils.is_valid_format(_query_start_time), "Time should have a valid format")
	var start_query_minutes : int = get_minutes(_query_start_time)
	var end_query_minutes : int = get_minutes(_query_end_time)
	return minutes >= start_query_minutes and minutes <= end_query_minutes
	
## Conecta una funcion a un tiempo establecido, se ejecutara en cuanto sea superior
func connect_to_time(_query_time : String, callable : Callable) -> void :
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	scheduled_times[_query_time] = callable

func connect_to_weekday(_query_week : TimeUtils.WEEKDAY,callable : Callable,_query_hour : String = "00", _query_minute : String = "00") -> void:
	var _query_time : String = _query_hour +":"+_query_minute
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	
	

## Retorna el tiempo restante para un tiempo objetivo
func time_left_to(_query_time : String) -> String :
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var minute = get_minutes(_query_time)
	var left_time = minutes - minute
	return format_minutes(left_time)

func get_week_day() -> String :
	return TimeUtils.WEEKDAY.find_key(week_day)
#endregion

#region tools


func get_time_values(_custom_target_time : String = get_current_time()) -> Array[int] :
	if TimeUtils.is_valid_format(_custom_target_time) : 
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
	assert(TimeUtils.is_valid_format(_nest_time), "Time should have a valid format")
	var times : int = get_minutes(_nest_time)
	minutes += times

func substract_to_current_time(_nest_time : String) -> void :
	assert(TimeUtils.is_valid_format(_nest_time), "Time should have a valid format")
	var times : int = get_minutes(_nest_time)
	minutes -= times
#endregion
