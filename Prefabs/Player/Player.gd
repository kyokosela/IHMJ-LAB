extends Entity
class_name Player

var interaction : InteractionComponent
var inventory : PlayerInventoryContainer
@onready var spin_box: SpinBox = $CanvasLayer/Control/SpinBox

var test_index = 0

func _ready() -> void:
	super()
	add_to_group("Player")

func _initialize() -> void:
	super()
	
	inventory = get_component("PlayerInventoryContainer")
	
	interaction = get_component("InteractionComponent")
	
	Dialogic.timeline_started.connect(_on_dialogic_timeline_started)
	Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
	
func _on_dialogic_timeline_started():
	movement.can_move = false
	
func _on_dialogic_timeline_ended():
	movement.can_move = true

#TODO: borrar this shit :sob:
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test_2"):
		add_item_by_data(preload("uid://bmt41wvyxm0ut"))
		add_item_by_data(preload("uid://cy37p1h5j1xr1"))
		sprite.change_layer("body",preload("uid://cnwqcbdmj2h5j"))
	if event.is_action_pressed("test"):
		inventory.use_item_at(test_index)
		print(inventory.get_hands_items())


func _process(_delta: float) -> void:
	pass

func _on_spin_box_value_changed(value: float) -> void:
	test_index = value
	spin_box.focus_exited.emit()
	


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
	return _has_inventory() and inventory.has_item(item_data)

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
	

# MEME
#func random_color() -> Color:
	#randomize()
#
	## Generate a random hue (0.0 to 1.0)
	#var random_hue = randf()
	#
	## Set saturation and value to full or near full for vibrant colors
	#var saturation = 1.0 
	#var value = 1.0
#
	## Create the color using the static method Color.from_hsv()
	#var random_vibrant_color = Color.from_hsv(random_hue, saturation, value)
	#
	#return random_vibrant_color
