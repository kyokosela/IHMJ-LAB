extends Component
class_name SpriteStackComponent

signal layer_changed(layer_name: String, new_sprite: SpriteFrames)
signal color_changed(layer_name: String, new_color: Color)
signal animation_changed(previous_anim : String, new_anim : String)

@onready var layers: Dictionary[String, AnimatedSprite2D] = {}

@export var layer_order: Array[String] = [
	"legs",
	"body",
	"head",
	"hair",
	"hat"
]

var layer_colors: Dictionary[String, Color] = {}
var current_animation : String = "idle"
var current_direction : String = "down"

func _ready() -> void:
	super()
	collect_layers()
	setup_z_index()
	play_animation("idle")

func collect_layers():
	for layer : AnimatedSprite2D in find_children("*", "AnimatedSprite2D"):
		layers[layer.name] = layer
		layer_colors[layer.name] = layer.modulate

func setup_z_index():
	for i in range(layer_order.size()):
		var layer_name = layer_order[i]
		if layers.has(layer_name):
			layers[layer_name].z_index = i

func play_animation(anim_prefix : String):
	var anim_name = get_directional_anim(anim_prefix)
	if anim_name == current_animation: return
	for layer in layers.values():
		if layer.sprite_frames and layer.sprite_frames.has_animation(anim_name):
			layer.play(anim_name)
		else:
			push_error("All layers do not contain the '%s' animation")
			return
	animation_changed.emit(current_animation,anim_name)
	current_animation = anim_name

func get_directional_anim(anim_name : String):
	return anim_name + "_" + current_direction

func stop_animation():
	for layer : AnimatedSprite2D in layers.values():
		layer.stop()

func pause_animation():
	for layer : AnimatedSprite2D in layers.values():
		layer.pause()

func resume_animation():
	for layer : AnimatedSprite2D in layers.values():
			layer.play(current_animation)

func set_frame(idx : int):
	for layer : AnimatedSprite2D in layers.values():
		if layer.sprite_frames:
			layer.frame = idx

func change_layer_sprite(layer_name : String, sprite_frames : SpriteFrames):
	if !layers.has(layer_name):
		push_error("Layer: "+ layer_name + "not found")
		return
	layers[layer_name].sprite_frames = sprite_frames
	layer_changed.emit(layer_name, sprite_frames)

func change_layer_color(layer_name : String, color : Color):
	if !layers.has(layer_name):
		push_error("Layer: "+ layer_name + "not found")
		return
	layers[layer_name].modulate = color
	layer_colors[layer_name] = color
	color_changed.emit(layer_name, color)

func show_layer(layer_name : String):
	if !layers.has(layer_name):
		push_error("Layer: "+ layer_name + "not found")
		return
	layers[layer_name].show()
	
func hide_layer(layer_name : String):
	if !layers.has(layer_name):
		push_error("Layer: "+ layer_name + "not found")
		return
	layers[layer_name].hide()

func toggle_layer(layer_name : String):
	if !layers.has(layer_name):
		push_error("Layer: "+ layer_name + "not found")
		return
	layers[layer_name].visible = !layers[layer_name].visible

func set_direction(direction : Vector2):
	if !Utils.valid_single_dir_vector(direction): return
	if direction == Vector2.UP: current_direction = "up"
	elif direction == Vector2.DOWN: current_direction = "down"
	elif direction == Vector2.LEFT: current_direction = "right"
	elif direction == Vector2.RIGHT: current_direction = "right"
	var flip_h = direction.x < 0
	for layer in layers.values():
		layer.flip_h = flip_h
