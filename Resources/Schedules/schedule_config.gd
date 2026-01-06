extends Resource
class_name ScheduleConfig

@export var month : Array[TimeUtils.MONTHS]
@export var week_day : Array[TimeUtils.WEEKDAY]
@export var day : int = -1
@export var time : String
@export var triggered : bool

@export_group("Auto reset")
@export var day_reset : bool = true

func restore() -> void :
	triggered = false
