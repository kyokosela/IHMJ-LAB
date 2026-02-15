extends ConsumableBehavior
class_name Ingredients

const INAPETENCIA_EAT_SUCCESS_CHANCE : float = 0.50
const INAPETENCIA_EFFECTIVENESS_MULTIPLIER : float = 0.75

func update_states(_item: Item) -> void:
	super(_item)

func use(_item: Item) -> void:
	if _item.has_state("no_prepared"): return #nose

	var base_energy_gain : float = 30.0
	match _item.data.item_quality:
		ItemData.QUALITY.A:
			base_energy_gain = 42
		ItemData.QUALITY.B:
			base_energy_gain = 37.5
		ItemData.QUALITY.C:
			base_energy_gain = 30

	var has_inapetencia : bool = PlayerManager.has_effect("INAPETENCIA")
	if has_inapetencia and randf() > INAPETENCIA_EAT_SUCCESS_CHANCE:
		super(_item)
		return

	super(_item)

	if has_inapetencia:
		base_energy_gain *= INAPETENCIA_EFFECTIVENESS_MULTIPLIER

	PlayerManager.increase_stat("ENERGY", base_energy_gain)
	PlayerManager.remove_effect("HUNGER")
	EventManager.reset_lapse_event("AUTO_HUNGER_LAPSE")
	
	if _item.has_state("hot"):
		print("reducir estres 1 nivel")
	
	
