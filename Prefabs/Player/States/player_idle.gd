extends PlayerState
class_name PlayerIdle

func _ready():
	super()

func enter():
	player.stop_move()
	player.play_animation("idle")

func exit():
	pass

func update(_delta: float):
	if player._has_movement():
		var direction = Input.get_vector("move_left","move_right","move_up","move_down")
		if direction and player.can_move():
			fsm.change_state("PlayerWalk")

func physics_update(_delta: float):
	pass
