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
var inventory : InventoryContainer

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
	inventory = get_component("InventoryContainer")
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

#region Inventory API 
func get_items() -> Array[Item]:
	return inventory.get_all_items() if _has_inventory() else []

func add_item_by_data(data : ItemData) -> void:
	if _has_inventory(): inventory.add_item_by_data(data)

func add_item(item: Item) -> bool:
	return _has_inventory() and inventory.add_item(item)
	
func remove_item(item: Item) -> bool:
	return _has_inventory() and inventory.remove_item(item)
	
func has_item(item_data: ItemData) -> bool:
	return _has_inventory() and inventory.has_item(item_data, 1)

func get_item_by_name(unique_name: String) -> Item:
	return inventory.get_item_instance_by_name(unique_name) if _has_inventory() else null

func get_item_by_data(data: ItemData) -> Item:
	return inventory.get_item_by_data(data) if _has_inventory() else null

func count_item(item_data: ItemData) -> int:
	return inventory.count_item(item_data) if _has_inventory() else 0

func get_inventory_size() -> int:
	return inventory.slots.size() if _has_inventory() else 0
	
func get_instances_of(item_data : ItemData) -> Array[Item]:
	return inventory.get_items_of(item_data) if _has_inventory() else []

func get_unique_content_data() -> Array[ItemData]:
	return inventory.get_unique_items_data() if _has_inventory() else []

func has_space_for(item_data: ItemData) -> bool:
	return _has_inventory() and inventory.has_space_for(item_data)
	
func transfer_item_to(target: InventoryContainer, item: Item) -> bool:
	return _has_inventory() and inventory.transfer_to(target, item)
	
func transfer_slot_to(target: InventoryContainer, index: int) -> bool:
	return _has_inventory() and inventory.transfer_slot_to(target, index)


func clear_inventory() -> void:
	if _has_inventory(): inventory.clear()
	
func _has_inventory() -> bool:
	return inventory != null

func inventory_container() -> InventoryContainer:
	return inventory 
	
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
