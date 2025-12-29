extends Resource
class_name ContainerRules

@export var allowed_types: Array[ItemData.TYPE] = []
@export var allow_unique_items := true

func can_store(item_data: ItemData, _amount: int = 1) -> bool:
	if allowed_types.size() > 0 and item_data.item_type not in allowed_types:
		return false

	if item_data.unique_item and not allow_unique_items:
		return false

	return true
