extends RefCounted
class_name InventorySlot

var item : Item
var quantity: int = 0

func _init(p_item : Item = null, p_quantity : int = 0) -> void:
	item = p_item
	quantity = p_quantity

func can_add(amount : int) -> bool:
	if not item:
		return true
	return item.is_stackable and quantity + amount <= item.max_stack

func add(amount: int) -> int: ## Retorna la cantidad que no alcanzo a caber, en caso de que no sobre nada retorna 0
	var space = item.max_stack - quantity if item else amount
	var added = min(amount, space)
	quantity += added
	return amount - added

func remove(amount : int) -> int: ## Retorna la cantidad que se logro eliminar, en caso de que se eliminen todos retorna quantity
	var removed = min(amount,quantity)
	quantity -= removed
	if quantity <= 0:
		item = null
		quantity = 0
	return removed

func is_empty() -> bool:
	return item == null or quantity <= 0
