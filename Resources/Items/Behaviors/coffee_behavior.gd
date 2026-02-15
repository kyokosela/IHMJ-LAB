extends ConsumableBehavior
class_name CoffeeBehavior

func update_states(_item: Item) -> void:
	super(_item)

func use(_item: Item) -> void:
	if _item.has_state("no_prepared"): return #nose
	super(_item)
	
	# Check for INSOMNIA trigger before applying hyperactive (design: coffee at energy >= 90%)
	PlayerManager.check_coffee_insomnia_trigger()
	
	PlayerManager.add_effect(preload("uid://bjjg72x4dps63"))
	EventManager.create_lapse_event("02:00",func(): PlayerManager.remove_effect("HYPERACTIVE"),"COFFEE_HYPERACTIVE","Coffee HyperActive", false, true, true)
	
	if _item.has_state("hot"):
		var random = randi_range(0,5)
		if random == 3:
			PlayerManager.decrease_level_effect("STRESS", 1)
	elif _item.has_state("cold"):
		PlayerManager.increase_stat("ENERGY", 10)
	
