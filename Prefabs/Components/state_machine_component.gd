extends Component
class_name FSMComponent

signal state_entered(state_name: String)
signal state_exited(state_name: String)
signal state_changed(old_state: String, new_state: String)

@export var initial_state : State

var states: Dictionary[String, State] = {}
var current_state: State
var current_state_name: String = ""

func _ready() -> void:
	super()
	_collect_states()
	if initial_state: 
		current_state = initial_state
		current_state_name = initial_state.name
	else: 
		current_state = states.keys()[0]
		current_state_name = states.keys()[0].name

func _collect_states() -> void:
	for state in find_children("*", "State"):
		states[state.name] = state
		state.fsm = self
		state.entity = entity

func change_state(new_state_name: String) -> void:
	if new_state_name == current_state_name: return
	if not states.has(new_state_name):
		push_error("Estado no encontrado: " + new_state_name)
		return
	var old_state_name = current_state_name
	if current_state:
		current_state.exit()
		state_exited.emit(current_state_name)
	
	current_state_name = new_state_name
	current_state = states[new_state_name]
	
	state_entered.emit(new_state_name)
	state_changed.emit(old_state_name, new_state_name)

func _process(delta) -> void:
	if current_state and is_enabled and entity:
		current_state.update(delta)

func _physics_process(delta) -> void:
	if current_state and is_enabled and entity:
		current_state.physics_update(delta)
