extends Node
class_name State

var fsm: FSMComponent
var entity: Entity

func _ready() -> void:
	pass

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func change_to(state_name: String) -> void:
	if fsm:
		fsm.change_state(state_name)

func is_current() -> bool:
	return fsm and fsm.current_state == self

func get_state_name() -> String:
	return name
