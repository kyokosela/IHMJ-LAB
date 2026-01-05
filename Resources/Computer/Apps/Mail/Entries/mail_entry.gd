extends Resource
class_name  MailEntry

signal completed

@export_category("Header")
@export var sender := "Coso"
@export var mail := "default@hola.com"
@export var icon: Texture2D
@export var subject := "No hay coso"

# TODO: añadir imagenes en content
@export_category("Content")
@export_multiline var content := ""
@export var event: MailEvent

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
