@tool
extends Interactable
class_name InteractableAction

@export_group("Dialog Interactions")
@export var talk_chain : Array[String]
@export var cooldown_message : String
@export var cooldown_time : String

var message_index : int = 0
var is_cooldown : bool
var max_cycles : int
var max_cycles_init : int

func _ready() -> void:
	super()
	talk_chain.append(cooldown_message)
	max_cycles = talk_chain.size()
	max_cycles_init = max_cycles

func execute() -> void:
	if is_cooldown : return
	can_interact = false
	
	if max_cycles == 1 : message_index += 1
	
	Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], tr(talk_chain[message_index]))
	Dialogic.timeline_ended.connect(func (): if !is_cooldown : can_interact = true, CONNECT_ONE_SHOT)
	
	if message_index == talk_chain.size() - 2 :
		max_cycles -= 1
	
	if max_cycles == max_cycles_init :
		message_index += 1
	
	if message_index + 1 == talk_chain.size() :
		toggle_visible(TOGGLE_MODE.HIDE)
		consume_time_handler()
		custom_execute()
		executed.emit()
		is_cooldown = true
		TimeManager.substract_to_current_time(cooldown_time)
		can_interact = false

func unlock_cooldown() -> void :
	pass
