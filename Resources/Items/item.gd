extends Resource
class_name Item

@export var data : ItemData
var condition : float = 100.0:
	set(_v): 
		condition = clamp(_v, 0.0, 100.0)
		update_states()

var states : Dictionary[String, ItemState]

func _init(p_data : ItemData) -> void:
	data = p_data
	update_states()
	
func add_state(state : ItemState) -> void: ## Añade un estado, en caso de que ya contenga un estado de un grupo exclusivo, se reemplazara por el nuevo estado
	if state.exclusive_group != "":
		for s : ItemState in states.values():
			if s.exclusive_group == state.exclusive_group:
				states.erase(s.id)
	states[state.id] = state

func update_states():
	data.behavior.update_states(self)
	print(states)

func use():
	var behavior = data.behavior
	if not behavior.can_use(self): return
	behavior.use(self)

func has_state(id : String) -> bool:
	return states.has(id)
