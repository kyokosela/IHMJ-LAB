class_name SaveManager

#region SETUP
const VERSION: int = 1
const SAVE_DIR: String = "user://saves/"
static var _active_components: Dictionary = {}
static var _global: Dictionary = {}


static func _static_init() -> void:
	if !DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
#endregion

#region API
static func register(component: SaveComponent) -> void:
	_active_components[component.get_instance_id()] = component
	
	if _global.has(component.uid):
		component.apply_data(_global[component.uid])


static func unregister(component: SaveComponent) -> void:
	if is_instance_valid(component) and not component.uid.is_empty():
		_global[component.uid] = component.get_data()
	_active_components.erase(component.get_instance_id())


static func save_to_disk(slot: String = "auto") -> void:
	for comp: SaveComponent in _active_components.values():
		if is_instance_valid(comp) and not comp.uid.is_empty():
			_global[comp.uid] = comp.get_data()
	
	var payload: Dictionary = {
		"version": VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"game_data": _global
	}
	
	var path = _get_slot_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if !file: 
		push_error("Write failed at %s. Error: %s" % [path, error_string(FileAccess.get_open_error())])
		return
	
	file.store_var(payload)
	print("Data saved: %s" % slot)
	print("%s\n\nactive components: %s" % [JSON.stringify(_global), JSON.stringify(_active_components.size())])


static func load_from_disk(slot: String = "auto") -> void:
	var path = _get_slot_path(slot)
	if !FileAccess.file_exists(path): return

	var file = FileAccess.open(path, FileAccess.READ)	
	if !file: return
	
	var payload = file.get_var()
	if !payload is Dictionary: 
		push_error("Corrupt save file at %s. Error: %s" % path)
		return
	
	var save_version = payload.get("version", 0)
	if save_version < VERSION:
		payload = _migrate_save(payload, save_version)	
		
	_global = payload.get("game_data", {})
	
	for comp: SaveComponent in _active_components.values():
		if is_instance_valid(comp) and _global.has(comp.uid):
			comp.apply_data(_global[comp.uid])
			
	print("Data loaded: %s" % slot)
	print("%s\n\nactive components: %s" % [JSON.stringify(_global), JSON.stringify(_active_components.size())])
#endregion

#region UTILS
static func _get_slot_path(slot: String) -> String:
	return SAVE_DIR + "save_" + slot + ".dat"


# TODO: implementar backwards compatibility
@warning_ignore("unused_parameter")
static func _migrate_save(payload: Dictionary, v: int) -> Dictionary:
	payload["version"] = VERSION
	return payload
#endregion
