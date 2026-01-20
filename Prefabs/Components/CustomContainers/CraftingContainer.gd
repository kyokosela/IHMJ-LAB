extends InventoryContainer
class_name CraftingContainer

@warning_ignore("unused_signal")
signal crafting_changed
signal craft_completed(result: Item)
signal recipes_updated

@export var available_crafts : Array[Crafts]
@export var inherent_utils : Array[String] ## Utils provided by the furniture itself (e.g. "sink", "stove")

var entity_container_ref : InventoryContainer
var active_crafts : Dictionary = {} # event_name -> Dictionary { recipe, indices, util_index }
var locked_indices : Array[int] = [] # Indices of items currently being used in a craft

func _ready():
	super()
	if inventory:
		inventory.inventory_changed.connect(func(): recipes_updated.emit())

func _exit_tree():
	# If we leave the scene, we should ideally cancel or save state.
	# For now, we clean up the events to avoid crashes.
	cancel_all_crafts()

# Gets all utils available (both from the furniture and from items inside), checking locks
func find_util_index(util_name: String, exclude_indices: Array[int] = []) -> int:
	if util_name == "": return -1
	
	# Check inherent first (always available and index is -1)
	if util_name in inherent_utils:
		return -1
		
	# Check items
	for i in range(inventory.slots.size()):
		if i in exclude_indices or i in locked_indices: continue
		
		var slot = inventory.slots[i]
		if not slot.is_empty() and slot.item.data.has_util(util_name):
			return i
			
	return -2 # Not found

# Returns a list of all recipes that can be crafted right now
func get_valid_recipes() -> Array[Dictionary]:
	var valid_recipes : Array[Dictionary] = []
	var available_items = get_available_item_slots()
	
	for recipe in available_crafts:
		var util_idx = find_util_index(recipe.needed_util)
		if util_idx == -2 and recipe.needed_util != "": continue # Util missing
			
		var indices : Array[int] = []
		if recipe.check_order: 
			indices = ordered_craft(recipe, available_items)
		else: 
			indices = unordered_craft(recipe, available_items)
			
		if not indices.is_empty():
			valid_recipes.append({
				"recipe": recipe,
				"indices": indices
			})
			
	return valid_recipes

# Helper to get items that are NOT locked
func get_available_item_slots() -> Array[Dictionary]:
	var list : Array[Dictionary] = []
	for i in range(inventory.slots.size()):
		if i in locked_indices: continue
		
		var slot = inventory.slots[i]
		if not slot.is_empty():
			list.append({ "item": slot.item, "index": i })
	return list

func craft(recipe: Crafts = null) -> void:
	if entity_container_ref == null: return
	
	var matched : Dictionary = {}
	var available_items = get_available_item_slots()
	
	if recipe:
		# Verify specific recipe
		var util_idx = find_util_index(recipe.needed_util)
		if util_idx == -2 and recipe.needed_util != "": 
			return
			
		var indices : Array[int] = []
		if recipe.check_order: indices = ordered_craft(recipe, available_items)
		else: indices = unordered_craft(recipe, available_items)
		
		if not indices.is_empty():
			matched = {"recipe": recipe, "indices": indices, "util_index": util_idx}
	
	if matched.is_empty():
		return
	
	start_craft(matched.recipe, matched.indices, matched.util_index)

func start_craft(recipe: Crafts, indices: Array[int], util_index: int):
	# Generate unique event name
	var event_name = "CRAFT_%s_%d" % [recipe.result_item.item_unique_name, Time.get_ticks_msec() + randi()]
	
	# Lock resources
	locked_indices.append_array(indices)
	if util_index != -1:
		locked_indices.append(util_index)
	
	var craft_data = {
		"recipe": recipe,
		"indices": indices,
		"util_index": util_index
	}
	active_crafts[event_name] = craft_data
	
	recipes_updated.emit() # Update UI to show locks
	
	if recipe.needed_time != "00:00":
		EventManager.create_lapse_event(
			recipe.needed_time,
			_execute_craft.bind(recipe, indices, util_index, event_name),
			event_name,
			"Cooking " + recipe.result_item.item_name,
			false,
			true,
			true
		)
	else:
		_execute_craft(recipe, indices, util_index, event_name)

