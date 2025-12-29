extends MailEvent
class_name  ChoiceEvent

@export var options: Array[String]

func execute(container: Control, data: MailEntry) -> void:
	var l = Label.new()
	l.text = "selecciona coso: "
	container.add_child(l)
	
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i]
		container.add_child(btn)
		
		btn.pressed.connect(func():
			print("elegido ", i)
			data.solve()
		)
