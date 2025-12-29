extends RigidBody2D
class_name MailInboxItem

signal opened(data: MailEntry)

var _mail_data: MailEntry

# TODO: setup all necessary values (text, sender, email, icon...)
func setup(data: MailEntry) -> void:
	_mail_data = data
	$Button.text = data.sender + ": " + data.subject
	%Button.pressed.connect(_on_pressed)
	
	if _mail_data.completed:
		modulate = Color(0.7, 0.7, 0.7)
	
func _on_pressed() -> void:
	opened.emit(_mail_data)
	
func launch(pos: Vector2) -> void:
	global_position = pos + Vector2(randf_range(-10, 10), 0)
	reset_physics_interpolation()
	apply_central_impulse(Vector2(0, 10))
