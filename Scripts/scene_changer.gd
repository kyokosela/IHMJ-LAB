@icon("res://Assets/CustomIcons/door.png")
@tool
extends Area2D
class_name sceneChanger

var collshape : CollisionShape2D

@export var shape : Shape2D : 
	# en el editor, al abrir la escena, collshape todavia no existe (mismo cuidado que en Interactable)
	set(value) : shape = value; if Engine.is_editor_hint() and collshape : collshape.shape = shape

@export var new_scene_id : ZoneManager.ZONES
## Completado: puertas y escaleras de la casa y del edificio. Son solidas (Mayui no se mete en el dibujo) y se cruzan caminando
## contra ellas. Sin marcarlo, se cruzan al pisarlas.
@export var push_to_use : bool = false

func _ready() -> void:
	collshape = CollisionShape2D.new()
	collshape.shape = shape
	add_child(collshape)
	if push_to_use and not Engine.is_editor_hint():
		var solid := StaticBody2D.new()
		var solid_shape := CollisionShape2D.new()
		solid_shape.shape = shape
		solid.add_child(solid_shape)
		add_child(solid)
	else:
		body_entered.connect(change_scene)

func change_scene(_body) -> void :
	if _body is Player :
		ZoneManager.change_zone(new_scene_id)

## Lo llama el movimiento de Mayui al caminar contra ella (MovementComponent).
func pushed(who : Node) -> void:
	if push_to_use and not GameManager.is_input_blocked():
		change_scene(who)
