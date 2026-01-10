extends Node
class_name SaveComponent

#region SETUP
@export var uid: String = ""
@export var props_to_save: Array[String] = []


func _ready() -> void:
	SaveManager.register(self)
	

func _exit_tree() -> void:
	SaveManager.unregister(self)
#endregion

#region API
func get_data() -> Dictionary:
	var parent: Node = get_parent()
	var data: Dictionary = {}
	
	for prop in props_to_save:
		var val = parent.get(prop)
		if val != null: data[prop] = val
	
	return data


func apply_data(data: Dictionary) -> void:
	var parent = get_parent()
	
	for prop in data:
		if prop in parent:
			parent.set(prop, data[prop])
#endregion
