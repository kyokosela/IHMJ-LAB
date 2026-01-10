extends Resource
class_name ItemBehavior

@export var can_decay : bool = true

func can_use(_item: Item) -> bool:
	return false

func use(_item: Item) -> void:
	_item.used.emit()

func update_states(_item: Item) -> void:
	var conditions = _item.data.custom_conditions
	
	for condition in conditions:
		condition.update_states(_item) 
	_item.item_changed.emit()

func apply_base_decay(minutes:int,item: Item, env_conditions: Array[String]):
	if !can_decay: return
	var decay_value : float = 0
	var base_decay : int = item.data.base_decay_time
	var quality : float = item.data.get_quality_percentage()
	var modifiers : Array[ConditionModifier] = item.data.modifiers
	
	decay_value = round( (minutes * get_base_decay_factor(base_decay,quality) ))
	
	for modifier : ConditionModifier in modifiers:
		if modifier.applies_to in env_conditions:
			decay_value = round( (minutes / get_base_decay_factor(base_decay,quality)) * modifier.multiplier )
	
	item.condition -= decay_value 
	update_states(item)
	

func apply_enviroment(minutes:int,item: Item, env_properties: Array[String]):
	var conditions = item.data.custom_conditions
	for condition in conditions:
		if not condition.can_decay: continue
		if condition.enviroment_condition not in env_properties: continue
		var decay_value : float = 0
		var base_decay : int = condition.base_decay_time
		var quality : float = item.data.get_quality_percentage()
		var modifiers : Array[ConditionModifier] = condition.modifiers
		var env_conditions : Array[String] = env_properties
		
		decay_value = round( (minutes * get_base_decay_factor(base_decay,quality)) )
		
		for modifier : ConditionModifier in modifiers:
			if modifier.applies_to in env_conditions:
				decay_value = round( (minutes * get_base_decay_factor(base_decay,quality) * modifier.multiplier))
		
		condition.value -= decay_value
		
		
	update_states(item)
	

func get_base_decay_factor(base_decay_time, quality : float ) -> float:
	return 100.0 / (base_decay_time + (base_decay_time * quality))
