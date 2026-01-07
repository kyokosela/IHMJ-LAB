extends Resource
class_name CustomCondition

@export var condition : String
@export var value : float = 100.0
@export var base_decay_time : int = 1440
@export var enviroment_condition : String
@export var modifiers : Array[ConditionModifier]
@export var condition_threshold : ConditionThreshold
@export var can_decay : bool

func update_states(_item : Item) -> void:
	var state = condition_threshold.get_state_for_value(value)
	_item.add_state(state)
