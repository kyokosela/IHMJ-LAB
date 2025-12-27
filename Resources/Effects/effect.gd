extends Resource
class_name Effect

enum OPERATION_CASE {
	INCREASE,
	DECREASE
}

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
	var total : float = 0
	var stats_changers = stat_changes_list(unique_stat_name)
	for stat_change in stats_changers:
		if stat_change.OPERATION == OPERATION_CASE.INCREASE:
			total += stat_change.value
		elif stat_change.OPERATION == OPERATION_CASE.DECREASE:
			total -= stat_change.value
	return total
		
