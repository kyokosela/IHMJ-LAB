extends Resource
class_name Task

signal task_finished

@export var task_name : String : 
	get() : return tr(task_name)
@export var task_description : String : 
	get() : return tr(task_description)
@export var task_done : bool

func set_done() -> void :
	task_done = true
	task_finished.emit()
