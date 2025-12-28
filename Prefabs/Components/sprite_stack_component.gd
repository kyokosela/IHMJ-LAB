extends Component
class_name SpriteStackComponent

signal layer_changed(layer_name: String, new_sprite: SpriteFrames)
signal color_changed(layer_name: String, new_color: Color)
signal animation_changed(previous_anim: String, new_anim: String)
signal direction_changed(new_direction: String)

@export var layer_order: Array[String] = [
	"legs",
	"body", 
	"head",
	"hair",
	"hat"
]

var layers: Dictionary[String, AnimatedSprite2D] = {}
var layer_colors: Dictionary[String, Color] = {}
var current_animation_prefix: String = "idle"
var current_direction: String = "down"
var is_flipped: bool = false

const VALID_DIRECTIONS = ["up", "down", "right"]
const DIRECTION_MAP = {
	Vector2.UP: "up",
	Vector2.DOWN: "down", 
	Vector2.LEFT: "right", 
	Vector2.RIGHT: "right"
}
#region Setup
func _ready() -> void:
	super()
	_collect_layers()
	_setup_z_index()
	play_animation("idle")

func _collect_layers() -> void: ##Recolecta todas las capas AnimatedSprite2D y guarda sus colores
	for layer: AnimatedSprite2D in find_children("*", "AnimatedSprite2D"):
		layers[layer.name] = layer
		layer_colors[layer.name] = layer.modulate

func _setup_z_index() -> void: ##Configura el z_index de cada capa según layer_order
	for i in range(layer_order.size()):
		var layer_name = layer_order[i]
		if layers.has(layer_name):
			layers[layer_name].z_index = i

#endregion

#region Animations

func play_animation(anim_prefix: String) -> void:## Reproduce una animación con el prefijo dado (ej: 'idle', 'walk') Se añade automáticamente la dirección actual
	if anim_prefix == current_animation_prefix:
		return
	var full_anim_name = _build_animation_name(anim_prefix, current_direction)
	
	if not _validate_animation(full_anim_name):
		push_warning("Animation '%s' not found in all layers. Skipping." % full_anim_name)
		return
	
	var previous_full_name = _build_animation_name(current_animation_prefix, current_direction)
	current_animation_prefix = anim_prefix
	
	_play_on_all_layers(full_anim_name)
	animation_changed.emit(previous_full_name, full_anim_name)

func set_direction(direction: Vector2) -> void: ## Cambia la dirección de la animación basándose en un Vector2 Maneja automáticamente el flip horizontal para left/right
	if not Utils.valid_single_dir_vector(direction):
		push_warning("Invalid direction vector: %s" % direction)
		return
	
	var new_direction = _get_direction_name(direction)
	var should_flip = direction.x < 0
	
	if new_direction == current_direction and should_flip == is_flipped:
		return
	
	current_direction = new_direction
	is_flipped = should_flip
	
	for layer in layers.values():
		layer.flip_h = is_flipped
	
	var new_anim = _build_animation_name(current_animation_prefix, current_direction)
	_play_on_all_layers(new_anim)
	
	direction_changed.emit(current_direction)

func stop_animation() -> void:
	##Detiene todas las animaciones
	for layer in layers.values():
		layer.stop()

func pause_animation() -> void: ##Pausa todas las animaciones
	for layer in layers.values():
		layer.pause()

func resume_animation() -> void: ##Reanuda todas las animaciones
	var anim_name = _build_animation_name(current_animation_prefix, current_direction)
	_play_on_all_layers(anim_name)

func set_frame(idx: int) -> void: ##Establece un frame específico en todas las capas
	for layer in layers.values():
		if layer.sprite_frames:
			layer.frame = clamp(idx, 0, layer.sprite_frames.get_frame_count(layer.animation) - 1)

#endregion

#region Layers

func change_layer_sprite(layer_name: String, sprite_frames: SpriteFrames) -> void: ##Cambia el SpriteFrames de una capa específica
	if not _validate_layer(layer_name):
		return
	
	layers[layer_name].sprite_frames = sprite_frames
	layer_changed.emit(layer_name, sprite_frames)
	
	var current_anim = _build_animation_name(current_animation_prefix, current_direction)
	if sprite_frames.has_animation(current_anim):
		layers[layer_name].play(current_anim)

func change_layer_color(layer_name: String, color: Color) -> void: ##Cambia el color de una capa específica
	if not _validate_layer(layer_name):
		return
	
	layers[layer_name].modulate = color
	layer_colors[layer_name] = color
	color_changed.emit(layer_name, color)

func reset_layer_color(layer_name: String) -> void: ##Resetea el color de una capa a su color original
	if not _validate_layer(layer_name):
		return
	
	if layer_colors.has(layer_name):
		change_layer_color(layer_name, layer_colors[layer_name])

func show_layer(layer_name: String) -> void: ##Muestra una capa específica
	if _validate_layer(layer_name):
		layers[layer_name].show()

func hide_layer(layer_name: String) -> void: ##Oculta una capa específica
	if _validate_layer(layer_name):
		layers[layer_name].hide()

func toggle_layer(layer_name: String) -> void: ##Alterna la visibilidad de una capa
	if _validate_layer(layer_name):
		layers[layer_name].visible = not layers[layer_name].visible

func is_layer_visible(layer_name: String) -> bool: ##Verifica si una capa está visible
	if _validate_layer(layer_name):
		return layers[layer_name].visible
	return false

#endregion

#region Getters

func get_current_animation() -> String: ##Retorna el nombre completo de la animación actual (con dirección)
	return _build_animation_name(current_animation_prefix, current_direction)

func get_animation_prefix() -> String: ##Retorna solo el prefijo de la animación (sin dirección)
	return current_animation_prefix

func get_current_direction() -> String: ##Retorna la dirección actual de la animación
	return current_direction

func get_layer(layer_name: String) -> AnimatedSprite2D: ##Obtiene una capa específica
	return layers.get(layer_name, null)

func has_layer(layer_name: String) -> bool: ##Verifica si existe una capa
	return layers.has(layer_name)

func get_all_layers() -> Dictionary[String, AnimatedSprite2D]: ##Retorna todas las capas
	return layers.duplicate()

#endregion

#region Helpers

func _build_animation_name(prefix: String, direction: String) -> String: ##Construye el nombre completo de la animación
	return "%s_%s" % [prefix, direction]

func _get_direction_name(direction: Vector2) -> String: ##Convierte un Vector2 a nombre de dirección
	return DIRECTION_MAP.get(direction, "down")

func _validate_animation(anim_name: String) -> bool: ##Valida que una animación existe en todas las capas
	for layer in layers.values():
		if not layer.sprite_frames or not layer.sprite_frames.has_animation(anim_name):
			return false
	return true

func _validate_layer(layer_name: String) -> bool: ##Valida que una capa existe
	if not layers.has(layer_name):
		push_warning("Layer '%s' not found" % layer_name)
		return false
	return true

func _play_on_all_layers(anim_name: String) -> void: ##Reproduce una animación en todas las capas
	
	for layer in layers.values():
		if layer.sprite_frames and layer.sprite_frames.has_animation(anim_name):
			layer.play(anim_name)

#endregion
