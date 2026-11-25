@tool
extends InteractableAction
## Puerta del balcon. En la manana del tutorial Mayui no sale: dice las frases de tu guion (DIALOGOS), puestas en
## event_messages. Despues, caminar hacia ella lleva al balcon.

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")

@export var destination : ZoneManager.ZONES = ZoneManager.ZONES.BALCONY

func check_events() -> bool:
	if not Engine.is_editor_hint() and ExitDoor.in_tutorial_morning():
		return false
	return super()

func custom_execute() -> void:
	super()
	if Engine.is_editor_hint(): return
	ZoneManager.change_zone(destination)
