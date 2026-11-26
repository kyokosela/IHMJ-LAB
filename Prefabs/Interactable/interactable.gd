@tool
@icon("res://Assets/CustomIcons/Interactable.png")
extends Area2D
class_name Interactable

#region SETUP

signal executed ## Se emite cuando el jugador realiza la [b]interacción[/b]
const DOT_SIZE : float = 6.0 ## diametro, en el mundo, del punto sobre lo que se puede usar (en pantalla, 5 veces)
const DOT_PIXELS : int = 32 ## resolucion del dibujo del punto
const DOT_COLOR : Color = Color(1.0, 0.93, 0.72)
enum SIGNAL_TYPE {AREA, BODY}
enum TOGGLE_MODE {TOGGLE,SHOW,HIDE}
var collshape : CollisionShape2D
#booleana para codigo de seguridad
# Fix: Añadido Engine.is_editor_hint() para evitar acceder a GameManager en @tool mode antes de que los autoloads estén listos
var index_code: bool = GameManager.index_code if GameManager and not Engine.is_editor_hint() else false

## Rango de interaccion
@export_group("Behaviour")
# Fix: Añadido null check de collshape para prevenir errores de asignación de shape cuando collshape aún no está inicializado
@export var shape : Shape2D : 
	set(value) : shape = value; if Engine.is_editor_hint() and collshape: collshape.shape = shape
@export var display_text : String ## nombre del objeto: si no esta vacio, al tenerlo delante sale un punto sobre el
@export var children_visible : bool ## Si es [b]verdadero[/b] ocultara a todos los nodos de tipo [b]control[/b] que se encuentren como hijos
@export var reusable : bool ## La acción se podra realizar varias veces si es verdadera, en caso contrario la interacción solo se ejecutara una unica vez
@export var show_again_at_end : bool ## Mostrar elementos despues de acabar la ejecucion si es necesario
@export var destroy_at_end : bool ## Destruir al final de la ejecución
@export var signal_type : SIGNAL_TYPE = SIGNAL_TYPE.AREA ## Tipo de señal que utilizara el Interactable
@export var is_solid : bool
@export var collision_trigger : bool
## Completado: puertas. Son solidas y se usan caminando contra ellas (una vez por empujon); no hace falta Z.
@export var push_to_use : bool
## Completado: donde va el punto, desde el centro. En (0, 0) queda encima del objeto; cambiarlo si ahi cae sobre otro mueble.
@export var mark_offset : Vector2
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
var interact_mark : TextureRect ## el punto sobre el objeto
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
	
	if is_solid or push_to_use :
		var collision = collshape.duplicate()
		var static_body := StaticBody2D.new()
		static_body.add_child(collision)
		add_child(static_body)
	
	if children_visible :
		for x in get_children() :
			if x == collshape : continue
			elements.append(x)
	
	if !display_text.is_empty() :
		_add_mark()

## Completado: en vez de un cartel con el nombre, un punto suave y difuminado sobre lo que se puede usar (el dibujo ya dice que
## es). Es un Control para mostrarse y ocultarse con los demas.
func _add_mark() -> void:
	var degradado := Gradient.new()   # centro claro que se difumina; un borde apenas oscuro para verlo sobre fondos claros
	degradado.offsets = PackedFloat32Array([0.0, 0.4, 0.7, 1.0])
	degradado.colors = PackedColorArray([Color(DOT_COLOR, 0.85), Color(DOT_COLOR, 0.7), Color(0.3, 0.22, 0.1, 0.22), Color(0.3, 0.22, 0.1, 0.0)])
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.width = DOT_PIXELS
	textura.height = DOT_PIXELS
	textura.fill = GradientTexture2D.FILL_RADIAL
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(0.5, 0.0)
	interact_mark = TextureRect.new()
	interact_mark.texture = textura
	interact_mark.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var sin_sombra := CanvasItemMaterial.new()   # se ve igual a oscuras (la manana del tutorial)
	sin_sombra.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	interact_mark.material = sin_sombra
	interact_mark.size = Vector2(DOT_PIXELS, DOT_PIXELS)
	interact_mark.scale = Vector2.ONE * (DOT_SIZE / DOT_PIXELS)
	interact_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interact_mark.z_index = 10
	interact_mark.visible = false
	add_child(interact_mark)
	var arriba : float = shape.get_rect().position.y if shape != null else 0.0
	var centro : Vector2 = mark_offset if mark_offset != Vector2.ZERO else Vector2(0, arriba - DOT_SIZE / 2.0 - 1.0)
	interact_mark.position = centro - Vector2.ONE * DOT_SIZE / 2.0
	elements.append(interact_mark)

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
	if Engine.is_editor_hint(): return
	if event.is_action_pressed("Interact") and is_inside and can_interact and !collision_trigger and !push_to_use:
		# No interactuar mientras hay un dialogo o una UI modal abierta: si no, la misma Z
		# que usas para avanzar/cerrar vuelve a disparar la accion.
		if GameManager.is_input_blocked(): return
		execute()

## Completado: lo llama el movimiento de Mayui al caminar contra una puerta (push_to_use).
func pushed(who : Node) -> void:
	if push_to_use and who is Player and can_interact and not GameManager.is_input_blocked():
		execute()

# Completado: "estar delante" se anota siempre, este o no disponible la accion. Antes, apartarse justo mientras estaba ocupada
# (teclas deprisa) no se anotaba y quedaba pegada: su cartel fijo y Z en otro mueble hacia hablar a este.
func _on_body_entered(_body : Node2D) -> void :
	#mejor se comprueba dentro del if para evitar errores con el motor
	if _body is Player and !is_inside and signal_type == SIGNAL_TYPE.BODY:
		body_ref = _body
		is_inside = true
		if not can_interact: return
		toggle_visible(TOGGLE_MODE.SHOW)
		if collision_trigger : execute()

func _on_body_exited(_body : Node2D) -> void :
	if _body is Player and is_inside and signal_type == SIGNAL_TYPE.BODY:
		body_ref = null
		toggle_visible(TOGGLE_MODE.HIDE)
		is_inside = false

func _on_area_entered(_area : Area2D) -> void :
	if _area.is_in_group("Interactor") and !is_inside and signal_type == SIGNAL_TYPE.AREA:
		area_ref = _area
		is_inside = true
		if not can_interact: return
		toggle_visible(TOGGLE_MODE.SHOW)
		if collision_trigger : execute()

func _on_area_exited(_area: Area2D) -> void :
	if _area.is_in_group("Interactor") and is_inside and signal_type == SIGNAL_TYPE.AREA:
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
