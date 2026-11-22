extends ItemBehavior
class_name ConsumableBehavior

const CONDITION_GOOD = preload("uid://xgsygm562hoc")
const CONDITION_BAD = preload("uid://bnjmcea38ho8i")
const CONDITION_ROTTEN = preload("uid://bilf2i6cga502")

func update_states(_item: Item) -> void:
	super(_item)
	if _item.condition > 40: _item.add_state(CONDITION_GOOD)
	elif _item.condition > 1: _item.add_state(CONDITION_BAD)
	elif can_decay: _item.add_state(CONDITION_ROTTEN)
	can_decay = true
	if _item.has_state("no_prepared"):
		can_decay = false
		
	if _item.has_state("cold") or _item.has_state("hot"):
		can_decay = false

func use(_item: Item) -> void:
	if !can_use(_item): return
	super(_item)
	# Completado: se descontaba del ItemData COMPARTIDO (data.uses): tras la primera comida ningun otro
	# objeto igual se podia usar. Los usos son de cada objeto (uses_left), como ya hacen HolderBehavior
	# y CraftingContainer.
	_item.uses_left -= 1
