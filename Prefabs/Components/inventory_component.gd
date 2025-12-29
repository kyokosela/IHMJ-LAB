extends Node2D
class_name InventoryComponent

signal item_added(item : ItemData, quantity: int)
signal item_removed(item : ItemData, quantity: int)
signal inventory_changed()
signal slot_changed(slot_index: int)

@export var size : int = 10

var slots : Array[InventorySlot] = []

#Hola, si ves este codigo, probablemente lo vibecodee por un crashout a nivel global, en todo caso
#lo revise y lo entendi a fondo gracias y perdon por todo. La IA va a dominar el mundo igualmente

func _init(p_size : int = 10):
	size = p_size
	_initialize_slots() # Se ejecuta inmediatamente al hacer .new()

func _initialize_slots():
	slots.clear()
	for i in range(size):
		slots.append(InventorySlot.new([], [], 99))
		
func add_item(data: ItemData, quantity: int = 1) -> bool:
	if not data or quantity <= 0:
		return false
	var instances : Array[Item] = []
	for i in range(quantity):
		instances.append(Item.new(data))

	return _add_instances(instances)

func _add_instances(instances: Array[Item]) -> bool:
	var remaining := instances.duplicate()
	
	for i in range(slots.size()):
		var slot = slots[i]
		if not remaining.is_empty() and slot.can_stack(remaining[0]):
			var leftover = slot.add_items(remaining)
			remaining = remaining.slice(remaining.size() - leftover, remaining.size())
			slot_changed.emit(i)

	if not remaining.is_empty():
		for i in range(slots.size()):
			var slot = slots[i]
			if slot.is_empty():
				var leftover = slot.add_items(remaining)
				remaining = remaining.slice(remaining.size() - leftover, remaining.size())
				slot_changed.emit(i)
				if remaining.is_empty():
					break
	if remaining.size() < instances.size():
		item_added.emit(instances[0].data, instances.size() - remaining.size())
		inventory_changed.emit()

	return remaining.is_empty()
	
func remove_item(data: ItemData, quantity: int = 1) -> int:
	var to_remove = quantity
	var removed_instances := []

	for i in range(slots.size()):
		var slot = slots[i]
		if slot.is_empty():
			continue

		var matching := []
		for inst in slot.items:
			if inst.data == data:
				matching.append(inst)

		if matching.is_empty():
			continue

		var remove_count = min(to_remove, matching.size())
		var removed = slot.remove(remove_count)
		removed_instances.append_array(removed)

		to_remove -= removed.size()
		slot_changed.emit(i)
		
		if to_remove <= 0:
			break
			
	if removed_instances.size() > 0:
		item_removed.emit(data, removed_instances.size())
		inventory_changed.emit()

	return removed_instances.size()

func remove_item_at(index: int, quantity: int = 1) -> Array[ItemData]:
	if index < 0 or index >= slots.size(): return []
	
	var slot = slots[index]
	if slot.is_empty(): return []

	var removed = slot.remove(quantity)

	if not removed.is_empty():
		item_removed.emit(removed[0].data, removed.size())
		slot_changed.emit(index)
		inventory_changed.emit()

	return removed

func get_first_item(item_unique_name : String) -> ItemData:
	var items : Array[ItemData] = get_unique_item_data()
	for item in items:
		if item.item_unique_name == item_unique_name:
			return item
	return null

func count_item(data: ItemData) -> int:
	var total := 0
	for slot in slots:
		for item in slot.items:
			if item.data == data:
				total += 1
	return total

func has_item(data: ItemData, quantity: int = 1) -> bool:
	return count_item(data) >= quantity

func is_empty() -> bool:
	for slot in slots:
		if not slot.is_empty():
			return false
	return true

func get_free_slot() -> int:
	for i in range(slots.size()):
		var slot = slots[i]
		if slot.is_empty(): return i
	return -1

func has_space_for(data: ItemData, quantity: int = 1) -> bool:
	var remaining = quantity
	
	for slot in slots:
		if slot.is_empty():
			remaining -= data.max_stack
		else:
			var slot_data = slot.items[0].data
			if slot_data == data and data.is_stackable:
				var current_count = slot.items.size()
				var space_in_slot = data.max_stack - current_count
				remaining -= space_in_slot
		if remaining <= 0:
			return true
			
	return false

func transfer_to(other: InventoryComponent, data: ItemData, quantity: int = 1) -> bool:
	if count_item(data) < quantity: return false
	
	var removed_instances : Array[Item]= []
	var to_remove = quantity

	for i in range(slots.size()):
		if to_remove <= 0: break

		var slot = slots[i]
		if slot.is_empty(): continue

		var matches := []
		for inst in slot.items:
			if inst.data == data:
				matches.append(inst)

		var count = min(to_remove, matches.size())
		var removed = slot.remove(count)
		removed_instances.append_array(removed)
		to_remove -= removed.size()
		slot_changed.emit(i)

	if removed_instances.is_empty():
		return false

	if other._add_instances(removed_instances):
		inventory_changed.emit()
		return true

	_add_instances(removed_instances) # Devuelve items si falla la transferencia
	return false

func transfer_slot_to(other: InventoryComponent, slot_index: int, quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var slot = slots[slot_index]
	if slot.is_empty():
		return false
	
	var removed = slot.remove(quantity)
	if removed.is_empty():
		return false
		
	if other._add_instances(removed):
		slot_changed.emit(slot_index)
		inventory_changed.emit()
		return true
	
	slot.items.append_array(removed)
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

func get_unique_item_data() -> Array[ItemData]:
	var unique : Array[ItemData] = []
	for slot in slots:
		if slot.is_empty():
			continue
		var data = slot.items[0].data
		if data not in unique:
			unique.append(data)
	return unique

func get_all_instances_of(data : ItemData) -> Array[Item]:
	var result : Array[Item] = []
	for slot in slots:
		for item in slot.items:
			if item.data == data:
				result.append(item)
	return result

func get_random_item() -> ItemData:
	if is_empty(): return null
	return get_unique_item_data().pick_random()

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
