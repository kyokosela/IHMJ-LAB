extends PanelContainer
class_name BaseWindow

#region SETUP
@onready var titlebar: MarginContainer = %Titlebar
@onready var titlebar_bg: ColorRect = %TitlebarBg
@onready var icon: TextureRect = %Icon
@onready var title: Label = %Title
@onready var minimize_btn: Button = %MinimizeBtn
@onready var maximize_btn: Button = %MaximizeBtn
@onready var close_btn: Button = %CloseBtn
@onready var content: SubViewport = %Content

## Los datos de la app a cargar en la ventana.
@export var app_metadata: AppMetadata:
	set(value):
		app_metadata = value
		_load_app_metadata()

var is_maximized := false
var is_dragging := false
var drag_offset := Vector2.ZERO
var previous_rect: Rect2
var bottom_margin: float = 0.0

signal closed
signal minimized
signal focused

func _ready() -> void:
	titlebar.gui_input.connect(drag)
	minimize_btn.pressed.connect(minimize)
	maximize_btn.pressed.connect(maximize)
	close_btn.pressed.connect(close)
	_load_app_metadata()
#endregion

#region LOGIC
func _load_app_metadata():
	if not app_metadata: return
	if not is_node_ready():
		return
	print(app_metadata.app_name)
	title.text = app_metadata.app_name
	titlebar_bg.color = app_metadata.titlebar_bg_color
	title.add_theme_color_override("font_color", app_metadata.titlebar_text_color)
	icon.texture = app_metadata.icon
	_apply_window_size(app_metadata.window_size)
	content.add_child(app_metadata.window_scene.instantiate())

func _apply_window_size(content_size: Vector2i) -> void:
	var safe_size := content_size
	if safe_size.x <= 0 or safe_size.y <= 0:
		safe_size = Vector2i(696, 340)

	content.size = safe_size
	content.size_2d_override = safe_size

	var titlebar_height := 32
	var window_size := Vector2(safe_size.x, safe_size.y + titlebar_height)
	custom_minimum_size = window_size
	size = window_size

	offset_left = -window_size.x * 0.5
	offset_top = -window_size.y * 0.5
	offset_right = window_size.x * 0.5
	offset_bottom = window_size.y * 0.5

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
	grab_focus()
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

#region API

#endregion
