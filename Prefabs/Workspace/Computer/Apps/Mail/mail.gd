extends Control
class_name MailApp

#region SETUP
@onready var inbox: Panel = %Inbox
@onready var timer: Timer = %Timer
@onready var sender_mail_label: Label = %SenderMailLabel
@onready var sender_icon: TextureRect = %SenderIcon
@onready var subject_label: Label = %SubjectLabel
@onready var content_label: Label = %ContentLabel
@onready var action_box: VBoxContainer = %ActionBox

@export var mail_item_scene: PackedScene
@export var mail_pool: Array[MailEntry]

var finished_mails: Array = []

var cache := {}
var current_wrapper: Control = null

func _ready() -> void:
	while !mail_pool.is_empty():
		spawn()
		await timer.timeout
#endregion

#region LOGIC
func spawn():
	var mail_data = mail_pool.pop_at(randi() % mail_pool.size())
	var mail_item = mail_item_scene.instantiate()
	inbox.add_child(mail_item)

	# TODO: Reemplazar a futuro con UIDs unicas manualmente escritas
	var uid =  ResourceLoader.get_resource_uid(mail_data.resource_path)
	if uid in finished_mails:  mail_data.finished = true

	mail_item.setup(mail_data)
	mail_item.launch(inbox.get_spawn_pos())
	mail_item.opened.connect(_handle_mail_content)

func _handle_mail_content(data: MailEntry) -> void:
	sender_mail_label.text = data.mail
	sender_icon.texture = data.icon 
	subject_label.text = data.subject
	content_label.text = data.content
	data.open()
	
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
		SaveManager.save_data()
	
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
