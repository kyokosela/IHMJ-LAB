@tool
extends InteractableAction
## Escritorio, en la manana del tutorial:
## - "Mientras come": si Mayui llega con comida cocinada en las manos (la olla o la instantanea), come ahi: la pantalla se
##   oscurece un buen momento (la secuencia; falta su dibujo sentada) y come con tu sistema de objetos (Hambre, energia, tarea
##   de comer). Con la comida instantanea dice tu "No sabe a nada.". Tambien se puede seguir comiendo en la cocina (clic
##   derecho).
## - Antes de comer, sin comida: una frase que dice para que sirve (PROVISIONAL, _DESK_HINT_).
## - "Despues de comer": tus frases (event_messages).
## Despues del tutorial no hay textos.

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")
const HINT_LINE : String = "_DESK_HINT_"
const INSTANT_LINE : String = "_DESK_EATING_" ## "No sabe a nada.", solo para la comida instantanea
const FADE_SECONDS : float = 1.0 ## cuanto tarda en oscurecer y en aclarar al sentarse a comer
const EATING_SECONDS : float = 1.5 ## cuanto se queda oscuro mientras come

var _eating : bool = false

func execute() -> void:
	if Engine.is_editor_hint() or _eating or not ExitDoor.in_tutorial_morning(): return
	var hand : int = _cooked_food_in_hands()
	if hand >= 0:
		_eat(hand)
		return
	if not _has_eaten():
		can_interact = false
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], tr(HINT_LINE))
		Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)
		return
	super()

func check_events() -> bool:
	return false   # solo habla

## La mano con comida cocinada (suelta o dentro de la olla); -1 si no hay.
func _cooked_food_in_hands() -> int:
	if PlayerManager.player == null: return -1
	var inventory = PlayerManager.player.inventory
	for i in inventory.get_hands_indices():
		var slot = inventory.inventory.slots[i]
		if slot.is_empty(): continue
		var food : Item = slot.item.held_item if slot.item.held_item != null else slot.item
		if food.data.behavior is Ingredients and food.data.behavior.can_use(food):
			return i
	return -1

func _eat(hand: int) -> void:
	_eating = true
	can_interact = false
	GameManager.modal_count += 1   # quieta mientras come
	var held : Item = PlayerManager.player.inventory.inventory.slots[hand].item
	var food : Item = held.held_item if held.held_item != null else held
	var instant : bool = (food.data.behavior as Ingredients).meal_kind == "INSTANT"
	TransitionManager.fadeIn(FADE_SECONDS)
	await TransitionManager.transition_finished
	PlayerManager.player.inventory.use_item_at(hand)
	await get_tree().create_timer(EATING_SECONDS).timeout
	TransitionManager.fadeOut(FADE_SECONDS)
	await TransitionManager.transition_finished
	GameManager.modal_count -= 1
	_eating = false
	if instant:
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], tr(INSTANT_LINE))
		Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)
		return
	_on_ended_message()

func _has_eaten() -> bool:
	var meal : Task = TaskManager.get_task_list_res(ExitDoor.TUTORIAL_LIST).get_task_res("COOK")
	return meal != null and meal.task_done
