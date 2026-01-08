extends Node2D
class_name InventoryComponent

signal item_added(item: Item)
signal item_removed(item: Item)
signal slot_changed(slot_index: int)
signal inventory_changed

@export var size : int = 10
var slots : Array[InventorySlot] = []

func _init(p_size : int = 10):
	size = p_size
	_initialize_slots()

func _initialize_slots():
	slots.clear()
	for i in range(size):
		slots.append(InventorySlot.new(null,[ItemData.TYPE.UNDEFINED]))

#region ADD / REMOVE
func add_item(data: ItemData) -> bool:
	if not data: return false
	return add_item_instance(Item.new(data))

func add_item_instance(item: Item) -> bool:
	var slot_index = get_free_slot()
	if slot_index == -1: return false
	
	slots[slot_index].item = item
	item_added.emit(item)
	slot_changed.emit(slot_index)
	inventory_changed.emit()
	return true

func _add_instances(instances: Array[Item]) -> bool:
	var all_added = true
	for item in instances:
		if not add_item_instance(item):
			all_added = false
	return all_added

func remove_item_instance(item: Item) -> bool:
	for i in range(slots.size()):
		if not slots[i].is_empty() and slots[i].item == item:
			slots[i].clear()
			item_removed.emit(item)
			slot_changed.emit(i)
			inventory_changed.emit()
			return true
	return false

func remove_item_at(index: int) -> bool:
	if index < 0 or index >= slots.size(): return false
	var slot = slots[index]
	if slot.is_empty(): return false
	
	var item = slot.item[0]
	slot.item.clear()
	item_removed.emit(item)
	slot_changed.emit(index)
	inventory_changed.emit()
	return true

#endregion

#region UTILS

func get_items() -> Array[Item]:
	var result : Array[Item] = []
	for slot in slots:
		if not slot.is_empty():
			result.append(slot.item)
	return result

func get_first_item_by_name(unique_name : String) -> Item:
	for item in get_items():
		if item.data.item_unique_name == unique_name:
			return item
	return null

func count_item_data(data: ItemData) -> int:
	var total := 0
	for item in get_items():
		if item.data == data:
			total += 1
	return total

func has_space() -> int:
	var free_slots = 0
	for slot in slots:
		if slot.is_empty(): free_slots += 1
	return free_slots 

func get_free_slot() -> int:
	for i in range(slots.size()):
		if slots[i].is_empty(): return i
	return -1

#endregion

#region TRANSFER & SLOTS

func transfer_to(other: InventoryComponent, item: Item) -> bool:
	if not other.has_space(): return false
	
	if remove_item_instance(item):
		if other.add_item_instance(item):
			return true
		else:
			add_item_instance(item)
	return false

func swap_slots(slot_a: int, slot_b: int) -> bool:
	if slot_a < 0 or slot_a >= slots.size() or slot_b < 0 or slot_b >= slots.size():
		return false
	
	var temp_items = slots[slot_a].item
	slots[slot_a].item = slots[slot_b].item
	slots[slot_b].item = temp_items
	
	slot_changed.emit(slot_a)
	slot_changed.emit(slot_b)
	inventory_changed.emit()
	return true

func clear():
	for i in range(slots.size()):
		slots[i].item.clear()
		slot_changed.emit(i)
	inventory_changed.emit()

#endregion

#region PERSISTENCE

func to_dict() -> Dictionary:
	var data = {
		"size": size,
		"slots": []
	}
	for slot in slots:
		if not slot.is_empty():
			var item = slot.item
			data.slots.append({
				"item_unique_name": item.data.item_unique_name,
				"condition": item.condition,
			})
		else:
			data.slots.append(null)
	return data

func from_dict(dict_data: Dictionary, item_database: Dictionary):
	size = dict_data.get("size", size)
	_initialize_slots()
	
	var slot_data = dict_data.get("slots", [])
	for i in range(min(slot_data.size(), slots.size())):
		var entry = slot_data[i]
		if entry != null:
			var unique_name = entry.get("item_unique_name", "")
			if item_database.has(unique_name):
				var new_item = Item.new(item_database[unique_name])
				new_item.condition = entry.get("condition", 100.0)
				slots[i].item = new_item
	
	inventory_changed.emit()

#endregion
