extends Resource
class_name CraftSlot

@export var item_id : String
@export var required_states: Array[String]
@export var item_return : ItemData

func matches(item: Item)-> bool:
	if item.data.item_unique_name != item_id:
		return false
	
	for state in required_states:
		if not item.has_state(state):
			return false
	
	return true
