@tool
extends Interactable
class_name InteractableTask

@export var task_list : TaskList

func execute() -> void :
	if task_list.is_all_task_done() :
		super()
	else :
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], task_list.get_task_message())
