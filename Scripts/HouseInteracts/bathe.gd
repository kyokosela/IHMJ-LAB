@tool
extends InteractableAction

func custom_execute() -> void :
	super()
	# Agua fria mientras el tutorial siga en curso (no hay agua caliente "en el momento"); despues, caliente.
	var cold_water : bool = TaskManager.is_task_list_active("TUTORIAL_DOOR") and not TaskManager.is_task_list_done("TUTORIAL_DOOR")
	TaskManager.done_task("TUTORIAL_DOOR", "BATHE")
	PlayerManager.remove_effect("SMELLY")
	EventManager.reset_lapse_event("AUTO_SMELLY_LAPSE")
	PlayerManager.register_bath(cold_water)
