extends Control
class_name BaseApp

#region SETUP
var app_id: String = ""

const PREFIX: String = "save_"
var _persistent_props: Array[String] = []

func _ready() -> void:
	assert(!app_id.is_empty(), name + " has not app id")
	
	_scan_props()
	
	var data = SaveManager.get_app_data(app_id)
	
	if !data.is_empty():
		for p in _persistent_props:
			if data.has(p):
				self.set(p, data[p])

	_on_app_ready()

func _on_app_ready() -> void:
	assert(false, "method meant to be overridden, at %s" % get_script().resource_path)
#endregion

#region LOGIC
func commit() -> void:
	var data: Dictionary = {}
	
	for prop in _persistent_props:
		data[prop] = self.get(prop)
	
	SaveManager.update_app_data(app_id, data)
	SaveManager.save_data()

func _load_app_data() -> void:
	var data = SaveManager.get_app_data(app_id)
	
	if data.is_empty(): return
	
	for prop in _persistent_props:
		if data.has(prop):
			self.set(prop, data[prop])

func _scan_props() -> void:
	_persistent_props.clear()
	
	for prop in get_property_list():
		if prop.name.begins_with(PREFIX):
			_persistent_props.append(prop.name)
#endregion
