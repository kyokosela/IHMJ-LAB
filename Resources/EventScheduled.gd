extends Event
class_name EventScheduled

@export var day : int
@export var month : int
@export_range(0,59,1) var hour : int
@export_range(-1,59,1) var end_hour : int
@export_range(0,59,1) var minute : int
@export_range(-1,59,1) var end_minute : int
