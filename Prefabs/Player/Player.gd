extends Entity
class_name Player

var fsm : FSMComponent
var movement : MovementComponent
var interaction : InteractionComponent

func _ready() -> void:
	super()
	add_to_group("Player")
	_initialize_components()

func _initialize_components() -> void:
	fsm = get_component("FSMComponent")
	movement = get_component("MovementComponent")
	interaction = get_component("InteractionComponent")

#region Movement API
func can_move() -> bool:
	return movement.can_move and _has_movement()

func moving() -> bool:
	return movement.is_moving and _has_movement()

func is_tile_based() -> bool:
	return movement.tile_based and _has_movement()

func current_speed() -> float:
	return velocity.length() if _has_movement() else 0.0

func facing_dir() -> Vector2:
	return movement.last_facing_dir if _has_movement() else Vector2.ZERO

func last_input_axis() -> Vector2:
	return movement.last_input_axis if _has_movement() else Vector2.ZERO

func _has_movement() -> bool:
	return movement != null
#endregion

#region FSM API
func get_curr_state() -> State:
	return fsm.current_state if _has_fsm() else null

func get_curr_state_name() -> String:
	return fsm.current_state_name if _has_fsm() else ""

func get_states() -> Dictionary[String, State]:
	return fsm.states if _has_fsm() else {}

func change_state(state_name : String) -> void:
	if _has_fsm(): fsm.change_state(state_name)

func is_in_state(state_name : String) -> bool:
	return state_name == fsm.current_state_name and _has_fsm()

func _has_fsm() -> bool:
	return fsm != null
#endregion
