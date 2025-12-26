extends Node2D
class_name InventoryComponent

signal item_added(item : Item, quantity: int)
signal item_removed(item : Item, quantity: int)
signal inventory_changed()
signal slot_changed(slot_index: int)

@export var size : int = 10
var slots : Array[InventorySlot] = []

#Hola, si ves este codigo, probablemente lo vibecodee por un crashout a nivel global, en todo caso
#lo revise y lo entendi a fondo gracias y perdon por todo. La IA va a dominar el mundo igualmente

func _init(p_size : int = 10):
	size = p_size

func _ready() -> void:
	_initialize_slots()

func _initialize_slots():
	slots.clear()
	for i in range(size):
		slots.append(InventorySlot.new())
		
func add_item(item : Item, quantity: int = 1) -> bool:
	if not item or quantity <= 0:
		return false
	
	var remaining = quantity
	if item.is_stackable:
		for i in range(slots.size()):
			var slot = slots[i]
			if slot.item == item and not slot.is_empty():
				remaining = slot.add(remaining)
				slot_changed.emit(i)
				if remaining <= 0:
					break
	
	if remaining > 0:
		for i in range(slots.size()):
			var slot = slots[i]
			if slot.is_empty():
				slot.item = item
				remaining = slot.add(remaining)
				slot_changed.emit(i)
				if remaining <= 0:
					break
	
	var added = quantity - remaining
	if added > 0:
		item_added.emit(item, added)
		inventory_changed.emit()
	return remaining <= 0

func remove_item(item : Item, quantity: int = 1) -> int:
	var to_remove = quantity
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.item == item and not slot.is_empty():
			var _removed = slot.remove(to_remove)
			to_remove -= _removed
			slot_changed.emit(i)
			if to_remove <= 0:
				break
	
	var removed = quantity - to_remove
	if to_remove > 0:
		item_removed.emit(item, removed)
		inventory_changed.emit()
	return removed
	
func remove_item_at(index : int, quantity: int = 1) -> int:
	if index < 0 or index > slots.size(): return 0
	
	var slot = slots[index]
	if slot.is_empty(): return 0
	
	var item_ref = slot.item
	var removed = slot.remove(quantity)
	
	if removed > 0:
		item_removed.emit(item_ref, removed)
		slot_changed.emit(index)
		inventory_changed.emit()
	return removed

func get_first_item(item_unique_name : String) -> Item:
	var items : Array[Item] = get_unique_items()
	for item in items:
		if item.item_unique_name == item_unique_name:
			return item
	return null

func count_item(item: Item) -> int:
	var total = 0
	for slot in slots:
		if slot.item == item:
			total += slot.quantity
	return total

func has_item(item : Item, quantity : int = 1) -> bool:
	return count_item(item) >= quantity

func is_empty() -> bool:
	return true if get_free_slot() == -1 else false

func get_free_slot() -> int:
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.is_empty(): return i
	return -1

func has_space_for(item : Item, quantity : int = 1) -> bool:
	var remaining = quantity
	for slot in slots:
		if slot.item == item and slot.can_add(remaining):
			remaining -= (item.max_stack - slot.quantity)
		elif slot.is_empty():
			remaining -= item.max_stack
		if remaining <= 0:
			return true
	return false

func transfer_to(other_inventory: InventoryComponent, item: Item, quantity: int = 1) -> bool:
	if not has_item(item, quantity):
		return false
	
	if other_inventory.add_item(item, quantity):
		remove_item(item, quantity)
		return true
	
	return false

func transfer_slot_to(other_inventory: InventoryComponent, slot_index: int, quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot = slots[slot_index]
	if slot.is_empty():
		return false
	
	var to_transfer = min(quantity, slot.quantity)
	
	if other_inventory.add_item(slot.item, to_transfer):
		remove_item_at(slot_index, to_transfer)
		return true
	
	return false

func swap_slots(slot_a: int, slot_b: int) -> bool:
	if slot_a < 0 or slot_a >= slots.size() or slot_b < 0 or slot_b >= slots.size():
		return false
	
	var temp = slots[slot_a]
	slots[slot_a] = slots[slot_b]
	slots[slot_b] = temp
	
	slot_changed.emit(slot_a)
	slot_changed.emit(slot_b)
	inventory_changed.emit()
	
	return true

func clear():
	for i in range(slots.size()):
		slots[i] = InventorySlot.new()
		slot_changed.emit(i)
	inventory_changed.emit()

func get_unique_items() -> Array[Item]:
	var unique: Array[Item] = []
	for slot in slots:
		if not slot.is_empty() and slot.item not in unique:
			unique.append(slot.item)
	return unique

func get_random_item() -> Item:
	return get_unique_items().pick_random()

# Serializar para guardar
func to_dict() -> Dictionary:
	var data = {
		"size": size,
		"slots": []
	}
	for slot in slots:
		if not slot.is_empty():
			data.slots.append({
				"item_id": slot.item.id,
				"quantity": slot.quantity
			})
		else:
			data.slots.append(null)
	return data

func from_dict(data: Dictionary, item_database: Dictionary):
	size = data.get("size", 20)
	_initialize_slots()
	
	var slot_data = data.get("slots", [])
	for i in range(min(slot_data.size(), slots.size())):
		if slot_data[i] != null:
			var item_id = slot_data[i].get("item_id", "")
			if item_database.has(item_id):
				slots[i].item = item_database[item_id]
				slots[i].quantity = slot_data[i].get("quantity", 0)
	
	inventory_changed.emit()
