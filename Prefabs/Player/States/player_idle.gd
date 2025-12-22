extends State
class_name PlayerIdleState

@export var movement_component: MovementComponent

func _ready():
	pass

func enter():
	movement_component.stop()

func exit():
	pass

func update(_delta: float):
	var direction = Input.get_vector("move_left","move_right","move_up","move_down")
	if direction and movement_component.can_move:
		fsm.change_state("PlayerWalkState")

func physics_update(_delta: float):
	pass
