extends Node
class_name TimeUtils

enum WEEKDAY {
	LUNES,
	MARTES,
	MIERCOLES,
	JUEVES,
	VIERNES,
	SABADO,
	DOMINGO
}

enum MONTHS {
	ENERO,
	FEBRERO,
	MARZO,
	ABRIL,
	MAYO,
	JUNIO,
	JULIO,
	AGOSTO,
	SEPTIEMBRE,
	OCTUBRE,
	NOVIEMBRE,
	DICIEMBRE
}

static func increase_time(time : String, addition_time : String) -> String :
	if !is_valid_format(time) : return time
	var time_val = get_minutes(time)
	var addition_time_val = get_minutes(addition_time)
	
	var res = time_val + addition_time_val
	return TimeManager.format_minutes(res)

static func decrease_time(time : String, substract_time : String) -> String :
	if !is_valid_format(time) : return time
	var time_val = get_minutes(time)
	var new_substract_time_val = get_minutes(substract_time)
	
	var res = time_val - new_substract_time_val
	return TimeManager.format_minutes(res)

static func is_valid_format(time : String) -> bool :
	var splitted : PackedStringArray = time.split(":")
	if splitted.size() <= 1 : return false
	if splitted[0].length() != 2 or splitted[1].length() != 2 : return false
	return true

static func get_minutes(time : String) -> int :
	var times = TimeManager.get_time_values(time)
	if times.is_empty() : return -1
	times[0] = times[0] * 60
	return times[0] + times[1]
