extends Control
class_name Desktop

#region SETUP
@export var current_profile: DesktopProfile

@onready var icon_grid = $Icons/MarginContainer/GridContainer
@onready var wallpaper = $Wallpaper
@onready var windows: Control = $Windows
@onready var active_windows: HBoxContainer = $Taskbar/MarginContainer/HBoxContainer/ActiveWindows
@onready var taskbar: Panel = $Taskbar

var window_base = preload("res://Prefabs/Workspace/Computer/BaseWindow.tscn")
var running_apps := {}

func _ready() -> void:
	if current_profile: 
		load_profile(current_profile)
#endregion

#region LOGIC
func load_profile(profile: DesktopProfile):
	if profile.wallpaper: 
		wallpaper.texture = profile.wallpaper
		
	for app_data in profile.installed_apps: 
		create_icon(app_data)

func create_icon(data: AppData):
	var btn = Button.new()
	btn.text = data.app_name
	btn.icon = data.icon
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	btn.flat = true
	btn.pressed.connect(open_app.bind(data))
	icon_grid.add_child(btn)
 	
func open_app(data: AppData):
	if running_apps.has(data):
		var window = running_apps[data]
		if is_instance_valid(window):
			window.show()
			return
		else:
			running_apps.erase(data)
			
	spawn_new_window(data)
	
func spawn_new_window(data: AppData):
	var window = window_base.instantiate()
	$Windows.add_child(window)
	
	window.app_data = data
	running_apps[data] = window
	window.bottom_margin = taskbar.size.y
	
	var btn = Button.new()
	btn.text = data.app_name
	btn.toggle_mode = true
	btn.button_pressed = true
	
	btn.pressed.connect(func():
		if not window.visible:
			window.visible = true
			windows.move_child(window, -1)
			btn.set_pressed_no_signal(true)
		elif window.get_index() < windows.get_child_count() - 1:
			windows.move_child(window, -1)
			btn.set_pressed_no_signal(true)
		else:
			window.minimize()
			btn.set_pressed_no_signal(false)
	)
	
	window.close_requested.connect(
		func():
			running_apps.erase(data)
			btn.queue_free()	
	)
	
	window.maximize_requested.connect(func(): btn.button_pressed = true)
	window.minimize_requested.connect(func(): btn.button_pressed = false)
	
	active_windows.add_child(btn)

func set_brightness():
	pass
#endregion
