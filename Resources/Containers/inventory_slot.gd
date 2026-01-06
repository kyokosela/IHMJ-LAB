extends RefCounted
class_name InventorySlot

var items: Array[Item] = []
var slot_type : Array[ItemData.TYPE] #unused por ahora
var max_stack := 10

func _init(p_slot_type : Array[ItemData.TYPE] = [ItemData.TYPE.UNDEFINED], p_item : Array[Item] = [], p_max_stack : int = 1) -> void:
	items = p_item
	max_stack = p_max_stack
	slot_type = p_slot_type

func can_add(amount: int) -> bool:
	return items.size() + amount <= max_stack

func add_items(new_items: Array[Item]) -> int: ## Retorna la cantidad que no alcanzo a caber, en caso de que no sobre nada retorna 0
	if new_items.is_empty():
		return 0
		
	var current_max_stack = new_items[0].data.max_stack if new_items[0].data else 99
	
	var space : int = current_max_stack - items.size()
	var added : int = min(space, new_items.size())

	for i in range(added):
		items.append(new_items[i])

	return new_items.size() - added

func remove(amount: int) -> Array[Item]: ## Retorna la cantidad que se logro eliminar, en caso de que se eliminen todos retorna quantity
	var removed : Array[Item] = []
	for i in range(min(amount, items.size())):
		removed.append(items.pop_back())
	return removed

func can_stack(item: Item) -> bool:
	if is_empty():
		return true
	
	return (
		items[0].data == item.data 
		and item.data.is_stackable 
		and items.size() < item.data.max_stack 
	)

func is_empty() -> bool:
	return items.is_empty()
