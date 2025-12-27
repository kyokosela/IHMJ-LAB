extends Resource
class_name TaskList

signal all_task_finished

@export var task_list : Array[Task]

func is_all_task_done() -> bool :
	for task : Task in task_list :
		if !task.task_done : return false
	all_task_finished.emit()
	return true
