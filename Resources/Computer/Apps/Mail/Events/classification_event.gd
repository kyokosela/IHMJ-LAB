extends MailEvent
class_name ClassificationEvent

@export var documents: Array[String] = []
@export var categories: Array[String] = []
@export var correct_classifications: Array[int] = []

var current_doc_index: int = 0
var _doc_label: Label
var _feedback_label: Label

func execute(container: Control, data: MailEntry) -> void:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(vbox)

	var progress := Label.new()
	progress.name = "ProgressLabel"
	progress.text = "Documento 1/%d" % maxi(documents.size(), 1)
	vbox.add_child(progress)

	_doc_label = Label.new()
	_doc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_doc_label.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(_doc_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var instruction := Label.new()
	instruction.text = "Clasificar como:"
	vbox.add_child(instruction)

	var button_box := HBoxContainer.new()
	button_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(button_box)

	for i: int in range(categories.size()):
		var button := Button.new()
		button.text = categories[i]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_box.add_child(button)
		var category_index: int = i
		button.pressed.connect(_on_category_selected.bind(category_index, data, progress))

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_feedback_label)

	_show_current_document()

func _show_current_document() -> void:
	if current_doc_index < documents.size():
		_doc_label.text = documents[current_doc_index]
		_feedback_label.text = ""
		return

	_doc_label.text = "Clasificacion completada."

func _on_category_selected(category_index: int, data: MailEntry, progress: Label) -> void:
	if current_doc_index >= documents.size():
		return
	if current_doc_index >= correct_classifications.size():
		return

	if category_index == correct_classifications[current_doc_index]:
		# Check for STRESS-induced mistake before confirming correct classification
		if check_stress_failure():
			# STRESS caused a misclick - treat as error
			_feedback_label.text = "Error de concentracion..."
			_feedback_label.modulate = Color(0.9, 0.5, 0.2)  # Orange for stress error
			await _doc_label.get_tree().create_timer(0.5).timeout
			_feedback_label.text = ""
			return
		
		_feedback_label.text = "Correcto"
		_feedback_label.modulate = Color(0.2, 0.9, 0.2)
		current_doc_index += 1
		progress.text = "Documento %d/%d" % [mini(current_doc_index + 1, documents.size()), documents.size()]
		if current_doc_index >= documents.size():
			data.solve()
			return
		await _doc_label.get_tree().create_timer(0.4).timeout
		_show_current_document()
		return

	_feedback_label.text = "Incorrecto, intenta otra vez"
	_feedback_label.modulate = Color(0.9, 0.2, 0.2)
