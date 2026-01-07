extends Resource
class_name TimeChanger

enum OPERATION_CASE {
	INCREASE,
	DECREASE,
	MULTIPLIER
}

@export var time_value : float
@export var OPERATION : OPERATION_CASE
