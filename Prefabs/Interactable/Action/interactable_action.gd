@tool
extends Interactable
class_name InteractableAction

@export_group("Dialog Interactions")
@export var talk_chain : Array[String]
@export var cycles_time : String = "00:02"
@export var cooldown_message : String
@export var cooldown_time : String = "00:05"

var message_index : int = 0
var is_cooldown : bool
var max_cycles : int

func _ready() -> void:
	super()
	talk_chain.append(cooldown_message)
	max_cycles = talk_chain.size()

func execute() -> void:
	if is_cooldown : return
	can_interact = false
	
	Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], tr(talk_chain[message_index]))
	Dialogic.timeline_ended.connect(func (): if !is_cooldown : can_interact = true, CONNECT_ONE_SHOT)
	
	message_index = clamp(message_index + 1, 0, talk_chain.size() - 1)
	
	if message_index == talk_chain.size() - 1 :
		if max_cycles == 0 and !is_cooldown :
			TimeManager.add_to_current_time(cooldown_time)
			toggle_visible(TOGGLE_MODE.HIDE)
			custom_execute()
			executed.emit()
			is_cooldown = true
			can_interact = false
		else :
			TimeManager.add_to_current_time(cycles_time)
		max_cycles -= 1
		
