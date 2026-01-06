extends Component
class_name InventoryContainer

@export var inventory: InventoryComponent
@export var rules: ContainerRules
@export var environment : ContainerEnvironment

func _ready():
	if inventory == null:
		inventory = InventoryComponent.new()
		add_child(inventory)
	TimeManager.minutes_delta.connect(apply_decay)

#region LOGIC
func apply_decay(minutes: int):
	print(minutes)
	var items = get_all_items()
	if not items: return 
	for item : Item in items:
		print("item: ", item.data.item_unique_name, " | condition: ",item.condition)
		var decay_value : float = 0
		var base_decay : int = item.data.base_decay_time
		var quality : float = item.data.get_quality_percentage()
		var modifiers : Array[ConditionModifier] = item.data.modifiers
		var env_conditions : Array[String] = environment.get_conditions()
		
		for modifier : ConditionModifier in modifiers:
			if modifier.applies_to in env_conditions:
				decay_value = round( (minutes / (base_decay + (base_decay * quality)) * 100) * modifier.multiplier )
		if modifiers.is_empty(): decay_value = round( (minutes / (base_decay + (base_decay * quality)) * 100) )
		print(decay_value)
		item.condition -= decay_value # Test por ahora, no creo que mantenga la formula asi
		print("item: ", item.data.item_unique_name, " | condition: ",item.condition)
			
	
#endregion

#region API

func add_item(data: ItemData, amount := 1) -> bool:
	if rules and not rules.can_store(data, amount):
		return false
	return inventory.add_item(data, amount)

func remove_item(data: ItemData, amount := 1) -> int:
	return inventory.remove_item(data, amount)

func transfer_to(target: InventoryContainer,data: ItemData,amount := 1) -> bool:
	if not has_item(data, amount):
		return false
		
	if not target.has_space_for(data, amount):
		return false
		
	if inventory.transfer_to(target.inventory, data, amount):
		return true
		
	return false

func transfer_slot_to(target: InventoryContainer,slot_index: int,amount := 1) -> bool:
	var slot := get_slot(slot_index)
	if slot == null or slot.is_empty():
		return false
		
	if inventory.transfer_slot_to(target.inventory, slot_index, amount):
		return true
	return false

#endregion

#region UTILS

func get_all_items() -> Array[Item]:
	var item_slots = get_slots()
	var items : Array[Item]
	for slot : InventorySlot in item_slots:
		for item in slot.items:
			items.append(item)
	return items
	
func has_item(data: ItemData, amount := 1) -> bool:
	return inventory.has_item(data, amount)

func count_item(data: ItemData) -> int:
	return inventory.count_item(data)

func has_space_for(data: ItemData, amount := 1) -> bool:
	if rules and not rules.can_store(data, amount):
		return false
	return inventory.has_space_for(data, amount)

func get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= inventory.slots.size():
		return null
	return inventory.slots[index]

func get_slots() -> Array[InventorySlot]:
	return inventory.slots

func get_items() -> Array[ItemData]:
	return inventory.get_unique_item_data()

func get_items_of(item : ItemData) -> Array[Item]:
	return inventory.get_all_instances_of(item)

func get_item_by_name(unique_name : String) -> ItemData:
	var slots = get_slots() 
	for slot in slots:
		if slot.is_empty(): continue
		var data = slot.items[0].data
		if data.item_unique_name == unique_name:
			return data
	return null

func get_random_item() -> ItemData:
	return get_items().pick_random()
	
func get_random_item_list(quantity : int = 2) -> Array[ItemData]:
	if quantity < 0: return []
	var items : Array[ItemData] = []
	for i in range(quantity):
		items.append(get_random_item())
	return items

func is_empty() -> bool:
	return inventory.is_empty()
#endregion

#region CLEAR

func clear():
	inventory.clear()
#endregion
