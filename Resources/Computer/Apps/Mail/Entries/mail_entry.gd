extends Resource
class_name  MailEntry

signal completed

@export_category("Header")
@export var sender := "Coso"
@export var subject := "No hay coso"

@export_category("Content")
@export_multiline var content := ""
@export var event: MailEvent

var finished := false
var _opened := false

# TODO:Evitar que el evento se ejecute cada vez que se abre el mail.
func open() -> void:
	if not _opened: _opened = true
		
	if event is LeaveEvent:
		var id = event.event_id
		
		if not id.is_empty():
			print("evento coso", id)
			# aquí se emite la señal
				
func solve() -> void:
	if !finished: finished = true
	completed.emit()
