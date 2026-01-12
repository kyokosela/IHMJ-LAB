extends Node
class_name SaveComponent

#region SETUP
## idealmente crea tus propias UID,
## pero no es mandatorio. Su default es
## la UID del nodo padre
@export var uid: String = ""
@export var props_to_save: Array[String] = []

@onready var _parent: Node = get_parent()

func _ready() -> void:
	if uid.is_empty(): uid = str(get_path())
	SaveManager.register(self)
	

func _exit_tree() -> void:
	SaveManager.unregister(self)
#endregion

#region API
func get_data() -> Dictionary:
	var data: Dictionary = {}
	for prop in props_to_save:
		var val = _parent.get(prop)
		if val != null: data[prop] = val
	return data


func apply_data(data: Dictionary) -> void:
	for prop in data:
		if prop in _parent:
			_parent.set(prop, data[prop])
#endregion
