extends Control
class_name MailApp

#region SETUP
@onready var inbox: Panel = %Inbox
@onready var sender_mail_label: Label = %SenderMailLabel
@onready var sender_icon: TextureRect = %SenderIcon
@onready var subject_label: Label = %SubjectLabel
@onready var content_label: Label = %ContentLabel
@onready var action_box: VBoxContainer = %ActionBox

const MAIL_ITEM_SCENE := preload("res://Prefabs/Workspace/Computer/Apps/Mail/UI/MailItem/MailItemSimple.tscn")

@export var mail_pool: Array[MailEntry]

var finished_mails: Array = []
var mail_items: Dictionary = {}  # MailEntry -> MailItemSimple

var cache := {}
var current_wrapper: Control = null
var current_mail_item: MailItemSimple = null

func _ready() -> void:
	var today_emails: Array[MailEntry] = EmailPoolManager.get_emails_for_day(TimeManager.day)
	mail_pool.append_array(today_emails)
	
	# Spawn all emails immediately (no physics delay needed)
	_spawn_all_emails()
#endregion

#region LOGIC
func _spawn_all_emails() -> void:
	for mail_data in mail_pool:
		_spawn_single_email(mail_data)

func _spawn_single_email(mail_data: MailEntry) -> void:
	var mail_item: MailItemSimple = MAIL_ITEM_SCENE.instantiate()
	
	# Check if already finished
	var uid = ResourceLoader.get_resource_uid(mail_data.resource_path)
	if uid in finished_mails:
		mail_data.finished = true
	
	mail_item.setup(mail_data)
	mail_item.opened.connect(_handle_mail_content)
	
	inbox.add_mail_item(mail_item)
	mail_items[mail_data] = mail_item

func _handle_mail_content(data: MailEntry) -> void:
	sender_mail_label.text = data.mail
	sender_icon.texture = data.icon 
	subject_label.text = data.subject
	content_label.text = data.content
	data.open()
	
	# Track current mail item for completion marking
	current_mail_item = mail_items.get(data) as MailItemSimple
	
	if current_wrapper: current_wrapper.hide()
	
	if !cache.has(data): _create_wrapper(data)
	
	current_wrapper = cache[data]
	current_wrapper.show()
	
	_get_focus(current_wrapper)
	
func _create_wrapper(data: MailEntry) -> void:
	var wrapper = VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_box.add_child(wrapper)
	
	if data.finished: _show_solved(wrapper)
	elif data.event:
		data.event.execute(wrapper, data)
		data.completed.connect(_on_mail_completed.bind(wrapper, data), CONNECT_ONE_SHOT)
	else:
		_show_solved(wrapper)
		
	cache[data] = wrapper

func _on_mail_completed(wrapper: Control, data: MailEntry) -> void:
	var uid = ResourceLoader.get_resource_uid(data.resource_path)
	
	if uid not in finished_mails:
		finished_mails.append(uid)

	if not data.email_id.is_empty():
		EmailPoolManager.mark_sent(data.email_id)
	
	# Mark the mail item as completed (grayed out with checkmark)
	var mail_item: MailItemSimple = mail_items.get(data) as MailItemSimple
	if mail_item:
		mail_item.mark_completed()
		
	for child in wrapper.get_children(): child.queue_free()
	_show_solved(wrapper)
	
func _show_solved(parent: Control) -> void:
	var l = Label.new()
	l.text = "--- ANSWERED ---"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	
func _get_focus(wrapper: Control) -> void:
	var next = wrapper.find_next_valid_focus()
	if next: next.grab_focus()
#endregion
