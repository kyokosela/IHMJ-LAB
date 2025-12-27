extends Resource
class_name TaskList

@export var task_list : Dictionary[String, bool]

func is_done() -> bool :
	for task in task_list :
		if !task_list[task] : return false
	return true
