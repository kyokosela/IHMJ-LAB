extends PanelContainer
class_name MailItemSimple

signal opened(data: MailEntry)

@onready var sender_label: Label = %SenderLabel
@onready var subject_label: Label = %SubjectLabel
@onready var status_icon: TextureRect = %StatusIcon
@onready var click_button: Button = %ClickButton

var _mail_data: MailEntry
var _is_read: bool = false
var _is_completed: bool = false
var _pending_setup: bool = false

func setup(data: MailEntry) -> void:
	_mail_data = data
	_pending_setup = true
	
	# If already in tree, apply immediately
	if is_node_ready():
		_apply_setup()

func _ready() -> void:
	if _pending_setup:
		_apply_setup()

func _apply_setup() -> void:
	_pending_setup = false
	
	sender_label.text = _mail_data.sender
	subject_label.text = _mail_data.subject
	
	# Check if already completed
	if _mail_data.finished:
		_mark_completed()
	
	click_button.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if not _is_read:
		_mark_read()
	opened.emit(_mail_data)

func _mark_read() -> void:
	_is_read = true
	# Subtle visual change for read emails
	modulate = Color(0.9, 0.9, 0.9, 1.0)

func mark_completed() -> void:
	_mark_completed()

func _mark_completed() -> void:
	_is_completed = true
	_is_read = true
	# Gray out and show checkmark
	modulate = Color(0.6, 0.6, 0.6, 1.0)
	if status_icon:
		status_icon.visible = true

func is_completed() -> bool:
	return _is_completed
