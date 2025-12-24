extends Node2D
class_name Component

signal component_ready
signal component_disabled
signal component_enabled

var entity : Entity
var is_enabled : bool = true

func _ready() -> void:
	if not entity and get_parent() is Entity:
		entity = get_parent()
	assert(entity != null, "Entity should never be NULL")
	component_ready.emit()

func enable() -> void:
	is_enabled = true
	component_enabled.emit()

func disable() -> void:
	is_enabled = false
	component_disabled.emit()
