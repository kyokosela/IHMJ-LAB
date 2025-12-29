extends Resource
class_name Item

@export var data : ItemData
var condition : float = 100.0
var states : Dictionary[String, ItemState]

func _init(p_data : ItemData) -> void:
	data = p_data

func add_state(state : ItemState) -> void: ## Añade un estado, en caso de que ya contenga un estado de un grupo exclusivo, se reemplazara por el nuevo estado
	if state.exclusive_group != "":
		for s : ItemState in states.values():
			if s.exclusive_group == state.exclusive_group:
				states.erase(s.id)
	states[state.id] = state

func has_state(id : String) -> bool:
	return states.has(id)
