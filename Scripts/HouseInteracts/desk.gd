@tool
extends InteractableAction
## Escritorio. En la manana del tutorial, despues de comer, Mayui dice que ya no tiene nada que hacer ahi (event_messages,
## tus frases de DIALOGOS). Comer sentada ahi necesita su dibujo; antes de comer y despues del tutorial no hay textos.

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")

func execute() -> void:
	if Engine.is_editor_hint() or not ExitDoor.in_tutorial_morning() or not _has_eaten(): return
	super()

func check_events() -> bool:
	return false   # solo habla

func _has_eaten() -> bool:
	var meal : Task = TaskManager.get_task_list_res(ExitDoor.TUTORIAL_LIST).get_task_res("COOK")
	return meal != null and meal.task_done
