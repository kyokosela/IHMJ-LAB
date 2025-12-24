extends Entity
class_name Player

var fsm : FSMComponent
var movement : MovementComponent
var sprite : SpriteStackComponent
var interaction : InteractionComponent
var colors = [Color(1.0, 0.0, 0.0, 1.0),
		  Color(0.0, 1.0, 0.0, 1.0),
		  Color(0.0, 0.0, 1.0, 0.0)]
func _ready() -> void:
	super()
	add_to_group("Player")
	_initialize()

func _initialize() -> void:
	fsm = get_component("FSMComponent")
	movement = get_component("MovementComponent")
	interaction = get_component("InteractionComponent")
	sprite = get_component("SpriteStackComponent")

func _process(_delta: float) -> void:
	set_animation_direction(facing_direction())

func random_color() -> Color:
	randomize()

	# Generate a random hue (0.0 to 1.0)
	var random_hue = randf()
	
	# Set saturation and value to full or near full for vibrant colors
	var saturation = 1.0 
	var value = 1.0

	# Create the color using the static method Color.from_hsv()
	var random_vibrant_color = Color.from_hsv(random_hue, saturation, value)
	
	return random_vibrant_color
#region Sprite API 
func set_animation_frame(idx: int):
	sprite.set_frame(idx)

func stop_animation():
	sprite.stop_animation()

func play_animation(anim_name : String):
	sprite.play_animation(anim_name)
	
func set_animation_direction(direction : Vector2):
	sprite.set_direction(direction)
	
func toggle_animation_layer(layer_name : String):
	sprite.toggle_layer(layer_name)
#endregion

#region Movement API
func can_move() -> bool:
	return movement.can_move and _has_movement()

func moving() -> bool:
	return movement.is_moving and _has_movement()

func is_tile_based() -> bool:
	return movement.tile_based and _has_movement()

func current_speed() -> float:
	return velocity.length() if _has_movement() else 0.0

func facing_direction() -> Vector2:
	return movement.last_facing_dir if _has_movement() else Vector2.ZERO

func last_input_axis() -> Vector2:
	return movement.last_input_axis if _has_movement() else Vector2.ZERO

func stop_move() -> void:
	if _has_movement(): movement.stop()

func set_direction(x_direction : int, y_direction : int) -> void:
	if _has_movement(): 
		movement.set_direction(x_direction,y_direction)

func set_facing_direction(direction : Vector2) -> void: ## Usar Vector2.UP, Vector2.LEFT etc... para mas facilidad
	if Utils.valid_single_dir_vector(direction):
		movement.last_facing_dir = direction
		movement.collision_raycast.target_position = direction * GameManager.tile_size
		movement.collision_raycast.force_raycast_update()
		movement.direction_changed.emit(movement.last_facing_dir, direction)
	else:
		push_error("Not a valid vector value")
		return

func _has_movement() -> bool:
	return movement != null

func move_component() -> MovementComponent:
	return movement if _has_movement() else null
#endregion

#region FSM API
func get_curr_state() -> State:
	return fsm.current_state if _has_fsm() else null

func get_curr_state_name() -> String:
	return fsm.current_state_name if _has_fsm() else ""

func get_states() -> Dictionary[String, State]:
	return fsm.states if _has_fsm() else {}

func change_state(state_name : String) -> void:
	if _has_fsm(): fsm.change_state(state_name)

func is_in_state(state_name : String) -> bool:
	return state_name == fsm.current_state_name and _has_fsm()

func _has_fsm() -> bool:
	return fsm != null
#endregion
