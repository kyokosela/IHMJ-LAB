extends Node

const DAY_MINUTES : int = 1440

enum TIMES {HOUR,MINUTE}

signal time_changed(month : TimeUtils.MONTHS, week: TimeUtils.WEEKDAY, day: int, minutes: int)

signal minutes_changed(time_value : int) ## se emite cuando el tiempo cambia
signal day_changed(day_value : int) ## se emite cuando el dia cambia
signal week_changed(week_value : int) ## se emite cada vez que la semana cambia, automaticamente los dias 7
signal month_changed(month_value : int) ## se emite cada vez que el mes cambia, automaticamente los dias 30

var julian_day = 0
var scheduled_times : Dictionary[ScheduleConfig, Callable]

var day : int = 1 :
	set(_value) : 
		day = day_set_handler(_value)

var minutes : int = 0:
	set(_value) :
		minutes = minutes_set_handler(_value)
		time_changed.emit(month,week_day,day,minutes,week)
	
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
	#connect_to_day(3, func(): print("hola"), "22:00", [TimeUtils.MONTHS.JUNIO, TimeUtils.MONTHS.JULIO])
	time_changed.connect(check_scheduled_times)
	minutes_changed.connect(func(_r): print("Minutes changed: "+ str(_r))) 

func check_scheduled_times(_query_month : TimeUtils.MONTHS, _query_weekday: TimeUtils.WEEKDAY, _query_day: int, _query_minutes: int, _query_week : int) -> void :
	print(scheduled_times)
	for x : ScheduleConfig in scheduled_times:
		print("indice: ", x)
		if !x.month.is_empty() and _query_month not in x.month:
			continue
		print("month verified")
		print("???", x.week_day, " | ", _query_weekday)
		if !x.week_day.is_empty() and _query_weekday not in x.week_day:
			continue
		print("weekday verified")
		if x.day != -1 and x.day != _query_day:
			continue
		print("day verified")
		#TODO en caso de que el auimento de tiempo suba un dia, verificar tambien eso, quizas? no se
		for time in x.times :
			if is_time_lower(time) :
				scheduled_times[x].call()

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
	return times >= minutes

## Comprueba con el parametro si el tiempo establecido es el mismo al tiempo actual del juego
func is_equal_time(_query_time : String) -> bool :
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var times : int = get_minutes(_query_time)
	return times == minutes

## Comprueba con el parametro si el tiempo establecido es inferior al tiempo actual del juego
func is_time_lower(_query_time : String) -> bool :
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var times : int = get_minutes(_query_time)
	print("Current minutes: ",minutes, " Query Minutes: ", times )
	return times <= minutes 

## Comprueba si el tiempo actual del juego esta dentro del rango start y end
func is_time_between(_query_start_time : String, _query_end_time : String) -> bool :
	assert(TimeUtils.is_valid_format(_query_start_time), "Time should have a valid format")
	var start_query_minutes : int = get_minutes(_query_start_time)
	var end_query_minutes : int = get_minutes(_query_end_time)
	return minutes >= start_query_minutes and minutes <= end_query_minutes
	
## Conecta una funcion a un tiempo establecido, se ejecutara en cuanto sea superior
func connect_to_time(_query_time : String, callable : Callable) -> void:
	#hola no se si cambiarlo a que sea modificable los dias semanas etc.
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var schedule_config : ScheduleConfig = ScheduleConfig.new()
	
	schedule_config.time = _query_time
	schedule_config.day = -1
	schedule_config.month = []
	schedule_config.week_day = []
	
	scheduled_times[schedule_config] = callable

func connect_to_day(_query_day : int,callable : Callable, _query_time : String = "00:00", _query_months : Array[TimeUtils.MONTHS] = []):
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var schedule_config : ScheduleConfig = ScheduleConfig.new()
	schedule_config.day = _query_day
	schedule_config.time = _query_time
	schedule_config.month = _query_months
	schedule_config.week_day = []
	
	scheduled_times[schedule_config] = callable
	

func connect_to_weekday(_query_weekday : Array[TimeUtils.WEEKDAY],callable : Callable,_query_time : Array[String],_query_months: Array[TimeUtils.MONTHS]) -> void:
	#assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	
	var schedule_config : ScheduleConfig = ScheduleConfig.new()
	
	schedule_config.week_day = _query_weekday
	schedule_config.day = -1
	schedule_config.times = _query_time
	schedule_config.month = _query_months
	
	scheduled_times[schedule_config] = callable
	

## Retorna el tiempo restante para un tiempo objetivo
func time_left_to(_query_time : String) -> String :
	assert(TimeUtils.is_valid_format(_query_time), "Time should have a valid format")
	var minute = get_minutes(_query_time)
	var left_time = minutes - minute
	return format_minutes(left_time)

func get_week_day_name() -> String :
	return TimeUtils.WEEKDAY.find_key(week_day)

func get_month_name() -> String:
	return TimeUtils.MONTHS.find_key(month)
#endregion

#region Tools

func day_set_handler(_value) -> int:
	var day_value = _value
	if week_day == TimeUtils.WEEKDAY.DOMINGO: week += 1
	if day_value >= 30:
		day_value = 0
		week = 0
		#hay que espeicficar el tipo de valor a pasar como un enum para evitar errores
		month = (month + 1) as TimeUtils.MONTHS
	day_changed.emit(day_value)
	return day_value

func minutes_set_handler(_value) -> int:
	var minute_value = clamp(_value, 0 , DAY_MINUTES)
	if _value >= DAY_MINUTES:
		day +=1
		julian_day += 1
		minute_value = 0
	#manejar el tema de la resta para definir a que hora del dia siguientes establecerlo
	if _value < 0:
		day -=1
		julian_day -= 1
		minute_value = DAY_MINUTES
	#lo mismo de arriba pero alrevez, mayormente para debug
	minutes_changed.emit(minute_value)
	return minute_value


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
