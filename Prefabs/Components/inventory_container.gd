extends Component
class_name InventoryContainer

var inventory: InventoryComponent
@export var rules: ContainerRules
@export var environment : ContainerEnvironment

func _ready():
	for child in get_children():
		if child is InventoryComponent:
			inventory = child
			break
	assert(inventory != null, "InventoryContainer en '" + name + "' necesita un InventoryComponent (asignado o como hijo)")
	TimeManager.minutes_delta.connect(apply_decay)

#region LOGIC
#TODO: mover a container manager
func apply_decay(minutes: int):
	var items = get_all_items()
	if items.is_empty(): return 
	
	var env_conditions : Array[String] = environment.get_conditions()
	var env_properties : Array[String] = environment.get_properties()
	
	for item in items:
		item.apply_decay(minutes, env_conditions)
		item.apply_enviroment(minutes, env_properties)
#endregion

#region API

func add_item_by_data(data: ItemData) -> bool:
	if rules and not rules.can_store(data): return false
		
	if not inventory.has_space(): return false
		
	var new_item_instance = Item.new(data)
	
	return inventory.add_item_instance(new_item_instance)

func add_item(item: Item) -> bool:
	if rules and not rules.can_store(item.data):
		return false
	return inventory.add_item_instance(item)
	
func remove_item(item: Item) -> bool:
	return inventory.remove_item_instance(item)

func transfer_to(target: InventoryContainer, item: Item) -> bool:
	if not inventory.has_item_instance(item):
		return false
		
	if not target.has_space_for(item.data):
		return false
		
	return inventory.transfer_to(target.inventory, item)

func transfer_slot_to(target: InventoryContainer, slot_index: int) -> bool:
	var slot := get_slot(slot_index)
	if slot == null or slot.is_empty():
		return false
		
	var item_to_transfer = slot.item
	if target.has_space_for(item_to_transfer.data):
		return inventory.transfer_to(target.inventory, item_to_transfer)
		
	return false

#endregion

#region UTILS

func get_all_items() -> Array[Item]:
	return inventory.get_items()
	
func has_item(data: ItemData, amount := 1) -> bool:
	return inventory.count_item_data(data) >= amount

func count_item(data: ItemData) -> int:
	return inventory.count_item_data(data)

func has_space_for(data: ItemData) -> bool:
	if rules and not rules.can_store(data):
		return false
	return inventory.has_space()

func get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= inventory.slots.size():
		return null
	return inventory.slots[index]

func use_item_at(slot_index: int):
	var slot : InventorySlot = get_slot(slot_index)
	var item = slot.item
	var behavior = item.data.behavior
	print(item == null)
	if not behavior.can_use(item) or item.data.uses <= 0 or item == null: return
	behavior.use(item)
	if item.data.uses <= 0:
		if item.data.consume_after_use:
			inventory.remove_item_at(slot_index)

func get_slots() -> Array[InventorySlot]:
	return inventory.slots

func get_unique_items_data() -> Array[ItemData]:
	var data_list : Array[ItemData] = []
	for item in get_all_items():
		if not item.data in data_list:
			data_list.append(item.data)
	return data_list

func get_items_of(data : ItemData) -> Array[Item]:
	var result : Array[Item] = []
	for item in get_all_items():
		if item.data == data:
			result.append(item)
	return result

func get_item_by_data(data: ItemData) -> Item:
	for item in get_all_items():
		if item.data == data:
			return item
	return null

func get_item_instance_by_name(unique_name : String) -> Item:
	for item in get_all_items():
		if item.data.item_unique_name == unique_name:
			return item
	return null

func get_random_item() -> Item:
	var all = get_all_items()
	return all.pick_random() if not all.is_empty() else null

func is_empty() -> bool:
	return inventory.is_empty()
#endregion

func clear():
	inventory.clear()
