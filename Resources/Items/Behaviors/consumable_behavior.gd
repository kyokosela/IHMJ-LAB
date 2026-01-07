extends ItemBehavior
class_name ConsumableBehavior

const CONDITION_GOOD = preload("uid://xgsygm562hoc")
const CONDITION_BAD = preload("uid://bnjmcea38ho8i")
const CONDITION_ROTTEN = preload("uid://bilf2i6cga502")

@export var can_decay : bool = true

func can_use(_item: Item) -> bool:
	return true

func update_states(_item: Item) -> void:
	super(_item)
	if _item.condition > 40 and can_decay: _item.add_state(CONDITION_GOOD)
	elif _item.condition > 1 and can_decay: _item.add_state(CONDITION_BAD)
	elif can_decay: _item.add_state(CONDITION_ROTTEN)
	
	can_decay = true
	
	if _item.has_state("no_prepared"):
		can_decay = false
		
	if _item.has_state("cold") or _item.has_state("hot"):
		can_decay = false
	

func use(_item: Item) -> void:
	pass
