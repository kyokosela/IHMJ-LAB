extends InventoryContainer
class_name PlayerInventoryContainer
## Inventario del player con sistema de manos + mochila opcional

signal hands_changed
signal bag_equipped(size: int)
signal bag_unequipped(items_dropped: Array[Item])

@export_group("Hands")
@export var hands_size: int = 2  ## Siempre 2 manos

@export_group("Bag")
@export var initial_bag_size: int = 0  ## 0 = sin mochila al inicio
@export var max_bag_size: int = 10  ## Tamaño máximo de mochila

var _bag_size: int = 0
var _has_bag: bool:
	get: return _bag_size > 0

## Índices
var _hands_start: int = 0
var _bag_start: int:
	get: return hands_size

func _ready():
	super()
	_bag_size = initial_bag_size
	_setup_inventory()

func _setup_inventory():
	if inventory:
		inventory.size = hands_size + _bag_size
		inventory._initialize_slots()

#region Hands API
## Obtiene los índices de las manos
func get_hands_indices() -> Array[int]:
	return [0, 1] as Array[int]

## Obtiene los items en las manos
func get_hands_items() -> Array[Item]:
	var items: Array[Item] = []
	for i in get_hands_indices():
		var slot = inventory.slots[i]
		if not slot.is_empty():
			items.append(slot.item)
	return items

## Obtiene el item en una mano específica (0 o 1)
func get_hand_item(hand_index: int) -> Item:
	if hand_index < 0 or hand_index >= hands_size:
		return null
	var slot = inventory.slots[hand_index]
	return slot.item if not slot.is_empty() else null

## Añade un item a la primera mano disponible
func add_to_hands(item: Item) -> bool:
	for i in get_hands_indices():
		var slot = inventory.slots[i]
		if slot.is_empty():
			slot.item = item
			inventory.slot_changed.emit(i)
			inventory.inventory_changed.emit()
			hands_changed.emit()
			return true
	return false

## Verifica si hay espacio en las manos
func has_hands_space() -> bool:
	for i in get_hands_indices():
		if inventory.slots[i].is_empty():
			return true
	return false

## Cuenta manos libres
func free_hands_count() -> int:
	var count = 0
	for i in get_hands_indices():
		if inventory.slots[i].is_empty():
			count += 1
	return count

## Quita un item de las manos
func remove_from_hands(item: Item) -> bool:
	for i in get_hands_indices():
		var slot = inventory.slots[i]
		if not slot.is_empty() and slot.item == item:
			slot.clear()
			inventory.slot_changed.emit(i)
			inventory.inventory_changed.emit()
			hands_changed.emit()
			return true
	return false

## Quita el item de una mano específica
func clear_hand(hand_index: int) -> Item:
	if hand_index < 0 or hand_index >= hands_size:
		return null
	
	var slot = inventory.slots[hand_index]
	if slot.is_empty():
		return null
	
	var item = slot.item
	slot.clear()
	inventory.slot_changed.emit(hand_index)
	inventory.inventory_changed.emit()
	hands_changed.emit()
	return item
#endregion

#region Bag API
## Verifica si tiene mochila
func has_bag() -> bool:
	return _has_bag

## Obtiene el tamaño de la mochila
func get_bag_size() -> int:
	return _bag_size

## Obtiene los índices de la mochila
func get_bag_indices() -> Array[int]:
	var indices: Array[int] = []
	for i in range(_bag_size):
		indices.append(_bag_start + i)
	return indices

## Obtiene los items en la mochila
func get_bag_items() -> Array[Item]:
	var items: Array[Item] = []
	for i in get_bag_indices():
		var slot = inventory.slots[i]
		if not slot.is_empty():
			items.append(slot.item)
	return items

## Equipa una mochila
func equip_bag(size: int) -> void:
	if _has_bag:
		push_warning("PlayerInventoryContainer: Ya tiene una mochila equipada")
		return
	
	_bag_size = mini(size, max_bag_size)
	_setup_inventory()
	bag_equipped.emit(_bag_size)

## Desequipa la mochila y retorna los items que contenía
func unequip_bag() -> Array[Item]:
	if not _has_bag:
		return []
	
	var items = get_bag_items()
	
	# Limpiar slots de mochila
	for i in get_bag_indices():
		inventory.slots[i].clear()
	
	_bag_size = 0
	_setup_inventory()
	
	bag_unequipped.emit(items)
	return items

## Añade un item a la mochila
func add_to_bag(item: Item) -> bool:
	if not _has_bag:
		return false
	
	for i in get_bag_indices():
		var slot = inventory.slots[i]
		if slot.is_empty():
			slot.item = item
			inventory.slot_changed.emit(i)
			inventory.inventory_changed.emit()
			return true
	return false

## Verifica si hay espacio en la mochila
func has_bag_space() -> bool:
	if not _has_bag:
		return false
	
	for i in get_bag_indices():
		if inventory.slots[i].is_empty():
			return true
	return false
#endregion

#region Combined API
## Añade un item al primer espacio disponible (manos primero, luego mochila)
func add_item_anywhere(item: Item) -> bool:
	if add_to_hands(item):
		return true
	if add_to_bag(item):
		return true
	return false

## Verifica si hay espacio en cualquier lugar
func has_any_space() -> bool:
	return has_hands_space() or has_bag_space()

## Cuenta espacios libres totales
func total_free_space() -> int:
	var count = free_hands_count()
	if _has_bag:
		for i in get_bag_indices():
			if inventory.slots[i].is_empty():
				count += 1
	return count

## Obtiene todos los items (manos + mochila)
func get_all_player_items() -> Array[Item]:
	var items: Array[Item] = []
	items.append_array(get_hands_items())
	items.append_array(get_bag_items())
	return items

## Determina el tipo de slot
func get_slot_type(index: int) -> String:
	if index < 0 or index >= inventory.slots.size():
		return "invalid"
	
	if index < hands_size:
		return "hand"
	else:
		return "bag"
#endregion

#region Override
## Override para priorizar manos
func has_space_for(data: ItemData) -> bool:
	if rules and not rules.can_store(data):
		return false
	return has_any_space()

## Override add_item para usar add_item_anywhere
func add_item(item: Item) -> bool:
	if rules and not rules.can_store(item.data):
		return false
	return add_item_anywhere(item)
#endregion
