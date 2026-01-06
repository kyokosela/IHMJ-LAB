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
	
	container.inventory = InventoryComponent.new(inventory_size)
	container.rules = rules
	container.environment = environment
	
	add_child(container)
	
	for item in initial_items:
		container.add_item(item,initial_items[item])
