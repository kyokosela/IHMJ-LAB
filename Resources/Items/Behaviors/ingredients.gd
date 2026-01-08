extends ConsumableBehavior
class_name Ingredients

func update_states(_item: Item) -> void:
	super(_item)

func use(_item: Item) -> void:
	print("30 de energia")
	print("elimina hambre")
	if _item.has_state("hot"):
		print("reducir estres 1 nivel")
	print(_item.states)
	print(_item.get_custom_condition("coldness").value)
	
