extends Control
class_name ContainerUI

@export var slot_scene : PackedScene
@export var grid_container : Container

var current_container : InventoryContainer

func open(p_container : InteractableContainer):
	if current_container:
		_disconnect_signals()
	
	current_container = p_container.container
	if not current_container: return
	
	_connect_signals()
	_update_ui()
	
	visible = true

func close():
	_disconnect_signals()
	current_container = null
	visible = false

func _connect_signals():
	if current_container.inventory:
		current_container.inventory.inventory_changed.connect(_update_items)

func _disconnect_signals():
	if not current_container: return
	
	if current_container.inventory and current_container.inventory.inventory_changed.is_connected(_update_items):
		current_container.inventory.inventory_changed.disconnect(_update_items)

func _update_ui():
	_update_items()

func _update_items():
	if not grid_container or not slot_scene: return
	
	# Clear existing slots
	for child in grid_container.get_children():
		child.queue_free()
	
	# Create new slots
	var slots = current_container.get_slots()
	for i in range(slots.size()):
		var slot_data = slots[i]
		var slot_ui = slot_scene.instantiate()
		grid_container.add_child(slot_ui)
		
		if slot_ui is InventorySlotUI:
			slot_ui.slot_index = i
			slot_ui.parent_inventory = current_container.inventory
			slot_ui.set_item(slot_data.item)
		elif slot_ui.has_method("display_item"):
			slot_ui.display_item(slot_data.item)
		elif slot_ui.has_method("set_item"):
			slot_ui.set_item(slot_data.item)
