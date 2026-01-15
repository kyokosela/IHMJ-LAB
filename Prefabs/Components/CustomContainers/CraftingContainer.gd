extends InventoryContainer
class_name CraftingContainer

@warning_ignore("unused_signal")
signal crafting_changed
signal craft_completed(result: Item)

@export var available_crafts : Array[Crafts]
@export var crafting_utils : Array[String]

var entity_container_ref : InventoryContainer
var current_craft : Crafts
var result : Item

#TODO: añadir los fokin return item de llos coffee mug (la olla desaparece mrc)

func _ready():
	super()

func add_util(util : String = ""):
	if util == "" or util in crafting_utils: return
	crafting_utils.append(util)

func remove_util(util : String = ""):
	if util == "" or util not in crafting_utils: return
	crafting_utils.erase(util)

func find_matching_craft(items: Array[Item], util: String = "") -> Dictionary:
	for recipe in available_crafts:
		var indices : Array[int] = []
		
		if recipe.check_order: indices = ordered_craft(recipe, items)
		else: indices = unordered_craft(recipe, items)
		
		if indices.is_empty(): continue
		
		if not _check_util(recipe, util): continue
		
		return {
			"recipe": recipe,
			"indices": indices
		}
	return {}

func craft(util: String = "") -> void:
	if entity_container_ref == null: return
	var matched = find_matching_craft(get_all_items(), util)
	
	if matched.is_empty():
		_cancel_cooking()
		return
	
	var recipe : Crafts = matched.recipe
	var indices : Array[int] = matched.indices
	
	if recipe.needed_time != "00:00":
		_start_cooking(recipe, indices)
	else:
		_execute_craft(recipe, indices)

func _start_cooking(recipe: Crafts, indices: Array[int]):
	if current_craft == recipe and EventManager.is_event_active("COOKING_TIME"):
		return
	EventManager.remove_event("COOKING_TIME")
	EventManager.create_lapse_event(
		recipe.needed_time,
		_execute_craft.bind(recipe, indices),
		"COOKING_TIME",
		"Cooking",
		false,
		true,
		true
	)
	current_craft = recipe

func _cancel_cooking():
	if EventManager.is_event_active("COOKING_TIME"):
		EventManager.remove_event("COOKING_TIME")
	current_craft = null

func _check_util(recipe: Crafts, util: String) -> bool:
	if recipe.needed_util == "" and util == "":
		return true
	return util == recipe.needed_util and util in crafting_utils

func _execute_craft(recipe : Crafts, match_indices):
	if result != null: print("craft override!!")
	for i in range(recipe.needed_items.size()):
		var slot_index : int = match_indices[i]
		var req : CraftSlot = recipe.needed_items[i]
		
		if req.item_return != null:
			var return_obj = Item.new(req.item_return.duplicate())
			var custom_conditions = get_slot(slot_index).item.data.custom_conditions
			return_obj.data.custom_conditions = custom_conditions
			get_slot(slot_index).item = return_obj
			transfer_slot_to(entity_container_ref,slot_index)
		else:
			get_slot(slot_index).clear()
			
	var final_result = Item.new(recipe.result_item.duplicate())
	
	result = final_result
	current_craft = null
	
	craft_completed.emit(result)
	print("crafteo exitoso: ", result.data.item_unique_name)

func unordered_craft(crafts: Crafts, items: Array[Item]) -> Array[int]:
	if items.size() < crafts.needed_items.size(): return []
	var recipe_reqs = crafts.needed_items
	var used_indices : Array[int] = []
	
	for req : CraftSlot in recipe_reqs:
		var found = false
		for j in range(items.size()):
			if j in used_indices: continue 
			
			if req.matches(items[j]):
				used_indices.append(j)
				found = true
				break 
				
		if not found: return []
	return used_indices

func ordered_craft(crafts : Crafts, items : Array[Item]) -> Array[int]:
	if items.size() < crafts.needed_items.size(): return []
	
	var used_indices : Array[int] = []
	for i in range(crafts.needed_items.size()):
		if crafts.needed_items[i].matches(items[i]):
			used_indices.append(i)
		else:
			return [] 
	return used_indices

func return_result(container : InventoryContainer):
	if result == null or container == null: return
	
	container.add_item(result)
	
	result = null
