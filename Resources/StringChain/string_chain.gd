extends Resource
class_name StringChain

signal end_chain

@export var string_list : Array[String]
@export var cooldown_message : String
@export var max_cycles : int = 3

@export var apply_times : bool = true
@export var time_cooldown : String = "00:05"
@export var time_cycles : String = "00:02"

var tries : int = 0
var message_index : int = -1

func get_message() -> String :
	var message : String
	
	if message_index == string_list.size() - 1 :
		if apply_times : TimeManager.add_to_current_time(time_cycles)
		tries +=1

	message_index = clamp(message_index + 1, 0, string_list.size() - 1)
	message = string_list[message_index]
	
	if tries >= max_cycles :
		message = cooldown_message
		if apply_times : TimeManager.add_to_current_time(time_cooldown)
		end_chain.emit()
	
	return message
	
