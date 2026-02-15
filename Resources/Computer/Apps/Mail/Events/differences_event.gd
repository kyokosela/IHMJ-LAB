extends MailEvent
class_name DifferencesEvent

@export_multiline var document_a: String = ""
@export_multiline var document_b: String = ""
@export var differences: Array[String] = []
@export var differences_to_find: int = 3

var found_differences: Array[String] = []

func execute(container: Control, data: MailEntry) -> void:
	var main_box := VBoxContainer.new()
	main_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(main_box)

	var docs_box := HBoxContainer.new()
	docs_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	docs_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_child(docs_box)

	docs_box.add_child(_create_document_panel("Version A", document_a))
	docs_box.add_child(VSeparator.new())
	docs_box.add_child(_create_document_panel("Version B", document_b))

	var input_box := VBoxContainer.new()
	main_box.add_child(input_box)

	var instruction := Label.new()
	instruction.text = "Encuentra %d diferencias:" % differences_to_find
	input_box.add_child(instruction)

	var controls := HBoxContainer.new()
	input_box.add_child(controls)

	var line_edit := LineEdit.new()
	line_edit.placeholder_text = "Describe una diferencia..."
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(line_edit)

	var submit := Button.new()
	submit.text = "Marcar"
	controls.add_child(submit)

	var found_label := Label.new()
	found_label.text = "Encontradas: 0/%d" % differences_to_find
	input_box.add_child(found_label)

	submit.pressed.connect(_check_difference.bind(line_edit, found_label, data))
	line_edit.text_submitted.connect(func(_new_text: String) -> void:
		_check_difference(line_edit, found_label, data)
	)

func _create_document_panel(title: String, content: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(250, 150)
	vbox.add_child(scroll)

	var content_label := RichTextLabel.new()
	content_label.bbcode_enabled = true
	content_label.text = content
	content_label.fit_content = true
	content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content_label)

	return panel

func _check_difference(line_edit: LineEdit, found_label: Label, data: MailEntry) -> void:
	var input_lower: String = line_edit.text.strip_edges().to_lower()
	if input_lower.is_empty():
		return

	for diff: String in differences:
		var diff_lower: String = diff.to_lower()
		if diff_lower in input_lower or input_lower in diff_lower:
			if diff not in found_differences:
				# Check for STRESS-induced oversight before confirming found difference
				if check_stress_failure():
					# STRESS caused player to second-guess correct answer
					line_edit.placeholder_text = "Hmm... no estoy segura..."
					line_edit.text = ""
					# Brief visual feedback
					line_edit.modulate = Color(1.0, 0.7, 0.5)
					await line_edit.get_tree().create_timer(0.3).timeout
					line_edit.modulate = Color(1, 1, 1, 1)
					return
				
				found_differences.append(diff)
				found_label.text = "Encontradas: %d/%d" % [found_differences.size(), differences_to_find]
				line_edit.text = ""
				line_edit.placeholder_text = "Correcto, siguiente..."
				if found_differences.size() >= differences_to_find:
					data.solve()
			return

	line_edit.placeholder_text = "No coincide con una diferencia valida..."
	line_edit.text = ""
