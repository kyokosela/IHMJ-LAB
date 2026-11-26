@tool
extends InteractableContainer
## La cocina del apartamento (nevera, mesa y estufa). En la manana del tutorial no se abre antes de ducharse (tus frases del
## refrigerador, DIALOGOS, en before_bath_messages) ni con la toalla puesta (towel_messages); despues funciona como
## cualquier contenedor.

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")

@export var before_bath_messages : StringChain
@export var towel_messages : StringChain

func custom_execute() -> void:
	var lines : StringChain = null if Engine.is_editor_hint() else _lines_before_cooking()
	if lines != null:
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], lines.get_message())
		Dialogic.timeline_ended.connect(func() -> void: can_interact = true, CONNECT_ONE_SHOT)
		return
	super()

## Lo que dice Mayui si todavia no puede cocinar (null si ya puede).
func _lines_before_cooking() -> StringChain:
	if not ExitDoor.in_tutorial_morning(): return null
	var bath : Task = TaskManager.get_task_list_res(ExitDoor.TUTORIAL_LIST).get_task_res("BATHE")
	if bath != null and not bath.task_done: return before_bath_messages
	if PlayerManager.get_outfit_id() == "towel": return towel_messages
	return null
