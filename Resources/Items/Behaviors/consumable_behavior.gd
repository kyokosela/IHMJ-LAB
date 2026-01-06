extends ItemBehavior
class_name ConsumableBehavior

const CONDITION_GOOD = preload("uid://xgsygm562hoc")
const CONDITION_BAD = preload("uid://bnjmcea38ho8i")
const CONDITION_ROTTEN = preload("uid://bilf2i6cga502")

func can_use(_item: Item) -> bool:
	return true

func update_states(_item: Item) -> void:
	if _item.condition > 40: _item.add_state(CONDITION_GOOD)
	elif _item.condition > 1: _item.add_state(CONDITION_BAD)
	else: _item.add_state(CONDITION_ROTTEN)


func use(_item: Item) -> void:
	#quitar hambre o dar dependiendo del estado del item no se
	_item.condition -= 10
	print("item used: ", _item)
	print("item condition: ", _item.condition)
	print("item states: ", _item.states)
	used.emit()
