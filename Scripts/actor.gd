extends Entity
class_name Actor

var fsm : FSMComponent
var movement : MovementComponent

func _ready() -> void:
	super()
	add_to_group("Actor")
	_initialize_components()

func _initialize_components() -> void:
	fsm = get_component("FSMComponent")
	movement = get_component("MovementComponent")

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
