extends Resource
class_name InventorySlot

@export var item: Item
@export var slot_type : Array[ItemData.TYPE]

func _init(p_item : Item = null, p_slot_type : Array[ItemData.TYPE] = [ItemData.TYPE.UNDEFINED]) -> void:
	item = p_item
	slot_type = p_slot_type

func can_add(new_item: Item) -> bool:
	if not is_empty(): return false
	if ItemData.TYPE.UNDEFINED in slot_type: return true
	
	return new_item.data.item_type in slot_type

func add_item(new_item: Item) -> bool:
	if not can_add(new_item): return false
	item = new_item
	return true

func clear() -> void:
	item = null

func is_empty() -> bool:
	return item == null
