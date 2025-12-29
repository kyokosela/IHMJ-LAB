@tool
extends Interactable
class_name InteractableContainer

@export_group("Inventory")
@export var inventory_size: int = 10
@export var initial_items: Dictionary[ItemData, int] = {}
@export var rules: ContainerRules
@export var environment: ContainerEnvironment

var container: InventoryContainer

func _ready() -> void:
	super()
	
	container = InventoryContainer.new()
	add_child(container)
	
	container.inventory = InventoryComponent.new(inventory_size)
	container.rules = rules
	container.environment = environment
	
	for item in initial_items:
		print(container.add_item(item,initial_items[item]))
		

func custom_execute():
	if !area_ref: return
	
	# ola testeo de inventario quitar luego
	
	var other_entity = area_ref.get_parent().entity as Entity
	if !other_entity._has_inventory() or container.is_empty(): return
	
	print(other_entity.inventory.get_items(), " ", container.get_items())

	var random_item : ItemData = container.get_random_item()
	print(container.transfer_to(other_entity.inventory, random_item, 1))
	
	print(other_entity.inventory.get_items(), " ", container.get_items())
		
