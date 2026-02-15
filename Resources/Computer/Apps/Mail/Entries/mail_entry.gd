extends Resource
class_name  MailEntry

signal completed

@export_category("Identifier")
@export var id: String = ""

@export_category("Header")
@export var sender := "Coso"
@export var mail := "default@hola.com"
@export var icon: Texture2D
@export var subject := "No hay coso"

# TODO: añadir imagenes en content
@export_category("Content")
@export_multiline var content := ""
@export var event: MailEvent

@export_category("Scheduling")
@export var email_id: String = ""
@export var day_available: int = 1
@export var sender_type: String = ""

@export_category("Conditions")
@export var is_conditional: bool = false
@export var required_flags: Array[String] = []
@export var excluded_flags: Array[String] = []

var finished := false
var _opened := false

func open() -> void:
	if _opened: return
	_opened = true
		
	if event is LeaveEvent:
		var id = event.event_id
		print("evento coso", id)
		# aquí se emite la señal
				
func solve() -> void:
	if !finished: finished = true
	completed.emit()

func can_appear() -> bool:
	if TimeManager.day < day_available:
		return false

	if is_conditional:
		for flag: String in required_flags:
			if not NarrativeFlags.has_flag(flag):
				return false
		for flag: String in excluded_flags:
			if NarrativeFlags.has_flag(flag):
				return false

	return true