func cancel_all_crafts():
	for event_name in active_crafts.keys():
		EventManager.remove_event(event_name)
	active_crafts.clear()
	locked_indices.clear()
	recipes_updated.emit()

func _execute_craft(recipe : Crafts, match_indices: Array[int], util_index: int, event_name: String):
	# Cleanup state
	if active_crafts.has(event_name):
		active_crafts.erase(event_name)
	
	# Unlock indices
	for i in match_indices:
		locked_indices.erase(i)
	if util_index != -1:
		locked_indices.erase(util_index)
	
	# Consume Util if it was an item
	if util_index != -1:
		var slot = inventory.slots[util_index]
		if not slot.is_empty():
			slot.item.uses_left -= 1
			slot.item.item_changed.emit()
			if slot.item.uses_left <= 0:
				inventory.remove_item_at(util_index)

	# Consume Ingredients & Handle Returns
	for i in range(recipe.needed_items.size()):
		var slot_index : int = match_indices[i]
		var req : CraftSlot = recipe.needed_items[i]
		
		if req.item_return != null:
			var original_item = get_slot(slot_index).item
			var return_obj = req.create_return_item(original_item)
			if return_obj != null:
				return_obj.update_states()  # Asegurar estados actualizados
			get_slot(slot_index).item = return_obj
		else:
			get_slot(slot_index).clear()
			
	# Create Result
	var final_result = recipe.create_result(_get_items_from_indices(match_indices))
	final_result.update_states()  # Asegurar estados actualizados
	
	# Try to place result in Slot 2 (Result Slot) if empty, otherwise any slot
	if not _try_add_result(final_result):
		print("CraftingContainer: No space for result! Dropping/Destroying (TODO: Drop)")
	
	craft_completed.emit(final_result)
	print("Craft success: ", final_result.data.item_unique_name)
	recipes_updated.emit()
	inventory.inventory_changed.emit()

func _try_add_result(item: Item) -> bool:
	# Try specific result slot (Index 2)
	if inventory.size > 2 and inventory.slots[2].is_empty():
		inventory.slots[2].item = item
		inventory.slot_changed.emit(2)
		return true
	
	# Fallback to standard add
	return inventory.add_item_instance(item)

# Logic using Dictionary {item, index}
func unordered_craft(crafts: Crafts, available_items: Array[Dictionary]) -> Array[int]:
	if available_items.size() < crafts.needed_items.size(): return []
	
	var used_slot_indices : Array[int] = []
	var used_avail_indices : Array[int] = [] # Indices in available_items array
	
	for req : CraftSlot in crafts.needed_items:
		var found = false
		for j in range(available_items.size()):
			if j in used_avail_indices: continue 
			
			if req.matches(available_items[j].item):
				used_avail_indices.append(j)
				used_slot_indices.append(available_items[j].index)
				found = true
				break 
				
		if not found: return []
	return used_slot_indices

func ordered_craft(crafts : Crafts, available_items : Array[Dictionary]) -> Array[int]:
	if available_items.size() < crafts.needed_items.size(): return []
	
	# Ordered implies sequence in the *available* list? 
	# Or strict mapping? "Ordered" usually means "Shape" in grid.
	# Here we assume strict sequence in the provided list.
	# But available_items might be [Slot0, Slot3, Slot5].
	# If recipe needs [A, B]. Slot0=A, Slot3=B -> Valid.
	
	var used_slot_indices : Array[int] = []
	
	for i in range(crafts.needed_items.size()):
		if crafts.needed_items[i].matches(available_items[i].item):
			used_slot_indices.append(available_items[i].index)
		else:
			return [] 
	return used_slot_indices

func get_locked_indices() -> Array[int]:
	return locked_indices

func _get_items_from_indices(indices: Array[int]) -> Array[Item]:
	var items: Array[Item] = []
	for idx in indices:
		var slot = get_slot(idx)
		if slot and not slot.is_empty():
			items.append(slot.item)
	return items
