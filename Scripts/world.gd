extends Node
class_name World

var entities : Dictionary[String,Entity]

func _ready() -> void:
	for entity : Entity in find_children("*", "Entity"):
		entities[entity.name] = entity
		entity.world = self
		await entity.entity_ready
	
