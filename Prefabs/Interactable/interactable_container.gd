@tool
extends Interactable
class_name InteractableContainer

@export_group("Inventory")
@export var container: InventoryContainer
@export var initial_items: Dictionary[ItemData, int]


func _ready() -> void:
	super()
	if container == null:
		container = InventoryContainer.new()
		add_child(container)
	
	for item in initial_items:
		container.add_item_by_data(item)

func custom_execute():
	#container.open_container o algo para que salga la UI y que esta se encargue
	#de usar la api para cosas etc
	var craft_container = container as CraftingContainer
	var player : Player = area_ref.get_parent().host
	
	if player.has_item(preload("uid://b364ksxd3tlh0")):
		player.transfer_slot_to(container,0)
	craft_container.craft()
