extends Control

@export var mail_item_scene: PackedScene
@export var mail_pool: Array[MailEntry]

var cache := {}
var current_wrapper: Control = null

func _ready() -> void:
	%Timer.timeout.connect(spawn)

func spawn():
	if mail_pool.is_empty(): 
		%Timer.stop()
		return

	var mail_data = mail_pool.pop_at(randi() % mail_pool.size())
	var instance = mail_item_scene.instantiate()
	instance.setup(mail_data)
	%Inbox.add_child(instance)
	
	instance.launch(%Inbox.get_spawn_pos())
	instance.opened.connect(_handle_mail_content)
		
func _handle_mail_content(data: MailEntry) -> void:
	%Text.text = data.content
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
	%ActionBox.add_child(wrapper)
	
	if data.finished: _show_solved(wrapper)
	elif data.event:
		data.event.execute(wrapper, data)
		data.completed.connect(_on_mail_completed.bind(wrapper), CONNECT_ONE_SHOT)
	else:
		_show_solved(wrapper)
		
	cache[data] = wrapper

# TODO: mantener el estado completado al cerrar y volver a abrir la aplicación
func _on_mail_completed(wrapper: Control) -> void:
	for child in wrapper.get_children(): child.queue_free()
	_show_solved(wrapper)
	
func _show_solved(parent: Control) -> void:
	var l = Label.new()
	l.text = "--- ANSWERED ---"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(l)
	
func _get_focus(wrapper: Control) -> void:
	for child in wrapper.get_children():
		if child.focus_mode != Control.FOCUS_NONE:
			child.grab_focus()
			return
