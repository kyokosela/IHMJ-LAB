extends Node2D
class_name World

@export var zone_id : ZoneManager.ZONES

var entities : Dictionary[String,Entity]

signal entity_created(entity : Entity)
signal entity_removed(entity : Entity)

func _ready() -> void:
	
	ZoneManager.zone_node = self
	
	for entity : Entity in find_children("*", "Entity", true):
		entities[entity.name] = entity
		entity.world = self
		entity_created.emit(entity)

func kill_entity(entity: Entity) -> void:
	if !entities.has(entity): return
	entities.erase(entity)
	entity_removed.emit(entity)
	entity.queue_free()
