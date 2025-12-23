@tool
@icon("res://Assets/CustomIcons/Interactable.png")
extends Area2D
class_name Interactable

#region SETUP

signal executed ## Se emite cuando el jugador realiza la [b]interacción[/b]
enum SIGNAL_TYPE {AREA, BODY}
enum TOGGLE_MODE {TOGGLE,SHOW,HIDE}
var collshape : CollisionShape2D

## Rango de interaccion
@export var shape : Shape2D : 
	set(value) : shape = value; if Engine.is_editor_hint() : collshape.shape = shape
@export var display_text : String = "_INTERACT_BASE_MESSAGE_" ## Texto que se mostrara en pantalla al entrar en el rango del area, si esta vacio no mostrara nada
@export var toggle_childrens_visible : bool = true ## Si es [b]verdadero[/b] ocultara a todos los nodos de tipo [b]control[/b] que se encuentren como hijos
@export var retoggable_inside : bool = true ## La acción se podra realizar varias veces si es verdadera, en caso contrario la interacción solo se ejecutara una unica vez
@export var show_again_at_end : bool = false ## Mostrar elementos despues de acabar la ejecucion si es necesario
@export var destroy_at_end : bool = false ## Destruir al final de la ejecución
@export var signal_type : SIGNAL_TYPE = SIGNAL_TYPE.BODY ## Tipo de señal que utilizara el Interactable

@export_group("Dialog Interactions")
@export var dialog : DialogueResource ## Recurso de dialogo
@export var dialog_title : String
@export var extra_game_states : Array

@export_group("Custom behaviors")
@export var custom_visible_node : Node ## [b]Intercambia[/b] el estado de visibilidad del nodo asignado en este campo

var is_inside : bool
var interact_label : Label
var elements : Array

func custom_execute() : return ## [b]Funcion personalizada[/b] que se ejecutara al realizar la [b]interacción[/b]

func _ready() -> void:
	add_to_group("Interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	collshape = CollisionShape2D.new()
	collshape.shape = shape
	add_child(collshape)
	
	if toggle_childrens_visible :
		for x in get_children() :
			if x == collshape : continue
			elements.append(x)
	
	if !display_text.is_empty() :
		var label := Label.new()
		label.text = tr(display_text)
		label.visible = false
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if shape != null : 
			label.position.y -= shape.size.y / 4
			label.position.x -= shape.size.x / 2
		add_child(label)
		elements.append(label)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact") and is_inside:
		execute()

#Esta comprobación causa error al solo detectar cuerpos físicos e ignorar el resto de elementos que entran el en área
#E 0:00:01:001   emit_signalp: Error calling from signal 'body_entered' to callable: 'Area2D(interactable.gd)::_on_body_entered': Cannot convert argument 1 from Object to Object.

#func _on_body_entered(_body : CharacterBody2D) -> void :
	#if _body and !is_inside and signal_type == SIGNAL_TYPE.BODY:
		#toggle_visible(TOGGLE_MODE.SHOW)
		#is_inside = true

#func _on_body_exited(_body : CharacterBody2D) -> void :
	#if _body and is_inside and signal_type == SIGNAL_TYPE.BODY:
		#toggle_visible(TOGGLE_MODE.HIDE)
		#is_inside = false
		
func _on_body_entered(_body : Node2D) -> void :
	#mejor se comprueba dentro del if para evitar errores con el motor
	if _body is CharacterBody2D and !is_inside and signal_type == SIGNAL_TYPE.BODY:
		toggle_visible(TOGGLE_MODE.SHOW)
		is_inside = true

func _on_body_exited(_body : Node2D) -> void :
	if _body is CharacterBody2D and is_inside and signal_type == SIGNAL_TYPE.BODY:
		toggle_visible(TOGGLE_MODE.HIDE)
		is_inside = false

func _on_area_entered(_area : Area2D) -> void :
	if _area and !is_inside and signal_type == SIGNAL_TYPE.AREA:
		toggle_visible(TOGGLE_MODE.SHOW)
		is_inside = true

func _on_area_exited(_area: Area2D) -> void :
	if _area and is_inside and signal_type == SIGNAL_TYPE.AREA:
		toggle_visible(TOGGLE_MODE.HIDE)
		is_inside = false

func toggle_visible(_custom_mode : TOGGLE_MODE = TOGGLE_MODE.TOGGLE) -> void :
	var all_elements = elements.duplicate()
	if custom_visible_node != null : all_elements.append(custom_visible_node)

	if !all_elements.is_empty() :
		for node in all_elements :
			if custom_visible_node == null and node is not Control : continue
			match _custom_mode :
				TOGGLE_MODE.TOGGLE : node.visible = !node.visible
				TOGGLE_MODE.SHOW : node.show()
				TOGGLE_MODE.HIDE : node.hide()
				_ : node.visible = !node.visible

func execute() -> void :
	if dialog != null : 
		DialogueManager.show_dialogue_balloon(dialog, dialog_title, extra_game_states)
		is_inside = false
		if retoggable_inside : 
			DialogueManager.dialogue_ended.connect(func (_r) : is_inside = true, CONNECT_ONE_SHOT)
	custom_execute()
	
	executed.emit()
	
	if !show_again_at_end : toggle_visible(TOGGLE_MODE.HIDE)
	
	if destroy_at_end : 
		if dialog == null : queue_free()
		else : DialogueManager.dialogue_ended.connect(func (_r) : queue_free(), CONNECT_ONE_SHOT)

#endregion
