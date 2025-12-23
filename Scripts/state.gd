extends Node
class_name State

var fsm: FSMComponent
var entity: Entity

func _ready():
	await get_tree().process_frame
	if not fsm and get_parent() is FSMComponent:
		fsm = get_parent()
		entity = fsm.entity

func enter():
	pass

func exit():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	pass
