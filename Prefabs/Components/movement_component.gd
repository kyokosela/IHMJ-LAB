extends Component
class_name MovementComponent

signal movement_started
signal movement_stopped
signal velocity_changed(new_velocity: Vector2)

@export var speed : int = 200
@export var can_move : bool = true
@export_subgroup("Tile Movement")
@export var tile_based: bool = true
@export var tile_size: Vector2:
	get: return tile_size * 1.5


var tile_map : TileMapLayer
var x_direction : int = 0
var y_direction : int = 0
var tile_destination : Vector2 = Vector2.ZERO
var is_moving : bool = false

func _ready() -> void:
	await super()
	tile_destination = entity.global_position
	tile_map = entity.tile_map
	assert(tile_destination != null,"Tile destination should not be NULL")
	

func _physics_process(delta: float):
	if not entity or not is_enabled or not can_move:
		return
	apply_movement(delta)

func apply_movement(delta : float): 
	var was_moving = is_moving
	var old_velocity = entity.velocity
	if tile_based:
		tile_movement(delta)
	else:
		dynamic_movement(delta)
	if entity.velocity != old_velocity: velocity_changed.emit(entity.velocity)
	if is_moving and not was_moving:
		movement_started.emit()
	if was_moving and not is_moving:
		movement_stopped.emit()
	entity.move_and_slide()

func tile_movement(delta: float):
	var distance_to_target = entity.global_position.distance_to(tile_destination)
	if distance_to_target <= 2.0:
		entity.global_position = tile_destination
		entity.velocity = Vector2.ZERO
		var input_dir = Vector2(x_direction, y_direction)
		if input_dir != Vector2.ZERO:
			var next_step = Vector2.ZERO
			if input_dir.x != 0:
				next_step = Vector2(input_dir.x, 0)
			else:
				next_step = Vector2(0, input_dir.y)
			var target_pos = entity.global_position + (next_step * tile_size)
			#if not is_tile_blocked(target_pos):
			tile_destination = target_pos
			is_moving = true
			#else:
				#is_moving = false 
		else:
			is_moving = false 
	else:
		var move_dir = entity.global_position.direction_to(tile_destination)
		entity.velocity = move_dir * speed
		is_moving = true

#func is_tile_blocked(target_pos: Vector2) -> bool:
#	pass

func dynamic_movement(delta:float):
	var desired_direction = Vector2(x_direction,y_direction)
	if desired_direction.length() > 0:
		entity.velocity = lerp(entity.velocity, desired_direction * speed, delta)
		is_moving = true
	else:
		entity.velocity = lerp(entity.velocity, Vector2.ZERO, delta)
		is_moving = entity.velocity.length() > 1.0

func set_direction(x_dir : int, y_dir: int):
	x_direction = x_dir
	y_direction = y_dir

func stop():
	x_direction = 0
	y_direction = 0

func get_current_speed() -> float:
	return entity.velocity.length()

func moving() -> bool:
	return is_moving
