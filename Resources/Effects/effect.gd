extends Resource
class_name Effect

@export var effect_unique_name : String
@export var effect_display_name : String :
	get() :
		return tr(effect_display_name)
@export var render : bool
@export var stat_changes : Array[StatChanger]

func stat_changes_list(unique_stat_name : String) -> Array[StatChanger]:
	var stats_changers : Array[StatChanger]= []
	for change in stat_changes: 
		if change.stat_unique_name == unique_stat_name:
			stats_changers.append(change)
	return stats_changers

func stat_change_total(unique_stat_name : String)-> float:
	var total : float = 0.0
	var stats_changers = stat_changes_list(unique_stat_name)
	stats_changers.sort_custom(func(_a,_b) : if _a.OPERATION != StatChanger.OPERATION_CASE.MULTIPLIER : return true)
	
	for stat_change in stats_changers:
		
		if stat_change.OPERATION == StatChanger.OPERATION_CASE.INCREASE:
			total += stat_change.value
		elif stat_change.OPERATION == StatChanger.OPERATION_CASE.DECREASE:
			total -= stat_change.value
		elif stat_change.OPERATION == StatChanger.OPERATION_CASE.MULTIPLIER :
			total *= stat_change.value
	return total

func get_stat_change_total(unique_stat_name : String, custom_value : float = 0.0)-> float:
	var total : float = custom_value
	var stats_changers = stat_changes_list(unique_stat_name)
	
	stats_changers.sort_custom(func(a, b):
		return a.OPERATION != StatChanger.OPERATION_CASE.MULTIPLIER and b.OPERATION == StatChanger.OPERATION_CASE.MULTIPLIER
	)
	
	for stat_change in stats_changers:
		print(stat_change.OPERATION )
		if stat_change.OPERATION == StatChanger.OPERATION_CASE.INCREASE:
			total += stat_change.value
		elif stat_change.OPERATION == StatChanger.OPERATION_CASE.DECREASE:
			total -= stat_change.value
		elif stat_change.OPERATION == StatChanger.OPERATION_CASE.MULTIPLIER :
			total *= 1 - stat_change.value

	return total
