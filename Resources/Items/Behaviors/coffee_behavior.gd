extends ConsumableBehavior
class_name CoffeeBehavior

func update_states(_item: Item) -> void:
	super(_item)

func use(_item: Item) -> void:
	if _item.has_state("no_prepared"): return #nose
	super(_item)
	
	print("ola adogg")
	
	PlayerManager.add_effect(preload("uid://bjjg72x4dps63"))
	EventManager.create_lapse_event("02:00",func(): PlayerManager.remove_effect("HYPERACTIVE"),"COFFEE_HYPERACTIVE","Coffee HyperActive", false, true, true)
	
	if _item.has_state("hot"):
		var random = randi_range(0,5)
		if random == 3: print("reducir estres nivel 1")
	elif _item.has_state("cold"):
		PlayerManager.increase_stat("ENERGY", 10)
	
