extends PlayerState
class_name PlayerWalk

func _ready():
	super()

func _initialize():
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
		player.set_direction(horizontal_axis,vertical_axis)
		player.play_animation("walk")
	else:
		player.stop_move()
		fsm.change_state("PlayerIdle")
	
