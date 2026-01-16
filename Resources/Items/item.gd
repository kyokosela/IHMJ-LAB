extends Resource
class_name Item

@warning_ignore("unused_signal") 
signal used
signal item_changed

@export var data : ItemData
@export var condition : float = 100.0:
	set(_v): 
		condition = clamp(_v, 0.0, 100.0)
		if data: update_states()

var states : Dictionary[String, ItemState]

func _init(p_data : ItemData = null) -> void:
	data = p_data
	if data: update_states()
	
func add_state(state : ItemState) -> void: ## Añade un estado, en caso de que ya contenga un estado de un grupo exclusivo, se reemplazara por el nuevo estado
	if state == null: return
	if state.exclusive_group != "":
		for s : ItemState in states.values():
			if s.exclusive_group == state.exclusive_group:
				states.erase(s.id)
	states[state.id] = state
	item_changed.emit()

func update_states():
	if not data or not data.behavior: return 
	data.behavior.update_states(self)
	item_changed.emit()

func apply_decay(minutes: int, env_conditions : Array[String]):
	data.behavior.apply_base_decay(minutes,self,env_conditions)
	item_changed.emit()

func apply_enviroment(minutes: int, env_properties : Array[String]):
	if data.custom_conditions.is_empty(): return
	data.behavior.apply_enviroment(minutes,self,env_properties)
	item_changed.emit()

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
		item_changed.emit()
		
func increase_condition_value(condition_name : String, value : float):
	var custom = get_custom_condition(condition_name)
	if custom != null:
		custom.value += value
		item_changed.emit()
	
func has_state(id : String) -> bool:
	return states.has(id)
