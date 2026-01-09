extends Node

#region SETUP
const SAVE_PATH: String = "user://system_data.dat"

var _global: Dictionary = {}

func _ready() -> void:
	load_data()
	print(_global)
#endregion

#region API
func save_data() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	assert(file, "Couldn't open file")
	file.store_var(_global)
	
func load_data() -> void:
	if !FileAccess.file_exists(SAVE_PATH): return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	assert(file, "couldn't open file")
	
	var content = file.get_var()
	_global = content if content is Dictionary else _global
#endregion

#region WORKSPACE API
func get_app_data(app_id: String) -> Dictionary:
	if !_global.has(app_id):
		_global[app_id] = {}
	return _global[app_id]
	
func update_app_data(app_id: String, data: Dictionary) -> void:
	_global[app_id] = data
	# save_data()
#endregion
