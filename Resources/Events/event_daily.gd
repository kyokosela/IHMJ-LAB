extends Event
class_name EventDaily

@export_range(0,30,1) var days : int
@export var week_day : TimeUtils.WEEKDAY
@export var months : TimeUtils.MONTHS
@export_range(0,23,1) var hour : int
@export_range(-1, 23, 1) var end_hour : int
@export_range(0,59,1) var minute : int
@export_range(-1, 59, 1) var end_minute : int
