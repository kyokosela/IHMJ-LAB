extends Component
class_name MovementComponent

#region VARIABLES
signal movement_started
signal movement_stopped
signal direction_changed(new_direction : Vector2, prev_direction : Vector2)
signal velocity_changed(new_velocity: Vector2)

@export var speed : int = 200 ## Velocidad de movimiento
@export var can_move : bool = true ## Determina si la entidad puede moverse o no
@export_subgroup("Tile Movement")
@export var tile_based: bool = true ## Determina el tipo de movimiento, si es falso el movimiento sera libre/vectorial
@export_custom(PROPERTY_HINT_LAYERS_2D_PHYSICS, "Collision Mask") var raycast_mask : int = 1

var tile_size: Vector2: ## Determina que tanto se va a mover el jugador dependiendo del tamaño de los tiles.
	get: return GameManager.tile_size #Para acortar, en caso de que no lo quieran tener como una global solo quitar esto jasdj
var collision_raycast : RayCast2D ## Permite la colision
var x_direction : int = 0 ## Direccion en X | -1 , 0 , 1 |
var y_direction : int = 0 ## Direccion en Y | -1 , 0 , 1 |
var last_input_axis : Vector2 = Vector2.ZERO ## El eje del ultimo input recibido | (1,0), (0,1) |
var last_facing_dir : Vector2 = Vector2.ZERO ## Ultima direccion en la que la entidad quedo
var tile_destination : Vector2 = Vector2.ZERO ## Posicion a la que el entity interpola para movimiento suave
var is_moving : bool = false ## Determina si la entidad esta en movimiento o no

#variables para input buffer
var buffered_input: Vector2 = Vector2.ZERO
var inputbuffer_time: float = 0.2
var buffer_timer: float = 0.0

#endregion

#region DEFAULTS
func _initialize():
	tile_destination = entity.global_position
	assert(tile_destination != null,"Tile destination should not be NULL")
	if collision_raycast: return
	collision_raycast = RayCast2D.new()
	collision_raycast.enabled = true
	collision_raycast.exclude_parent = true
	collision_raycast.target_position = Vector2.ONE
	collision_raycast.collision_mask = raycast_mask
	collision_raycast.hit_from_inside = false
	add_child(collision_raycast)

func _ready() -> void:
	super()
	direction_changed.connect(func (x,y): print("direction changed: %s, %s" % [x,y]))
	call_deferred("_initialize")

func _physics_process(delta: float):
	if not entity:
		return
	if not is_enabled:
		return
	if not can_move:
		return
		
	if buffer_timer > 0:
		buffer_timer -= delta
		
		if buffer_timer <= 0:
			buffered_input = Vector2.ZERO
		
	apply_movement(delta)
#endregion

#region HANDLERS
func apply_movement(delta : float): ## Determina que tipo de movimiento se usara y maneja las señales
	var player = entity as Player
	var was_moving = is_moving
	var old_velocity = entity.velocity
	var direction = last_facing_dir
	if tile_based:
		tile_movement(delta)
	else:
		dynamic_movement(delta)
	if entity.velocity != old_velocity: velocity_changed.emit(entity.velocity)
	if direction != last_facing_dir: direction_changed.emit(direction, last_facing_dir)
	if is_moving and not was_moving:
		movement_started.emit()
	if was_moving and not is_moving:
		movement_stopped.emit()
	player.set_animation_direction(last_facing_dir)
	entity.move_and_slide()
	
func tile_movement(_delta: float) -> void: ## Maneja el movimiento basado por tiles
	var distance := entity.global_position.distance_to(tile_destination)
	
	## El sistema de detección de tiles planteado causa un pequeño delay en los inputs por los pixeles que 
	## tiene que detectar el jugador al pasar a cada tile, esto interfiere directamente con los fps
	## hay que usar un input buffer para amortiguarlo
	if distance <= 3.0:
		_snap_to_tile()
		_try_start_next_move()
	else:
		_move_towards_tile()

func dynamic_movement(delta:float): ## Maneja el movimiento libre/vectorial 
	var desired_direction = Vector2(x_direction,y_direction).normalized()
	if desired_direction.length() > 0:
		entity.velocity = lerp(entity.velocity, desired_direction * speed, delta)
		is_moving = true
	else:
		entity.velocity = lerp(entity.velocity, Vector2.ZERO, delta)
		is_moving = entity.velocity.length() > 1.0
#endregion

#region Util
func _snap_to_tile() -> void: ## Ajusta con un margen la posicion del player para que quede justo con el tilemap
	entity.global_position = tile_destination
	entity.velocity = Vector2.ZERO
	is_moving = false

func _try_start_next_move() -> void: ## Intenta empezar el siguiente movimiento verificando las colisiones
	var input_dir: Vector2 = Vector2.ZERO
	
	if buffered_input != Vector2.ZERO:
		input_dir = buffered_input
	else:
		input_dir = Vector2(x_direction, y_direction)
	
	if input_dir == Vector2.ZERO:
		return
		
	var next_step := _get_priority_step(input_dir)
	last_facing_dir = next_step
	
	if is_tile_blocked(next_step):
		buffered_input = Vector2.ZERO
		return
		
	tile_destination = entity.global_position + next_step * tile_size
	is_moving = true
	
	buffered_input = Vector2.ZERO
	buffer_timer = 0.0

func _get_priority_step(direction: Vector2) -> Vector2: ## Retorna la direccion por prioridad. La prioridad es determinada por el eje del ultimo input
	if last_input_axis.x != 0 and direction.x != 0:
		return Vector2(sign(direction.x), 0)
	if last_input_axis.y != 0 and direction.y != 0:
		return Vector2(0, sign(direction.y))
	if direction.x != 0:
		return Vector2(sign(direction.x), 0)
	return Vector2(0, sign(direction.y))

func _move_towards_tile() -> void:
	var move_dir : Vector2 = entity.global_position.direction_to(tile_destination)
	last_facing_dir = move_dir
	entity.velocity = move_dir * speed
	is_moving = true

func is_tile_blocked(next_step : Vector2) -> bool:
	collision_raycast.target_position = next_step * (tile_size)
	collision_raycast.force_raycast_update()
	if collision_raycast.is_colliding():
		return true
	return false

func set_direction(x_dir : int, y_dir: int):	
	var new_input = Vector2(x_dir, y_dir)
	
	if new_input != Vector2(x_direction, y_direction) and new_input != Vector2.ZERO:
		buffered_input = new_input
		buffer_timer = inputbuffer_time
		
		if x_dir != x_direction: 
			last_input_axis = Vector2(1, 0)
		elif y_dir != y_direction: 
			last_input_axis = Vector2(0, 1)
		
	x_direction = clamp(x_dir, -1,1)
	y_direction = clamp(y_dir, -1,1)

func stop():
	x_direction = 0
	y_direction = 0
	buffered_input = Vector2.ZERO
#endregion
