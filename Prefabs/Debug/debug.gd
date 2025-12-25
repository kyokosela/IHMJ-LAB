extends Window

@onready var line_edit: LineEdit = %LineEdit
@onready var add_time: Button = %"Add Time"
@onready var remove_time: Button = %"Remove Time"
@onready var set_time: Button = %"Set Time"
@onready var current_time: RichTextLabel = %CurrentTime
@onready var current_day: RichTextLabel = %CurrentDay


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	current_time.text = "Current Timer: %s" % TimeManager.get_current_time()
	current_day.text = "Current Day: %s" % TimeManager.day


func _on_add_time_pressed() -> void:
	if TimeManager.is_valid_time(line_edit.text):
		TimeManager.add_to_current_time(line_edit.text)


func _on_remove_time_pressed() -> void:
	if TimeManager.is_valid_time(line_edit.text):
		TimeManager.substract_to_current_time(line_edit.text)


func _on_set_time_pressed() -> void:
	if TimeManager.is_valid_time(line_edit.text):
		TimeManager.set_current_time(line_edit.text)
