extends MailEvent
class_name LeaveEvent

@export var event_id: String
@export var reply := "ya void"

func execute(container: Control, data: MailEntry) -> void:
	var l = Label.new()
	l.text = "INCIDENTE"
	l.modulate = Color(1, 0.3, 0.3)
	container.add_child(l)
	
	var btn = Button.new()
	btn.text = reply
	container.add_child(btn)
	
	btn.pressed.connect(func(): data.solve())
