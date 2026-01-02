extends Resource
class_name ScheduleConfig

@export var month : Array[TimeUtils.MONTHS]
@export var week_day : Array[TimeUtils.WEEKDAY]
@export var day : int = -1
@export_custom(PROPERTY_HINT_PLACEHOLDER_TEXT, "HH:MM") var time : String ##HH:MM
