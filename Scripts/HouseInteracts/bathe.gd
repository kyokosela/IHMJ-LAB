@tool
extends InteractableTask

func custom_execute() -> void :
	TaskManager.done_task("TUTORIAL_DOOR", "BATHE")
	PlayerManager.remove_effect("DIRT")
