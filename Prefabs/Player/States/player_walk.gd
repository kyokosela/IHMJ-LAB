extends State
class_name PlayerWalkState

@export var movement_component: MovementComponent

func _ready():
	pass

func enter():
	pass

func exit():
	pass

func update(_delta: float):
	pass

func physics_update(_delta: float):
	var horizontal_axis = Input.get_axis("move_left","move_right")
	var vertical_axis = Input.get_axis("move_up","move_down")
	var direction = Vector2(horizontal_axis,vertical_axis)
	if direction:
		movement_component.set_direction(horizontal_axis,vertical_axis)
	else:
		movement_component.stop()
		fsm.change_state("PlayerIdleState")
