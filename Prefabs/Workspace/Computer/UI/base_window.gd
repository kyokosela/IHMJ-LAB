extends PanelContainer
class_name BaseWindow

#region SETUP

## Los datos de la app a cargar en la ventana.
@export var app_data: AppData:
	set(value):
		app_data = value
		_load_app_data()

var is_maximized := false
var is_dragging := false
var drag_offset := Vector2.ZERO
var previous_rect: Rect2
var bottom_margin: float = 0.0

signal closed
signal minimized
signal focused

func _ready() -> void:
	%Titlebar.gui_input.connect(drag)
	%Minimize.pressed.connect(minimize)
	%Maximize.pressed.connect(maximize)
	%Close.pressed.connect(close)
#endregion

#region LOGIC
func _load_app_data():
	if not app_data: return
	print(app_data.app_name)
	%Title.text = app_data.app_name
	%TitlebarBg.color = app_data.titlebar_bg_color
	%Title.add_theme_color_override("font_color", app_data.titlebar_text_color)
	%Icon.texture = app_data.icon
	%Content.add_child(app_data.window_scene.instantiate())

func close():
	closed.emit()
	queue_free()
	
func minimize():
	hide()
	minimized.emit()	

func maximize():
	if is_maximized:
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		global_position = previous_rect.position
		size = previous_rect.size
		is_maximized = false
		print(size, "minimizado")
	else:
		previous_rect = get_global_rect()
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		offset_bottom = -bottom_margin
		print(size, "maximizado")
		is_maximized = true

	focus()

func focus():
	show()
	get_parent().move_child(self, -1)
	focused.emit()

func drag(event: InputEvent):
	if is_maximized: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
		drag_offset = get_global_mouse_position() - global_position
		focus()
			
	if event is InputEventMouseMotion and is_dragging:
		var new_pos = get_global_mouse_position() - drag_offset
		var screen_size = get_viewport_rect().size
			
		new_pos.x = clamp(new_pos.x, 0, screen_size.x - size.x)
		new_pos.y = clamp(new_pos.y, 0, screen_size.y - size.y)
		
		global_position = new_pos
#endregion
