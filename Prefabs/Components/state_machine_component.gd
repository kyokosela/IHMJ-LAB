extends Component
class_name FSMComponent

signal state_entered(state_name: String)
signal state_exited(state_name: String)
signal state_changed(old_state: String, new_state: String)

@export var initial_state: State

var states: Dictionary[String, State] = {}
var current_state: State
var current_state_name: String = ""

func _ready() -> void:
	super()
	_collect_states()
	_initialize_fsm()

func _collect_states() -> void:
	for state in find_children("*", "State"):
		states[state.name] = state
		state.fsm = self

func _initialize_fsm() -> void:
	for state in states.values():
		state.entity = entity
	
	var start_state: State = null
	var start_state_name: String = ""
	
	if initial_state and states.has(initial_state.name):
		start_state = initial_state
		start_state_name = initial_state.name
	elif states.size() > 0:
		start_state_name = states.keys()[0]
		start_state = states[start_state_name]
	else:
		push_error("FSM no tiene estados definidos!")
		return
	
	current_state = start_state
	current_state_name = start_state_name

	current_state.enter()
	state_entered.emit(current_state_name)

func change_state(new_state_name: String) -> void:
	if new_state_name == current_state_name:
		return
	
	if not states.has(new_state_name):
		push_error("Estado no encontrado: %s" % new_state_name)
		return
	
	var old_state_name = current_state_name
	
	if current_state:
		current_state.exit()
		state_exited.emit(old_state_name)
	
	current_state_name = new_state_name
	current_state = states[new_state_name]
	
	current_state.enter()
	state_entered.emit(new_state_name)
	state_changed.emit(old_state_name, new_state_name)

func _process(delta: float) -> void:
	if current_state and is_enabled and entity:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state and is_enabled and entity:
		current_state.physics_update(delta)

func has_state(state_name: String) -> bool:
	return states.has(state_name)

func get_state(state_name: String) -> State:
	return states.get(state_name, null)

func get_all_states() -> Array[State]:
	return states.values()
