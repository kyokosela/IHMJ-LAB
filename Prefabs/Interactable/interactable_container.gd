@tool
extends Interactable
class_name InteractableContainer

@export_group("Inventory")
@export var initial_items: Array[ItemData]
@export var container_ui : ContainerUI
var container: InventoryContainer

func _ready() -> void:
	super()
	_find_container()
	if not Engine.is_editor_hint():
		assert(container != null, "ERROR: No hay InventoryContainer en " + name)
		if container:
			for item in initial_items:
				container.add_item_by_data(item)

func _find_container():
	for child in get_children():
		if child is InventoryContainer:
			container = child
			return
	container = null

func open_ui():
	if !container_ui: return
	container_ui.open(self)

func custom_execute():
	#container.open_container o algo para que salga la UI y que esta se encargue
	#de usar la api para cosas etc
	
	#craft testing, remover luego
	var crafting_container = container as CraftingContainer
	
	var player : Player = area_ref.get_parent().host
	
	
	player.transfer_slot_to(crafting_container,player.test_index)
	crafting_container.craft("chopping_board")
	crafting_container.craft("sink")
	crafting_container.craft("stove")
	crafting_container.craft()
	crafting_container.return_result(player.inventory)
	
	
	
	#open_ui()
