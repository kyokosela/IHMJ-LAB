extends CharacterBody2D
class_name Entity

@export var entity_group : String ## unicamente servira como identificador

#region SETUP
signal entity_ready

var components : Dictionary[String,Component]
var world : World

var fsm : FSMComponent
var movement : MovementComponent
var sprite : SpriteComponent

func _ready() -> void:
	for component : Component in find_children("*", "Component"):
		add_component(component)
	_initialize()
	global_position = global_position.snapped(GameManager.tile_size) + GameManager.tile_size / 2
	entity_ready.emit()

func _initialize():
	fsm = get_component("FSMComponent")
	movement = get_component("MovementComponent")
	sprite = get_component("SpriteComponent")
#endregion

#region Entity API
func get_component(component_name : String) -> Component:
	if components.has(component_name):
		return components[component_name]
	return null

func get_all_components() -> Array[Component]:
	return components.values()

func add_component(component: Component) -> void:
	if !components.has(component.name):
		components[component.name] = component
		component.host = self
		if component.get_parent() != self: add_child(component)

func remove_component(component: Component) -> void:
	if component.has(component.name):
		components.erase(component.name)
		component.queue_free()

func kill_entity() -> void:
	world.kill_entity(self)
	queue_free()
#endregion


#region Sprite API 
func play_animation(anim_name : String):
	if _has_sprite(): sprite.play_animation(anim_name)

func set_animation_direction(direction :Vector2):
	if _has_sprite(): sprite.set_anim_direction(direction)

func has_preset(preset_name : String) -> bool:
	return sprite.has_preset(preset_name) and _has_sprite()

func change_preset(preset : SpritePreset) ->void:
	if _has_sprite(): sprite.change_preset(preset)

func change_preset_by_name(preset_name : String) -> void:
	if _has_sprite(): sprite.change_preset_by_name(preset_name)

func get_preset(preset_name : String) -> SpritePreset:
	return sprite.get_preset(preset_name) if _has_sprite() else null

func get_all_preset() -> Array[SpritePreset]:
	return sprite.get_all_preset() if _has_sprite() else []

func _has_sprite() -> bool:
	return sprite != null
	
func sprite_component() -> SpriteComponent:
	return sprite if _has_sprite() else null
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
	if _has_movement(): movement.set_direction(x_direction,y_direction)

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
