extends Node2D
class_name Component

signal component_ready
signal component_disabled
signal component_enabled

var host : Node2D
var is_enabled : bool = true

func _ready() -> void:
	if not host and get_parent() is Node2D:
		host = get_parent()
	assert(host != null, "Entity should never be NULL")
	component_ready.emit()

func enable() -> void:
	is_enabled = true
	component_enabled.emit()

func disable() -> void:
	is_enabled = false
	component_disabled.emit()
