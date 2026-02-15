extends MailEvent
class_name TriviaEvent

@export var question: String = ""
@export var options: Array[String] = []
@export var correct_index: int = 0
@export var allow_multiple_attempts: bool = true

func execute(container: Control, data: MailEntry) -> void:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(vbox)

	var question_label := Label.new()
	question_label.text = question
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(question_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	for i: int in range(options.size()):
		var button := Button.new()
		button.text = options[i]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(button)
		var option_index: int = i
		button.pressed.connect(_on_option_selected.bind(option_index, button, data, vbox))

	if vbox.get_child_count() > 2:
		var first_button: Button = vbox.get_child(2) as Button
		if first_button:
			first_button.grab_focus()

func _on_option_selected(index: int, button: Button, data: MailEntry, box: VBoxContainer) -> void:
	if index == correct_index:
		# Check for STRESS-induced failure before confirming success
		if check_stress_failure():
			# STRESS caused a mistake - treat as wrong answer
			button.modulate = Color(0.9, 0.5, 0.2)  # Orange to indicate stress error
			if not allow_multiple_attempts:
				button.disabled = true
				return
			await button.get_tree().create_timer(0.5).timeout
			button.modulate = Color(1, 1, 1, 1)
			return
		
		# Success - correct answer and no stress failure
		button.modulate = Color(0.2, 0.9, 0.2)
		for child: Node in box.get_children():
			if child is Button:
				(child as Button).disabled = true
		data.solve()
		return

	button.modulate = Color(0.9, 0.2, 0.2)
	if not allow_multiple_attempts:
		button.disabled = true
		return

	await button.get_tree().create_timer(0.3).timeout
	button.modulate = Color(1, 1, 1, 1)
