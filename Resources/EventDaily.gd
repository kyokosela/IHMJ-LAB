extends Event
class_name EventDaily

@export_range(0,30,1) var days : int
@export_range(0,11,1) var months : int
@export_range(0,59,1) var hour : int
@export_range(-1, 59, 1) var end_hour : int
@export_range(0,59,1) var minute : int
@export_range(-1, 59, 1) var end_minute : int
