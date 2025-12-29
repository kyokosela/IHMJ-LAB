extends Resource
class_name TaskList

signal all_task_finished

@export var task_list_unique_name : String
@export var task_list : Array[Task]
var ready_task : bool = false

func get_task_res(_unique_task_name) -> Task :
	for task in task_list :
		if task.task_unique_name == _unique_task_name : return task
	return null

func is_all_task_done() -> bool :
	if task_list.is_empty() : return true
	for task : Task in task_list :
		if !task.task_done : 
			return false
	all_task_finished.emit()
	return true

func get_task_message() -> String :
	if is_all_task_done() : return ""
	for task : Task in task_list :
		if !task.check_events() : continue
		if !task.task_done : return tr(task.get_message())
	return ""

func check_task(_task_unique_name) -> void :
	for task : Task in task_list :
		if task.task_unique_name == _task_unique_name :
			task.set_done()
