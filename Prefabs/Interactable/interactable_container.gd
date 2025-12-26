@tool
extends Interactable
class_name InteractableContainer

@export var initial_items : Array[Item]:
	set(value):
		while Engine.is_editor_hint() and value.size() > inventory.size: 
			value.pop_back()
		initial_items = value

@export var inventory_size : int = 10

var inventory: InventoryComponent

func _ready() -> void:
	super()
	inventory = InventoryComponent.new(inventory_size)
	add_child(inventory)
	for item in initial_items:
		inventory.add_item(item,2)

func custom_execute():
	if area_ref:
		var other_entity = area_ref.get_parent().entity as Entity
		if !other_entity._has_inventory() or inventory.is_empty(): return
		var random_item : Item = inventory.get_random_item()
		print(inventory.transfer_to(other_entity.inventory, random_item, 1))
		
