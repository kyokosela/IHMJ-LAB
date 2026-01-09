extends ConsumableBehavior
class_name Ingredients

func update_states(_item: Item) -> void:
	super(_item)

func use(_item: Item) -> void:
	if _item.has_state("no_prepared"): return #nose
	
	super(_item)
	match _item.data.item_quality:
		ItemData.QUALITY.A: PlayerManager.increase_stat("ENERGY", 42)
		ItemData.QUALITY.B: PlayerManager.increase_stat("ENERGY", 37.5)
		ItemData.QUALITY.C: PlayerManager.increase_stat("ENERGY", 30)
	PlayerManager.remove_effect("HUNGER")
	EventManager.reset_lapse_event("AUTO_HUNGER_LAPSE")
	
	if _item.has_state("hot"):
		print("reducir estres 1 nivel")
	
	
