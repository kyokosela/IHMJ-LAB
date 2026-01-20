extends Node2D
class_name InventoryComponent

signal item_added(item: Item)
signal item_removed(item: Item)
signal slot_changed(slot_index: int)
signal inventory_changed

@export var size : int = 10
var slots : Array[InventorySlot] = []

## Flag para diferir la emisión de inventory_changed
var _defer_inventory_signal: bool = false
var _pending_inventory_signal: bool = false

func _ready() -> void:
	_initialize_slots()

func _initialize_slots():
	slots.clear()
	for i in range(size):
		slots.append(InventorySlot.new(null,[ItemData.TYPE.UNDEFINED]))

## Inicia un batch de operaciones (no emite inventory_changed hasta end_batch)
func begin_batch():
	_defer_inventory_signal = true
	_pending_inventory_signal = false

## Termina el batch y emite inventory_changed si hubo cambios
func end_batch():
	_defer_inventory_signal = false
	if _pending_inventory_signal:
		_pending_inventory_signal = false
		inventory_changed.emit()

## Emite inventory_changed o lo marca como pendiente si estamos en batch
func _emit_inventory_changed():
	if _defer_inventory_signal:
		_pending_inventory_signal = true
	else:
		inventory_changed.emit()

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
	_emit_inventory_changed()
	return true

func add_item_at(index: int, item: Item) -> bool:
	if index < 0 or index >= slots.size(): return false
	if not slots[index].is_empty(): return false
	
	slots[index].item = item
	item_added.emit(item)
	slot_changed.emit(index)
	_emit_inventory_changed()
	return true

func _add_instances(instances: Array[Item]) -> bool:
	begin_batch()
	var all_added = true
	for item in instances:
		if not add_item_instance(item):
			all_added = false
	end_batch()
	return all_added

func remove_item_instance(item: Item) -> bool:
	for i in range(slots.size()):
		if not slots[i].is_empty() and slots[i].item == item:
			slots[i].clear()
			item_removed.emit(item)
			slot_changed.emit(i)
			_emit_inventory_changed()
			return true
	return false

func remove_item_at(index: int) -> bool:
	if index < 0 or index >= slots.size(): return false
	var slot = slots[index]
	if slot.is_empty(): return false
	
	var item = slot.item
	slot.clear()
	item_removed.emit(item)
	slot_changed.emit(index)
	_emit_inventory_changed()
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

func get_first_item_by_data(data : ItemData) -> Item:
	for item in get_items():
		if item.data == data:
			return item
	return null

func count_item_data(data: ItemData) -> int:
	var total := 0
	for item in get_items():
		if item.data == data:
			total += 1
	return total

func has_item_instance(item : Item) -> bool:
	for i in get_items():
		if i == item: return true
	return false

func has_item_data(data : ItemData) -> bool:
	for i in get_items():
		if i.data == data: return true
	return false

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
	_emit_inventory_changed()
	return true

func interact_inventory(my_index: int, other_inventory: InventoryComponent, other_index: int) -> bool:
	if my_index < 0 or my_index >= slots.size(): return false
	if other_index < 0 or other_index >= other_inventory.slots.size(): return false
	
	var my_item = slots[my_index].item
	var other_item = other_inventory.slots[other_index].item
	
	# Simple swap/move logic
	slots[my_index].item = other_item
	other_inventory.slots[other_index].item = my_item
	
	# Emit signals
	slot_changed.emit(my_index)
	other_inventory.slot_changed.emit(other_index)
	_emit_inventory_changed()
	other_inventory._emit_inventory_changed()
	
	return true

func clear():
	begin_batch()
	for i in range(slots.size()):
		if not slots[i].is_empty():
			slots[i].clear()
			slot_changed.emit(i)
	end_batch()

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
				"uses_left": item.uses_left
			})
		else:
			data.slots.append(null)
	return data

func from_dict(dict_data: Dictionary, item_database: Dictionary):
	size = dict_data.get("size", size)
	_initialize_slots()
	
	begin_batch()
	var slot_data = dict_data.get("slots", [])
	for i in range(min(slot_data.size(), slots.size())):
		var entry = slot_data[i]
		if entry != null:
			var unique_name = entry.get("item_unique_name", "")
			if item_database.has(unique_name):
				var new_item = Item.new(item_database[unique_name])
				new_item.condition = entry.get("condition", 100.0)
				new_item.uses_left = entry.get("uses_left", new_item.data.uses)
				slots[i].item = new_item
	end_batch()

#endregion
