@tool
@icon("res://Assets/CustomIcons/Interactable.png")
extends Area2D
class_name Interactable

#region SETUP

signal executed ## Se emite cuando el jugador realiza la [b]interacción[/b]
enum SIGNAL_TYPE {AREA, BODY}
enum TOGGLE_MODE {TOGGLE,SHOW,HIDE}
var collshape : CollisionShape2D
#booleana para codigo de seguridad
var index_code: bool = GameManager.index_code

## Rango de interaccion
@export_group("Behaviour")
@export var shape : Shape2D : 
	set(value) : shape = value; if Engine.is_editor_hint() : collshape.shape = shape
@export var display_text : String ## default: _INTERACT_BASE_MESSAGE_, Texto que se mostrara en pantalla al entrar en el rango del area, si esta vacio no mostrara nada
@export var children_visible : bool ## Si es [b]verdadero[/b] ocultara a todos los nodos de tipo [b]control[/b] que se encuentren como hijos
@export var reusable : bool ## La acción se podra realizar varias veces si es verdadera, en caso contrario la interacción solo se ejecutara una unica vez
@export var show_again_at_end : bool ## Mostrar elementos despues de acabar la ejecucion si es necesario
@export var destroy_at_end : bool ## Destruir al final de la ejecución
@export var signal_type : SIGNAL_TYPE = SIGNAL_TYPE.AREA ## Tipo de señal que utilizara el Interactable
@export var is_solid : bool
@export var collision_trigger : bool
@export_group("Time Interaction")
@export var consume_time: bool = false:
	set(value):
		consume_time = value
		notify_property_list_changed()
var time_consumption: String = " "
var random_time_range: bool = false:
	set(value):
		random_time_range = value
		notify_property_list_changed()
var random_initial_time: String = ""
var random_final_time: String = ""

@export_group("Dialog Interactions")
@export var dialog : DialogicTimeline ## Recurso de dialogo

@export_group("Custom behaviors")
@export var custom_visible_node : Node ## [b]Intercambia[/b] el estado de visibilidad del nodo asignado en este campo

var is_inside : bool
var can_interact : bool = true
var interact_label : Label
var elements : Array
var area_ref : Area2D
var body_ref : Node2D
var custom_expresion : Expression = Expression.new()

@export_group("DANGEROUS")
@export_custom(PROPERTY_HINT_EXPRESSION,"") var expresion : String = ""

func custom_execute(): return ## [b]Funcion personalizada[/b] que se ejecutara al realizar la [b]interacción[/b], USAR SUPER

func _ready() -> void:
	add_to_group("Interactable")
	
	custom_expression_handler()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	collshape = CollisionShape2D.new()
	collshape.shape = shape
	add_child(collshape)
	
	if is_solid :
		var collision = collshape.duplicate()
		var static_body := StaticBody2D.new()
		static_body.add_child(collision)
		add_child(static_body)
	
	if children_visible :
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

func custom_expression_handler()-> void:

	#validación de seguridad para indexación de código externo
	if not index_code:
		if !Engine.is_editor_hint():
			print_rich("[color=yellow][Security][/color] Indexación de código denegada para: ", name)
		return

	if expresion.strip_edges().is_empty():
		return

	var inputs : Dictionary = {
		"TimeManager": TimeManager,
		"EventManager": EventManager,
		"PlayerManager": PlayerManager,
		"GameManager": GameManager,
		"Dialogic": Dialogic
	}
	var error = custom_expresion.parse(expresion, inputs.keys())
	
	if error != OK: 
		print("Expression parse error", custom_expresion.get_error_text())

	else: 
		custom_expresion.execute(inputs.values(),self)

	if custom_expresion.has_execute_failed():
		push_error("Error de ejecución en la expresión" + name)
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact") and is_inside and can_interact and !collision_trigger:
		execute()
		
func _on_body_entered(_body : Node2D) -> void :
	#mejor se comprueba dentro del if para evitar errores con el motor
	if _body is Player and !is_inside and can_interact and signal_type == SIGNAL_TYPE.BODY:
		body_ref = _body
		toggle_visible(TOGGLE_MODE.SHOW)
		is_inside = true
		if collision_trigger : execute()

func _on_body_exited(_body : Node2D) -> void :
	if _body is Player and is_inside and can_interact and signal_type == SIGNAL_TYPE.BODY:
		body_ref = null
		toggle_visible(TOGGLE_MODE.HIDE)
		is_inside = false

func _on_area_entered(_area : Area2D) -> void :
	if _area.is_in_group("Interactor") and can_interact and !is_inside and signal_type == SIGNAL_TYPE.AREA:
		area_ref = _area
		toggle_visible(TOGGLE_MODE.SHOW)
		is_inside = true
		if collision_trigger : execute()

func _on_area_exited(_area: Area2D) -> void :
	if _area.is_in_group("Interactor") and can_interact and is_inside and signal_type == SIGNAL_TYPE.AREA:
		area_ref = null
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

func execute() -> void:
	can_interact = false
	consume_time_handler()
	if dialog != null : 
		Dialogic.start(dialog)
		if reusable: 
			Dialogic.timeline_ended.connect(func (): can_interact = true, CONNECT_ONE_SHOT)
	custom_execute()
	executed.emit()
	
	if !show_again_at_end : toggle_visible(TOGGLE_MODE.HIDE)
	
	if destroy_at_end : 
		if dialog == null : queue_free()
		else : Dialogic.timeline_ended.connect(func () : queue_free(), CONNECT_ONE_SHOT)

func consume_time_handler():
	if !consume_time: return
	if random_time_range: 
		var random_initial_int = TimeManager.get_minutes(random_initial_time)
		var random_final_int = TimeManager.get_minutes(random_final_time)
		
		var random_time = TimeManager.format_minutes(randi_range(random_initial_int, random_final_int))
		TimeManager.add_to_current_time(random_time)
	else:
		TimeManager.add_to_current_time(time_consumption)
#endregion


#region Export Handler
func _get_property_list() -> Array:
	var props: Array = []
	props.append({
		"name": "Time Interaction",
		"type": TYPE_NIL,
		"usage": PROPERTY_USAGE_GROUP
	})
	if consume_time:
		var time_usage = PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE
		if random_time_range:
			time_usage |= PROPERTY_USAGE_READ_ONLY
		props.append({
			"name": "time_consumption",
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
			"hint_string": "HH:MM",
			"usage": time_usage
		})
		props.append({
			"name": "random_time_range",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE
		})
		if random_time_range:
			props.append_array([
				{
					"name": "random_initial_time",
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
					"hint_string": "HH:MM",
					"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE
				},
				{
					"name": "random_final_time",
					"type": TYPE_STRING,
					"hint": PROPERTY_HINT_PLACEHOLDER_TEXT,
					"hint_string": "HH:MM",
					"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_STORAGE
				}
			])
	return props

func _set(property, value):
	match property:
		"time_consumption", "random_initial_time", "random_final_time":
			var cleaned = value.replace(" ", "")
			if cleaned.length() > 5:
				cleaned = cleaned.substr(0, 5)
			set(property, cleaned)
			return true
	return false


#endregion
