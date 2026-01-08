extends Node2D
class_name World

@export var zone_id : ZoneManager.ZONES
@export var player_enabled : bool = true
@export var optional_camera_node : Camera2D

var entities : Dictionary[String,Entity]

signal entity_created(entity : Entity)
signal entity_removed(entity : Entity)

func _ready() -> void:
	
	ZoneManager.zone_node = self
	if player_enabled : 
		PlayerManager.player.reparent(self, false)
		
		for mark : SpawnPoint in get_tree().get_nodes_in_group("spawn_point") :
			if mark.entity == "Player" :
				PlayerManager.player.movement.tile_destination = mark.global_position
				PlayerManager.player.global_position = mark.global_position
		
		if optional_camera_node : optional_camera_node.reparent(PlayerManager.player, false)
	
	for entity : Entity in find_children("*", "Entity", true):
		entities[entity.name] = entity
		entity.world = self
		entity_created.emit(entity)

func kill_entity(entity: Entity) -> void:
	if !entities.has(entity): return
	entities.erase(entity)
	entity_removed.emit(entity)
	entity.queue_free()

func _exit_tree() -> void:
	optional_camera_node.reparent(self)
	PlayerManager.player.reparent(PlayerManager)
