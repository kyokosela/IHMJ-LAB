extends Resource
class_name StatChanger

enum OPERATION_CASE {
	INCREASE,
	DECREASE
}

@export var stat_unique_name : String
@export var value : float
@export var OPERATION : OPERATION_CASE
