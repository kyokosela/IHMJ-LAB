extends ConsumableBehavior
class_name Ingredients

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

	# Inapetencia (SISTEMA_EFECTOS §3.2): probabilidad de fallar y energia recuperada segun su nivel.
	var eating : Dictionary = PlayerManager.get_inapetencia_eating()
	if eating.fail_chance > 0.0 and PlayerManager.rng.randf() < eating.fail_chance:
		super(_item)
		return

	super(_item)

	base_energy_gain *= eating.energy_mult

	PlayerManager.increase_stat("ENERGY", base_energy_gain)
	PlayerManager.remove_effect("HUNGER")
	EventManager.reset_lapse_event("AUTO_HUNGER_LAPSE")
	# Cuenta como comida casera para la Rutina saludable; servida caliente baja 1 nivel de Estres.
	PlayerManager.register_meal("HOME", _item.has_state("hot"))
