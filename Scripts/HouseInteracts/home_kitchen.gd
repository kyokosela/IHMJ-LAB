@tool
extends InteractableContainer
## La cocina del apartamento (nevera, mesa y estufa). En la manana del tutorial, antes de ducharse no se abre y Mayui dice
## tus frases del refrigerador (DIALOGOS), puestas en before_bath_messages; despues funciona como cualquier contenedor.

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")

@export var before_bath_messages : StringChain

func custom_execute() -> void:
	if not Engine.is_editor_hint() and before_bath_messages != null and _needs_bath():
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], before_bath_messages.get_message())
		Dialogic.timeline_ended.connect(func() -> void: can_interact = true, CONNECT_ONE_SHOT)
		return
	super()

func _needs_bath() -> bool:
	if not ExitDoor.in_tutorial_morning(): return false
	var bath : Task = TaskManager.get_task_list_res(ExitDoor.TUTORIAL_LIST).get_task_res("BATHE")
	return bath != null and not bath.task_done
