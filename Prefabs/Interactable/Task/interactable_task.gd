@tool
extends Interactable
class_name InteractableAction

const EFFECT_STRESS := preload("res://Resources/Effects/Effects/stress.tres")

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
	
	var final_time_cost : String = PlayerManager.get_time_cost_with_effects(time_cost)
	if TimeUtils.is_valid_format(final_time_cost):
		TimeManager.add_to_current_time(final_time_cost)

	_process_action_stress_risk()
	
	if is_cooldown_at_execute :
		if !TimeUtils.is_valid_format(cooldown_time) : printerr(" error con el formato del tiempo en cooldown");return
		if cooldown_timer_message != null : cooldown_timer_message.reset()
		EventManager.create_lapse_event(cooldown_time, disable_cooldown, interaction_name.to_upper() + "_COOLDOWN", interaction_name.to_upper() + "_COOLDOWN", false, true, true)
	
	if !is_cooldown and is_cooldown_at_execute : cooldown_executed = true

## Hipersomnia puede causar Estres en cualquier accion (4 / 7 / 10 % segun su nivel).
## Atenta ya NO suma riesgo (antes sumaba 5 %): tu diseno dice que lo reduce; su efecto es subir
## el umbral de "exceso de trabajo". SISTEMA_EFECTOS §3.2.
func _process_action_stress_risk() -> void:
	var chance : float = PlayerManager.get_action_stress_chance()
	if chance > 0.0 and PlayerManager.rng.randf() < chance:
		PlayerManager.add_stress_cause("ACTION_HIPERSOMNIA")

func _ready() -> void:
	super()
	# Fix: Añadido Engine.is_editor_hint() para evitar acceder a EventManager en @tool mode antes de que los autoloads estén listos
	if EventManager and not Engine.is_editor_hint():
		var cooldown_event : Event = EventManager.get_event(interaction_name.to_upper() + "_COOLDOWN")
		if cooldown_event != null:
			# Volvimos a esta escena con el cooldown en curso (la escena se recrea al cambiar de zona):
			# sigue en cooldown y se reinicia al terminar. Antes quedaba usable al instante, o muerta para siempre.
			is_cooldown = true
			cooldown_executed = is_cooldown_at_execute
			cooldown_event.event_executed.connect(disable_cooldown, CONNECT_ONE_SHOT)
	
	# Fix: Añadidos checks para evitar acceder a la señal end_chain en instancias Resource placeholder en @tool mode
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
			var task_message : String = TaskManager.get_task_list_message(task_list)
			if task_message.is_empty() :   # Completado: la tarea agoto sus frases (cooldown); antes abria un cuadro vacio
				_on_ended_message()
				return
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], task_message)
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
