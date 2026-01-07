extends Resource
class_name ConditionThreshold

@export var thresholds: Array[ThresholdEntry]
@export var default_state: ItemState

func get_state_for_value(current_value: float) -> ItemState:
	var sorted_thresholds = thresholds.duplicate()
	sorted_thresholds.sort_custom(func(a, b): return a.max_value < b.max_value)
	
	for entry in sorted_thresholds:
		if current_value <= entry.max_value:
			return entry.state
	return default_state
