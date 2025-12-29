extends Node

@export var active_tasks : Array[TaskList]

#region API

func load_task_list(task_list : TaskList) -> void :
	active_tasks.append(task_list)

func remove_task_list(_task_list_unique_name : String) -> void :
	var task_list : TaskList = get_task_list_res(_task_list_unique_name)
	if task_list != null : active_tasks.erase(task_list)

func connect_to_task(_task_list_unique_name : String, _task_unique_name : String, callable : Callable) -> void :
	var task_list : TaskList = get_task_list_res(_task_list_unique_name)
	if task_list != null : 
		var task : Task = task_list.get_task_res(_task_unique_name)
		if task : task.task_finished.connect(callable)

func done_task(_task_list_unique_name : String, _task_unique_name : String) -> void :
	var task_list : TaskList = get_task_list_res(_task_list_unique_name)
	if task_list != null : 
		task_list.check_task(_task_unique_name)

func is_task_list_done(_task_list_unique_name : String) -> bool :
	var task_list : TaskList = get_task_list_res(_task_list_unique_name)
	if task_list != null : return task_list.is_all_task_done()
	return false

func is_task_list_active(_task_list_unique_name : String) -> bool :
	var task_list : TaskList = get_task_list_res(_task_list_unique_name)
	if task_list != null : return true
	else : return false

func get_task_list_message(_task_list_unique_name : String) -> String :
	var task_list : TaskList = get_task_list_res(_task_list_unique_name)
	if task_list != null : return task_list.get_task_message()
	return ""

func connect_to_end_task_list(_task_list_unique_name : String, callable : Callable) -> void :
	var task_list : TaskList = get_task_list_res(_task_list_unique_name)
	if task_list != null : task_list.all_task_finished.connect(callable)

func get_task_list_res(_task_list_unique_name : String) -> TaskList :
	for task_list : TaskList in active_tasks :
		if task_list.task_list_unique_name == _task_list_unique_name :
			return task_list
	return null

#endregion
