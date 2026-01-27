@tool
extends Interactable
class_name InteractableAction

@export var interaction_name : String
@export var is_cooldown_at_execute : bool
@export var cooldown_time : String = "05:00"
@export var cooldown_timer_message : StringChain
@export_group("Requeriments")
@export var task_lists : Array[String] ## Lista de tareas por hacer
@export var effect_list : Array[String] ## Lista de efectos requeridos
@export var effect_messages : StringChain 
@export var event_list : Array[String]
@export var event_messages : StringChain
@export_group("Cost values")
@export var stat_req_list : Dictionary[String, int] ## usar nombre unico como por ejemplo ENERGY
@export var stat_messages : StringChain
@export var time_cost : String
@export var weak_messages : StringChain

var is_cooldown : bool
var cooldown_executed : bool

func custom_execute(): 
	super()
	
	if !is_cooldown : can_interact = true # esto parece que hace nada pero hace de default en acciones aslkdjsad
	
	for stat_name in stat_req_list :
		var test = PlayerManager.get_cost_with_effects(stat_name, stat_req_list[stat_name])
		PlayerManager.decrease_stat(stat_name, test)
	
	for effect : Effect in PlayerManager.effects :
		if effect.time_changes == null : continue
		if effect.time_changes.OPERATION == TimeChanger.OPERATION_CASE.MULTIPLIER :
			time_cost = TimeUtils.multiply_time(time_cost, effect.time_changes.time_value)
	
	if TimeUtils.is_valid_format(time_cost) : TimeManager.add_to_current_time(time_cost)
	
	if is_cooldown_at_execute :
		if !TimeUtils.is_valid_format(cooldown_time) : printerr(" error con el formato del tiempo en cooldown");return
		EventManager.create_lapse_event(cooldown_time, disable_cooldown, interaction_name.to_upper() + "_COOLDOWN", interaction_name.to_upper() + "_COOLDOWN", false, true, true)
	
	if !is_cooldown and is_cooldown_at_execute : cooldown_executed = true

func _ready() -> void:
	super()
	# Fix: Added Engine.is_editor_hint() check to prevent accessing EventManager in @tool mode before autoloads are ready
	if EventManager and not Engine.is_editor_hint() and EventManager.is_event_exist(interaction_name.to_upper() + "_COOLDOWN") : is_cooldown = true
	
	# Fix: Added checks to prevent accessing end_chain signal on placeholder Resource instances in @tool mode
	if effect_messages and not Engine.is_editor_hint(): effect_messages.end_chain.connect(_on_end_chain)
	if event_messages and not Engine.is_editor_hint(): event_messages.end_chain.connect(_on_end_chain)
	if stat_messages and not Engine.is_editor_hint(): stat_messages.end_chain.connect(_on_end_chain)
	if cooldown_timer_message and not Engine.is_editor_hint(): cooldown_timer_message.end_chain.connect(set_cooldown, true)

func _on_end_chain() -> void :
	set_cooldown()

func execute() -> void :
	can_interact = false
	
	for task_list in task_lists :
		if TaskManager.is_task_list_active(task_list) and !TaskManager.is_task_list_done(task_list) :
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], TaskManager.get_task_list_message(task_list))
			Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)
			return
		
	if !check_events()  :
		if event_messages != null :
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], event_messages.get_message())
			Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)
		return
	
	if !check_effects() :
		if effect_messages != null :
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], effect_messages.get_message())
			Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)
		return
	
	if !check_stats() :
		if stat_messages != null :
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], stat_messages.get_message())
			Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)
		return
	
	if cooldown_executed :
		if cooldown_timer_message != null:
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], cooldown_timer_message.get_message())
			Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)
		return
		
	custom_execute()
	executed.emit()
	
	if !show_again_at_end : toggle_visible(TOGGLE_MODE.HIDE)
	
	if destroy_at_end : 
		if dialog == null : queue_free()
		else : Dialogic.timeline_ended.connect(func () : queue_free(), CONNECT_ONE_SHOT)

func _on_ended_message() -> void :
	if !is_cooldown : can_interact = true

func set_cooldown() -> void :
	is_cooldown = true
	can_interact = false
	toggle_visible(TOGGLE_MODE.HIDE)

func disable_cooldown() -> void :
	is_cooldown = false
	can_interact = true
	cooldown_executed = false

func check_effects() -> bool :
	for effect : String in effect_list :
		if !PlayerManager.has_effect(effect) : return false
	return true

func check_events() -> bool :
	for event : String in event_list :
		if !EventManager.is_event_active(event) : return false
	return true

func check_stats() -> bool :
	for stat in stat_req_list :
		print(" hola " , stat)
		var value = PlayerManager.get_stat_value(stat)
		
		if stat == "ENERGY" and PlayerManager.has_effect("WEAK") and stat_req_list[stat] >= 15 :
			return false
		
		if value < (PlayerManager.get_cost_with_effects(stat, stat_req_list[stat])) :
			return false
				
	return true
