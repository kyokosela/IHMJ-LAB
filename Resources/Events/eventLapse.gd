extends Event
class_name LapseEvent

@export var time_lapse_value : String ## usar el formato HH:MM
@export var auto_restart : bool

var timer_count : String ## usar el formato HH:MM

func check_timer(time_lapse) -> void :
	if timer_count.is_empty() : timer_count = time_lapse_value
	var formated_time : String = TimeManager.format_minutes(time_lapse)
	print(formated_time , " | ", time_lapse)
	timer_count = TimeUtils.decrease_time(timer_count, formated_time)
	if TimeUtils.is_lower_or_equal("00:00", timer_count) :
		if auto_restart : reset_lapse()
		execute()

func reset_lapse() -> void :
	print("RELOAD")
	is_enabled = true
	timer_count = time_lapse_value
