@tool
extends InteractableAction
## Calendario. Cada vez que Mayui lo mira dice lo siguiente de "readings" (tus textos de DIALOGOS).
## - En la manana del tutorial, cuando ya los dijo todos, repite el aviso (event_messages), que habla de salir ya.
## - Pasada la manana vuelve a decirlos, uno cada vez (PROVISIONAL, hasta que haya textos para el resto de la semana).

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")
const READ_FLAG := "calendar_read_%d"

@export var readings : Array[DialogicTimeline]

var _again : int = 0 ## cual toca releer cuando ya se dijeron todos

## Falso (sale el aviso de event_messages) solo en la manana y sin textos nuevos.
func check_events() -> bool:
	if ExitDoor.in_tutorial_morning() and _next_reading() >= readings.size(): return false
	return not readings.is_empty() and super()

func custom_execute() -> void:
	super()
	if Engine.is_editor_hint(): return
	var reading := _next_reading()
	if reading < readings.size():
		NarrativeFlags.set_flag(READ_FLAG % reading)   # se recuerda aunque Mayui entre al bano y vuelva
	else:
		reading = _again % readings.size()
		_again += 1
	can_interact = false
	Dialogic.start(readings[reading])
	Dialogic.timeline_ended.connect(_on_ended_message, CONNECT_ONE_SHOT)

func _next_reading() -> int:
	var reading := 0
	while reading < readings.size() and NarrativeFlags.has_flag(READ_FLAG % reading):
		reading += 1
	return reading
