@tool
extends InteractableTask

func custom_execute() -> void :
	TaskManager.done_task("TUTORIAL_DOOR", "BATHE")
	PlayerManager.remove_effect("DIRT")
	PlayerManager.decrease_stat("ENERGY", 10)
	print(PlayerManager.get_stat_value("ENERGY"))
