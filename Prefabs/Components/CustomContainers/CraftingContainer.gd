extends InventoryContainer
class_name CraftingContainer

@export var available_crafts : Array[Crafts]

var result : Item

func _ready():
	if inventory == null:
		inventory = InventoryComponent.new(3)
		add_child(inventory)

func get_craft_preview() -> Item:
	var current_items : Array[Item] = get_all_items()
	
	for recipe in available_crafts:
		if current_items.size() < recipe.needed_items.size(): continue
		var matched_indices : Array[int] = []
		
		if recipe.check_order:
			matched_indices = order_craft(recipe, current_items)
		else:
			matched_indices = unorder_craft(recipe, current_items)
		
		if not matched_indices.is_empty():
			var preview_item = recipe.result_item.duplicate()
			if recipe.result_state != null:
				preview_item.add_state(recipe.result_state) 
			return preview_item
	return null

func craft() -> void:
	var items : Array[Item] = get_all_items()
	for crafts in available_crafts:
		var match_indices = []
		if crafts.check_order: match_indices = order_craft(crafts, items)
		else: match_indices = unorder_craft(crafts, items)
	
		if match_indices.size() > 0:
			_execute_craft(crafts, match_indices)
			return

func _execute_craft(recipe, match_indices):
	for i in range(recipe.needed_items.size()):
		var slot_index : int = match_indices[i]
		var req : CraftSlot = recipe.needed_items[i]
		
		if req.item_return != null:
			var return_obj = req.item_return.duplicate()
			if req.state_return != null:
				return_obj.add_state(req.state_return)
			get_slot(slot_index).item = return_obj
		else:
			get_slot(slot_index).clear()
			
	var final_result = Item.new(recipe.result_item.duplicate())
	if recipe.result_state != null:
		final_result.add_state(recipe.result_state)
	
	result = final_result
	print("crafteo exitoso: ", result.data.item_unique_name)

func unorder_craft(crafts: Crafts, items: Array[Item]) -> Array[int]:
	var recipe_reqs = crafts.needed_items
	var used_indices : Array[int] = []
	
	for req in recipe_reqs:
		var found = false
		for j in range(items.size()):
			if j in used_indices: continue 
			
			if req.matches(items[j]):
				used_indices.append(j)
				found = true
				break 
				
		if not found: return []
	return used_indices

func order_craft(crafts : Crafts, items : Array[Item]) -> Array[int]:
	if items.size() < crafts.needed_items.size(): return []
	
	var used_indices : Array[int] = []
	for i in range(crafts.needed_items.size()):
		if crafts.needed_items[i].matches(items[i]):
			used_indices.append(i)
		else:
			return [] 
	return used_indices
	
	
