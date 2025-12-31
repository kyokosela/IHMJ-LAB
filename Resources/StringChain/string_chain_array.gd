extends Resource
class_name StringChainArray

enum BEHAVIOUR {
	COOLDOWN,
	RANDOM,
	ORDER,
	CYCLE
}

@export var unique_event_name : String = "ALL"
@export var string_list : Array[String]
@export var behaviour : BEHAVIOUR
