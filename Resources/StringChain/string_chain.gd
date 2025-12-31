extends Resource
class_name StringChain

signal end_chain

@export var string_list : Array[StringChainArray] ## Lista de mensajes, Ordenar por prioridad, es decir el mas importante arriba (indice 0)
@export var cooldown_message : String
@export var max_cycles : int = 3

@export var apply_times : bool = true
@export var time_cooldown : String = "00:05"
@export var time_cycles : String = "00:02"

var tries : int = 0
var message_index : int = -1

var message_order_index : int = 0
var message_cycle_index : int = 0

func get_message() -> String :
	
	var selection : StringChainArray
	
	for x in string_list :
		if EventManager.is_event_active(x.unique_event_name) : 
			selection = x
	if selection.string_list.is_empty() : printerr(" No se encontro ningun texto en ", self);return ""
	
	if selection.behaviour == StringChainArray.BEHAVIOUR.COOLDOWN : return get_cooldown_message(selection)
	if selection.behaviour == StringChainArray.BEHAVIOUR.RANDOM : return selection.string_list.pick_random()
	if selection.behaviour == StringChainArray.BEHAVIOUR.ORDER : message_order_index = clamp(message_order_index + 1, 0, string_list.size() - 1);return selection.string_list[message_order_index]
	if selection.behaviour == StringChainArray.BEHAVIOUR.CYCLE : message_cycle_index += 1;return selection.string_list[message_cycle_index % string_list.size() - 1]
	
	printerr(" unknow error with stringChain, check export sets")
	return ""
	
func get_cooldown_message(selection : StringChainArray) -> String :
	var message : String
	
	if message_index == selection.string_list.size() - 1 :
		if apply_times : TimeManager.add_to_current_time(time_cycles)
		tries +=1

	message_index = clamp(message_index + 1, 0, selection.string_list.size() - 1)
	message = selection.string_list[message_index]
	
	if tries >= max_cycles :
		message = cooldown_message
		if apply_times : TimeManager.add_to_current_time(time_cooldown)
		end_chain.emit()
	
	return message
