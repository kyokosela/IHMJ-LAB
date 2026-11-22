extends ConsumableBehavior
class_name CoffeeBehavior

func update_states(_item: Item) -> void:
	super(_item)

func use(_item: Item) -> void:
	if _item.has_state("no_prepared"): return #nose
	super(_item)
	
	# Check for INSOMNIA trigger before applying hyperactive (design: coffee at energy >= 90%)
	PlayerManager.check_coffee_insomnia_trigger()
	
	PlayerManager.apply_timed_hyperactive("COFFEE")   # reactivada estando activa -> Insomnio (D2)
	PlayerManager.coffee_relieves_hipersomnia()
	
	if _item.has_state("hot"):
		var random = PlayerManager.rng.randi_range(0,5)
		if random == 3:
			PlayerManager.mitigate_stress(1, "HOT_COFFEE")
	elif _item.has_state("cold"):
		PlayerManager.increase_stat("ENERGY", 10)
	
