extends Event
class_name EventScheduled

@export_category("setup scheduled")
@export var day : int
@export var month : int
@export_range(0,59,1) var hour : int # no deberia ser 24? asdjk ola
@export_range(-1,59,1) var end_hour : int
@export_range(0,59,1) var minute : int
@export_range(-1,59,1) var end_minute : int

func get_formated_end() -> String :
	var time = (end_hour * 60) +  end_minute
	return TimeManager.format_minutes(time)

func get_formated_start() -> String :
	var time = (hour * 60) +  minute
	return TimeManager.format_minutes(time)
