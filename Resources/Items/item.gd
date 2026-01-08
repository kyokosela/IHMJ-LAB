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

func apply_decay(minutes: int, env_conditions : Array[String]):
	data.behavior.apply_base_decay(minutes,self,env_conditions)

func apply_enviroment(minutes: int, env_properties : Array[String]):
	if data.custom_conditions.is_empty(): return
	data.behavior.apply_enviroment(minutes,self,env_properties)

func get_custom_condition(condition_name : String) -> CustomCondition:
	for c in data.custom_conditions:
		if c.condition == condition_name: return c
	return null

func has_custom_condition(condition_name : String) -> bool:
	for c in data.custom_conditions:
		if c.condition == condition_name: return true
	return false
	
func decrease_condition_value(condition_name : String, value : float):
	var custom = get_custom_condition(condition_name)
	if custom != null:
		custom.value -= value
		
func increase_condition_value(condition_name : String, value : float):
	var custom = get_custom_condition(condition_name)
	if custom != null:
		custom.value += value
		
func use():
	var behavior = data.behavior
	if not behavior.can_use(self): return
	behavior.use(self)

func has_state(id : String) -> bool:
	return states.has(id)
