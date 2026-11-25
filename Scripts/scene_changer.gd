@icon("res://Assets/CustomIcons/door.png")
@tool
extends Area2D
class_name sceneChanger

var collshape : CollisionShape2D

@export var shape : Shape2D : 
	# en el editor, al abrir la escena, collshape todavia no existe (mismo cuidado que en Interactable)
	set(value) : shape = value; if Engine.is_editor_hint() and collshape : collshape.shape = shape

@export var new_scene_id : ZoneManager.ZONES

func _ready() -> void:
	collshape = CollisionShape2D.new()
	collshape.shape = shape
	add_child(collshape)
	body_entered.connect(change_scene)

func change_scene(_body) -> void : 
	if _body is Player :
		ZoneManager.change_zone(new_scene_id)
