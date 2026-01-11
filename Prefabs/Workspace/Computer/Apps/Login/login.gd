extends CanvasLayer
class_name LoginScreen

signal unlocked
signal lockout

@onready var input: LineEdit = %Input
@onready var submit_btn: Button = %SubmitBtn
@onready var error_label: Label = %ErrorLabel

var current_profile: DesktopProfile

var _attempts = 0
const MAX_ATTEMPTS = 5

func _ready() -> void:
	input.grab_focus()
	input.text_submitted.connect(_on_passwd_submitted)
	submit_btn.pressed.connect(func(): _on_passwd_submitted(input.text))

func setup(profile: DesktopProfile) -> void:
	current_profile = profile
	
func _on_passwd_submitted(passwd: String) -> void:
	if passwd == current_profile.password: 
		_unlock()
		return
	
	_attempts += 1
	input.grab_focus()
	
	SaveManager.save_data()
	
	var remaining = MAX_ATTEMPTS - _attempts
	if remaining <= 0: _lockout()
	else: _show_err("Coso incorrecto. Quedan %d intentos" % remaining)
	
	
func _unlock() -> void:
	_attempts = 0
	SaveManager.save_data()
	unlocked.emit()
	queue_free()

func _lockout() -> void:
	input.editable = false
	input.placeholder_text = "coso bloqueado"
	submit_btn.disabled = true
	error_label.text = "coso bloqueado jajaja"
	lockout.emit()
	

func _show_err(msg: String) -> void:
	error_label.show()
	error_label.text = msg
	input.clear()
