@tool
extends InteractableAction
## Calendario. En la manana del tutorial, cada vez que Mayui lo mira dice lo siguiente de "readings" (tus textos de
## DIALOGOS) y, cuando ya los dijo todos, repite el aviso (event_messages). Para despues del tutorial no hay textos.

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")
const READ_FLAG := "calendar_read_%d"

@export var readings : Array[DialogicTimeline]

func execute() -> void:
	if Engine.is_editor_hint() or not ExitDoor.in_tutorial_morning(): return
	super()

## Mientras queden textos se leen; despues devuelve falso y sale el aviso de event_messages.
func check_events() -> bool:
	return _next_reading() < readings.size() and super()

func custom_execute() -> void:
	super()
	if Engine.is_editor_hint(): return
	var reading := _next_reading()
	NarrativeFlags.set_flag(READ_FLAG % reading)   # se recuerda aunque Mayui entre al bano y vuelva
	can_interact = false
	Dialogic.start(readings[reading])
	Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)

func _next_reading() -> int:
	var reading := 0
	while reading < readings.size() and NarrativeFlags.has_flag(READ_FLAG % reading):
		reading += 1
	return reading
