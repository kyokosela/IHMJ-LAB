extends Control
class_name Desktop

#region SETUP
@export var current_profile: DesktopProfile ## perfil que se quiere cargar in-game

@onready var icon_grid := %IconGrid
@onready var wallpaper := %Wallpaper
@onready var windows_root := %Windows
@onready var active_windows := %ActiveWindows
@onready var taskbar: Panel = %Taskbar

var base_window = preload("uid://b3gndi1tcb5on")
var running_apps := {}
var taskbar_group := ButtonGroup.new()

func _ready() -> void:
	taskbar_group.allow_unpress = true
	if current_profile: load_profile(current_profile)
#endregion

#region LOGIC

## obtiene los datos del perfil cargado
func load_profile(profile: DesktopProfile):
	if profile.wallpaper: 
		wallpaper.texture = profile.wallpaper

	for app_data in profile.installed_apps: 
		create_icon(app_data)

## Crea instancias de iconos para las aplicaciones cargadas
func create_icon(data: AppData):
	var btn = Button.new()
	btn.text = data.app_name
	btn.icon = data.icon
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	btn.flat = true
	
	btn.pressed.connect(open_app.bind(data))
	icon_grid.add_child(btn)
 
## Crea la instancia de la aplicación. 
## Si ya fue creada, muestra la misma.
## Si fue cerrada pero vuelto a abrir. Se vuelve a crear  
func open_app(data: AppData):
	if running_apps.has(data):
		running_apps[data].focus()
		return
	else:
		running_apps.erase(data)
	

	spawn_new_window(data)

## Instancia la escena de la app en una ventana y añade una referencia a la barra de tareas
func spawn_new_window(data: AppData):
	var session = _get_session(data)
	
	var window = base_window.instantiate()
	windows_root.add_child(window)
	
	window.app_data = data
	running_apps[data] = window
	window.bottom_margin = taskbar.size.y
	
	if window.has_method("inject_session"):
		window.inject_session(session)
	
	var btn = Button.new()
	btn.text = data.app_name
	btn.toggle_mode = true
	btn.button_group = taskbar_group
	
	btn.pressed.connect(_on_button_pressed.bind(btn, window))
	window.focused.connect(_set_button_pressed_state.bind(btn, true))
	window.minimized.connect(_set_button_pressed_state.bind(btn, false))
	
	window.closed.connect(func():
		running_apps.erase(data)
		btn.queue_free()	
	)

	active_windows.add_child(btn)
	
	window.focus()

func _get_session(data: AppData) -> AppSession:
	if current_profile.app_states.has(data.app_name):
		return current_profile.app_states[data.app_name]
		
	var new_session = data.session_script.new() if data.session_script else AppSession.new()
	current_profile.app_states[data.app_name] = new_session
	return new_session

func _on_button_pressed(btn, window):
	if btn.button_pressed:
		window.focus()
	else:
		window.minimize()
		
func _set_button_pressed_state(btn: Button, is_pressed: bool):
	btn.set_block_signals(true)
	btn.button_pressed = is_pressed
	btn.set_block_signals(false)

func set_brightness():
	pass
#endregion
