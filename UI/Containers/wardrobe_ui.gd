extends Control

enum STATE {CLEAN, DIRTY, WET, EMPTY, FULL}

@export var preset: ClothingData:
	set(value):
		preset = value
		update_ui()
		
@export var current_state: STATE = STATE.CLEAN:
	set(value):
		current_state = value
		update_ui()
		
@onready var contour_node: Control = get_child(0)
@onready var garment_sprite : Sprite2D = get_child(0).get_child(0)
		
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	update_ui()
		
func update_ui():
	if preset == null or garment_sprite == null:
		return
		
	match current_state:
		STATE.CLEAN: garment_sprite.texture = preset.clean
		STATE.DIRTY: garment_sprite.texture = preset.dirty
		STATE.WET: garment_sprite.texture = preset.wet
		STATE.EMPTY: garment_sprite.texture = preset.empty
		STATE.FULL: garment_sprite.texture = preset.full
		
func _get_drag_data(_at_position: Vector2) -> Variant:
	if preset == null:
		return null
	var preview_container = Control.new()
	var visual_clone = contour_node.duplicate()
	visual_clone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.add_child(visual_clone)
	visual_clone.position = Vector2.ZERO
	preview_container.modulate.a = 0.5
	set_drag_preview(preview_container)
	return preset
