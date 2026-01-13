extends InventoryContainer
class_name CraftingContainer

signal _crafting_changed

@export var available_crafts : Array[Crafts]
@export var crafting_utils : Array[String]

var current_craft : Crafts
		
var result : Item

func _ready():
	super()

func get_craft_preview(util : String = "") -> Item:
	var current_items : Array[Item] = get_all_items()
	for recipe in available_crafts:
		var matched_indices : Array[int] = []
		var util_check : bool
		
		if recipe.check_order:
			matched_indices = ordered_craft(recipe, current_items)
		else:
			matched_indices = unordered_craft(recipe, current_items)
		
		util_check = util == recipe.needed_util
		
		if matched_indices.size() > 0 and util_check:
			var preview_item = recipe.result_item.duplicate()
			return preview_item
	return null

func craft(util : String = "") -> void:
	var items : Array[Item] = get_all_items()
	for crafts in available_crafts:
		var match_indices : Array[int] = []
		var util_check : bool
		
		if crafts.check_order: match_indices = ordered_craft(crafts, items)
		else: match_indices = unordered_craft(crafts, items)
		
		util_check = util == crafts.needed_util and util in crafting_utils
		if util == "" and crafts.needed_util == "": util_check = true
		
		print(crafts.result_item.item_name, match_indices,util_check)
		
		if match_indices.size() >= crafts.needed_items.size() and util_check:
			if crafts.needed_time != "00:00":
				if current_craft != crafts: EventManager.remove_event("COOKING_TIME")
				EventManager.create_lapse_event(crafts.needed_time,_execute_craft.bind(crafts,match_indices),"COOKING_TIME", "Cooking",false, true, true)
				current_craft = crafts
			else:
				EventManager.remove_event("COOKING_TIME")
				_execute_craft(crafts, match_indices)
			return
	if EventManager.is_event_active("COOKING_TIME"): EventManager.remove_event("COOKING_TIME")

func _execute_craft(recipe : Crafts, match_indices):
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
	
	
	result = final_result
	current_craft = null
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
	
	add_item(result)
	transfer_to(container,result)
	
	result = null
