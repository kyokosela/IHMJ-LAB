@tool
extends InteractableAction

@export var energy_cost : float = 10

func custom_execute() -> void :
	super()
	TaskManager.done_task("TUTORIAL_DOOR", "BATHE")
	PlayerManager.remove_effect("DIRT")
	PlayerManager.decrease_stat("ENERGY", energy_cost)
