extends ContainerUI
class_name KitchenUI
## @deprecated: Usar KitchenMultiUI para el nuevo sistema de cocina multi-estación
## Este archivo se mantiene por compatibilidad con escenas existentes que usen CraftingContainer
## Para nuevas implementaciones, usar KitchenContainer + KitchenMultiUI

@export var input_grid : Container
@export var result_grid : Container
@export var util_grid : Container
@export var player_grid : Container
@export var recipe_container : Container

var crafting_container : CraftingContainer

func open(p_container : InteractableContainer):
	super.open(p_container)
	crafting_container = current_container as CraftingContainer
	_update_recipes()
	_update_player_inventory()

func _connect_signals():
	super._connect_signals()
	if current_container is CraftingContainer:
		current_container.recipes_updated.connect(_update_recipes)
	
	if PlayerManager.player and PlayerManager.player.inventory:
		if not PlayerManager.player.inventory.inventory.inventory_changed.is_connected(_update_player_inventory):
			PlayerManager.player.inventory.inventory.inventory_changed.connect(_update_player_inventory)

func _disconnect_signals():
	super._disconnect_signals()
	if current_container is CraftingContainer and current_container.recipes_updated.is_connected(_update_recipes):
		current_container.recipes_updated.disconnect(_update_recipes)
		
	if PlayerManager.player and PlayerManager.player.inventory:
		if PlayerManager.player.inventory.inventory.inventory_changed.is_connected(_update_player_inventory):
			PlayerManager.player.inventory.inventory.inventory_changed.disconnect(_update_player_inventory)

func _update_items():
	# Override base to split items into grids based on index
	if not current_container: return
	
	_clear_grid(input_grid)
	_clear_grid(result_grid)
	_clear_grid(util_grid)
	
	var slots = current_container.inventory.slots
	var locked_indices = []
	if crafting_container:
		locked_indices = crafting_container.get_locked_indices()
	
	for i in range(slots.size()):
		var slot = slots[i]
		var slot_ui = slot_scene.instantiate()
		
		# Assign to correct grid
		if i == 0 or i == 1:
			input_grid.add_child(slot_ui)
		elif i == 2:
			result_grid.add_child(slot_ui)
		elif i >= 3 and i <= 5:
			util_grid.add_child(slot_ui)
		else:
			# Extra slots go to utils or ignored
			util_grid.add_child(slot_ui)
			
		if slot_ui is InventorySlotUI:
			slot_ui.slot_index = i
			slot_ui.parent_inventory = current_container.inventory
			
		slot_ui.set_item(slot.item)
		if i in locked_indices:
			slot_ui.set_locked(true)
		else:
			slot_ui.set_locked(false)

func _update_player_inventory():
	if not player_grid or not PlayerManager.player or not PlayerManager.player.inventory: return
	
	_clear_grid(player_grid)
	
	var slots = PlayerManager.player.inventory.get_slots()
	for i in range(slots.size()):
		var slot = slots[i]
		var slot_ui = slot_scene.instantiate()
		player_grid.add_child(slot_ui)
		
		if slot_ui is InventorySlotUI:
			slot_ui.slot_index = i
			slot_ui.parent_inventory = PlayerManager.player.inventory.inventory
			
		slot_ui.set_item(slot.item)

func _update_recipes():
	if not recipe_container or not crafting_container: return
	
	_clear_grid(recipe_container)
	
	var valid_recipes = crafting_container.get_valid_recipes()
	
	for entry in valid_recipes:
		var recipe : Crafts = entry.recipe
		var btn = Button.new()
		btn.text = "Craft " + recipe.result_item.item_name
		btn.pressed.connect(func(): crafting_container.craft(recipe))
		recipe_container.add_child(btn)

func _clear_grid(grid: Container):
	if grid:
		for child in grid.get_children():
			child.queue_free()
