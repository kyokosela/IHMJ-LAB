extends Node2D
class_name World

@export var zone_id : ZoneManager.ZONES
@export var player_enabled : bool = true
@export var optional_camera_node : Camera2D
## Zoom de la camara automatica que se crea si la escena no trae una propia.
## Asi todas las zonas se ven al mismo tamano (Apartment.tscn usa 5 con su propia camara).
@export var default_camera_zoom : Vector2 = Vector2(5, 5)

var entities : Dictionary[String,Entity]

signal entity_created(entity : Entity)
signal entity_removed(entity : Entity)

func _ready() -> void:
	ZoneManager.zone_node = self
	if player_enabled :
		if optional_camera_node == null:
			var auto_camera := Camera2D.new()
			auto_camera.name = "AutoCamera"
			auto_camera.zoom = default_camera_zoom
			add_child(auto_camera)
			optional_camera_node = auto_camera
		PlayerManager.player.reparent(self, false)
		
		var spawn : SpawnPoint = _find_player_spawn()
		if spawn != null:
			PlayerManager.player.movement.tile_destination = spawn.global_position
			PlayerManager.player.global_position = spawn.global_position
		if optional_camera_node: optional_camera_node.reparent(PlayerManager.player, false)
	
	if PlayerManager.player: 
		entities["Player"] = PlayerManager.player
		entity_created.emit(PlayerManager.player)
		
	for entity : Entity in find_children("*", "Entity", true):
		entities[entity.name] = entity
		entity.world = self
		entity_created.emit(entity)

## Donde aparece Mayui: el punto marcado con la zona de la que viene (cerca de la puerta por la que salio);
## si no hay uno para esa zona, el general (from_zone = -1); y si tampoco, cualquiera de Mayui.
func _find_player_spawn() -> SpawnPoint:
	var general : SpawnPoint = null
	var any_player_spawn : SpawnPoint = null
	for mark : SpawnPoint in get_tree().get_nodes_in_group("spawn_point"):
		if mark.entity != "Player":
			continue
		any_player_spawn = mark
		if mark.from_zone >= 0 and mark.from_zone == ZoneManager.previous_zone:
			return mark
		if mark.from_zone < 0:
			general = mark
	return general if general != null else any_player_spawn

func kill_entity(entity: Entity) -> void:
	if !entities.has(entity): return
	entities.erase(entity)
	entity_removed.emit(entity)
	entity.queue_free()

## Devuelve la camara a esta escena y el Player al PlayerManager para que sobreviva al
## cambio de escena. Debe llamarse ANTES de cerrar la escena (ver ZoneManager.change_zone):
## hacerlo dentro de _exit_tree() reparenta nodos de un arbol que se esta destruyendo y
## el motor se cae (signal 11).
func release_player() -> void:
	if optional_camera_node and is_instance_valid(optional_camera_node) and optional_camera_node.get_parent() != self:
		optional_camera_node.reparent(self, false)
	var player := PlayerManager.player
	if player and is_instance_valid(player) and player.get_parent() == self:
		player.reparent(PlayerManager)

func _exit_tree() -> void:
	# Normalmente release_player() ya se llamo y esto no hace nada (es idempotente).
	release_player()
