@tool
extends Interactable
class_name InteractableAction

@export var task_lists : Array[String]
@export var effect_list : Array[String]
@export var effect_messages : StringChain
@export var event_list : Array[String]
@export var event_messages : StringChain
var is_cooldown : bool

func custom_execute(): 
	super()
	if !is_cooldown : 
		can_interact = true 

func _ready() -> void:
	super()
	if effect_messages : effect_messages.end_chain.connect(set_cooldown)
	if event_messages : event_messages.end_chain.connect(set_cooldown)

func execute() -> void :

	can_interact = false
	for task_list in task_lists :
		if TaskManager.is_task_list_active(task_list) and !TaskManager.is_task_list_done(task_list) :
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], TaskManager.get_task_list_message(task_list))
			Dialogic.timeline_ended.connect(func (): if !is_cooldown : can_interact = true, CONNECT_ONE_SHOT)
			return
		
	if !check_events()  :
		if event_messages != null :
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], event_messages.get_message())
			Dialogic.timeline_ended.connect(func (): if !is_cooldown : can_interact = true, CONNECT_ONE_SHOT)
		return
	
	if !check_effects() :
		if effect_messages != null :
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], effect_messages.get_message())
			Dialogic.timeline_ended.connect(func (): if !is_cooldown : can_interact = true, CONNECT_ONE_SHOT)
		return
	
	custom_execute()
	executed.emit()
	
	if !show_again_at_end : toggle_visible(TOGGLE_MODE.HIDE)
	
	if destroy_at_end : 
		if dialog == null : queue_free()
		else : Dialogic.timeline_ended.connect(func () : queue_free(), CONNECT_ONE_SHOT)

func set_cooldown() -> void :
	is_cooldown = true
	toggle_visible(TOGGLE_MODE.HIDE)
	can_interact = false

func check_effects() -> bool :
	for effect : String in effect_list :
		if !PlayerManager.has_effect(effect) : return false
	return true

func check_events() -> bool :
	for event : String in event_list :
		if !EventManager.is_event_active(event) : return false
	return true
