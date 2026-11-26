extends ConsumableBehavior
class_name Ingredients

## Completado (comida instantanea, tu diseno): cuenta como comida "INSTANT" y da una energia fija; la casera ("HOME") da segun
## la calidad.
@export var meal_kind : String = "HOME"
@export var fixed_energy : float = 0.0 ## > 0: da esto en vez de la energia segun la calidad

func update_states(_item: Item) -> void:
	super(_item)

## Completado: solo se come lo cocinado (preparation "cooked"). Antes los ingredientes picados ("prepared") se comian igual que la
## comida, sueltos o desde la olla: daban la misma energia y marcaban la tarea COOK del tutorial.
func can_use(_item: Item) -> bool:
	return super(_item) and _item.has_state("cooked")

func use(_item: Item) -> void:
	if not can_use(_item): return

	var base_energy_gain : float = 30.0
	match _item.data.item_quality:
		ItemData.QUALITY.A:
			base_energy_gain = 42
		ItemData.QUALITY.B:
			base_energy_gain = 37.5
		ItemData.QUALITY.C:
			base_energy_gain = 30
	if fixed_energy > 0.0:
		base_energy_gain = fixed_energy

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
	# La casera cuenta para la Rutina saludable y servida caliente baja 1 nivel de Estres; la instantanea puede causarlo.
	PlayerManager.register_meal(meal_kind, _item.has_state("hot"))
	# Tutorial: comer es la tarea COOK de la puerta (igual que bathe.gd marca BATHE)
	if TaskManager.is_task_list_active("TUTORIAL_DOOR"):
		TaskManager.done_task("TUTORIAL_DOOR", "COOK")
