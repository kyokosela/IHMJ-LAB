extends Node

#region SETUP
const SAVE_PATH: String = "user://system_data.dat"
var _active_components: Array[SaveComponent] = []
var _global: Dictionary = {}


func _ready() -> void:
	load_data()
	print(_global)
#endregion

#region API
func register(component: SaveComponent):
	_active_components.append(component)
	if _global.has(component.uid):
		component.apply_data(_global[component.uid])


func unregister(component: SaveComponent):
	if component in _active_components: _active_components.erase(component)


func save_data():
	for i in range(_active_components.size() -1, -1, -1):
		var comp = _active_components[i]
		
		if !is_instance_valid(comp):
			_active_components.remove_at(i)
			continue
			
		if !comp.uid.is_empty():
			_global[comp.uid] = comp.get_data()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(_global)


func load_data():
	if !FileAccess.file_exists(SAVE_PATH): return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	_global = file.get_var()
#endregion
