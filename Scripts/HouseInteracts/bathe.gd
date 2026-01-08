@tool
extends InteractableAction

func custom_execute() -> void :
	super()
	TaskManager.done_task("TUTORIAL_DOOR", "BATHE")
	PlayerManager.remove_effect("DIRT")
