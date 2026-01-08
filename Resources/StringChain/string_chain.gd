extends Resource
class_name StringChain

signal end_chain

@export var string_list : Array[StringChainArray] ## Lista de mensajes, Ordenar por prioridad, es decir el mas importante arriba (indice 0)
@export var cooldown_message : String
@export var max_cycles : int = 3

@export var apply_times : bool = true
@export var time_cooldown : String = "00:05"
@export var time_cycles : String = "00:02"

var time_cycle_started : bool

@export var apply_energy : bool = true
@export var energy_cycles : float = 1
@export var energy_cooldown : float = 5

var energy_cycle_started : bool

var tries : int = 0
var message_index : int = -1

var message_order_index : int = 0
var message_cycle_index : int = 0

func get_message() -> String :

	var selection : StringChainArray = null
	var all_selection : StringChainArray = null
	
	for x in string_list :
		if x.unique_event_name == "ALL" :
			all_selection = x
		if EventManager.is_event_active(x.unique_event_name) : 
			selection = x
			break
			
	if selection == null and all_selection != null: selection = all_selection
	else :printerr("se jodio todo con este sistema de mierda de mensajes")
			
	var list_to_check: Array[String] = selection.string_list
			
	if list_to_check.is_empty():printerr("StringChain: La lista de mensajes de ", selection.unique_event_name, "está vacía");return ""
			
	if selection.string_list.is_empty() : printerr(" No se encontro ningun texto en ", self);return ""
	
	match selection.behaviour:
		StringChainArray.BEHAVIOUR.COOLDOWN:
			return get_cooldown_message(selection)
			
		StringChainArray.BEHAVIOUR.RANDOM:
			return list_to_check.pick_random()
		
		StringChainArray.BEHAVIOUR.ORDER:
			message_order_index = clamp(message_order_index + 1, 0, list_to_check.size() - 1)
			return list_to_check[message_order_index]
			
		StringChainArray.BEHAVIOUR.CYCLE:
			message_cycle_index += 1
			var idx = (message_cycle_index - 1) % list_to_check.size()
			return list_to_check[idx]
	
	printerr(" unknow error with stringChain, check export sets")
	return ""
	
func get_cooldown_message(selection : StringChainArray) -> String :
	var message : String
	
	if message_index == selection.string_list.size() - 1 :
		if apply_times and !time_cycle_started: 
			TimeManager.add_to_current_time(time_cycles)
			time_cycle_started = true
		if apply_energy and !energy_cycle_started  :
			PlayerManager.decrease_stat("ENERGY", energy_cycles)
			energy_cycle_started = true
		tries +=1

	message_index = clamp(message_index + 1, 0, selection.string_list.size() - 1)
	message = selection.string_list[message_index]
	
	if tries >= max_cycles :
		message = cooldown_message
		if apply_times : 
			TimeManager.add_to_current_time(time_cooldown)
		if apply_energy :
			PlayerManager.decrease_stat("ENERGY", energy_cooldown)
		end_chain.emit()
	
	return message
