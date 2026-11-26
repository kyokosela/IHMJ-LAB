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
	else :
		printerr(" error con al asignar la tarea ", _task_list_unique_name, " -> ", _task_unique_name)

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

#region Guardado (Docs/Design/GUARDADO.md)
## Las listas activas (por su archivo .tres) y, de cada tarea, si esta hecha y su espera.
func get_save_data() -> Dictionary :
	var lists : Array = []
	var seen : Array[String] = []
	for task_list : TaskList in active_tasks :
		if task_list.resource_path == "" or task_list.resource_path in seen : continue
		seen.append(task_list.resource_path)
		var tasks := {}
		for task : Task in task_list.task_list :
			tasks[task.task_unique_name] = {"done": task.task_done, "cooldown": task.cooldown, "is_cooldown": task.is_cooldown}
		lists.append({"path": task_list.resource_path, "ready": task_list.ready_task, "tasks": tasks})
	return {"lists": lists}

func load_save_data(data : Dictionary) -> void :
	active_tasks.clear()
	for entry : Dictionary in data.get("lists", []) :
		var task_list := load(entry.path) as TaskList
		if task_list == null : continue
		task_list.ready_task = entry.get("ready", false)
		var tasks : Dictionary = entry.get("tasks", {})
		for task : Task in task_list.task_list :
			if not tasks.has(task.task_unique_name) : continue
			task.task_done = tasks[task.task_unique_name].get("done", false)
			task.cooldown = tasks[task.task_unique_name].get("cooldown", task.cooldown)
			task.is_cooldown = tasks[task.task_unique_name].get("is_cooldown", false)
		active_tasks.append(task_list)
#endregion
