@tool
extends Component
class_name SpriteComponent

@export var animation_player : AnimationPlayer
@export var custom_presets : Array[SpritePreset]

#TODO: Verificar cada layer de mayui con un preset para condicion de si ppuede ir al traqbajo por ejemplo
#de esta manera es posible hacer que mayui pueda usar distintas capas de diferentes presets o texturas

@export var current_preset: SpritePreset:
	set(v):
		current_preset = v
		_update_textures()

@export_group("Sincronización")
@export var sync_hframes: int: # Total de frames
	set(v):
		sync_hframes = v
		_propagate_property("hframes", v)

@export var sync_frame: int: # El AnimationPlayer moverá ESTO
	set(v):
		sync_frame = v
		_propagate_property("frame", v)

@export var sync_offset : Vector2:
	set(v):
		sync_offset = v
		_propagate_property("offset", v)

var _layer_nodes: Dictionary = {}
var anim_direction: String = "down"

func _ready():
	_collect_nodes()
	_update_textures()

func _collect_nodes():
	for child in get_children():
		if child is Sprite2D:
			_layer_nodes[child.name] = child

func _update_textures():
	if not current_preset: return
	for layer_name in current_preset.layers:
		if _layer_nodes.has(layer_name):
			_layer_nodes[layer_name].texture = current_preset.layers[layer_name]
	_propagate_property("hframes", sync_hframes)

func _propagate_property(prop: String, value: Variant):
	for node in _layer_nodes.values():
		node.set(prop, value)

func change_layer(layer_name : String, texture : Texture2D):
	if !current_preset: return
	if !current_preset.layers.has(layer_name): return
	
	current_preset.layers[layer_name] = texture
	_update_textures()

func has_preset(preset_name : String) -> bool:
	for preset in custom_presets:
		if preset.preset_name == preset_name: return true
	return false

func change_preset(preset: SpritePreset) -> void:
	current_preset = preset

func change_preset_by_name(preset_name : String) -> void:
	if !has_preset(preset_name): return
	change_preset(get_preset(preset_name))

func get_preset(preset_name : String) -> SpritePreset:
	for preset in custom_presets:
		if preset.preset_name == preset_name: return preset
	return null

func get_all_preset() -> Array[SpritePreset]:
	return custom_presets

func set_anim_direction(direction : Vector2):
	anim_direction = Utils.get_vector_name(direction)

func play_animation(anim_name: String):
	var full_anim : String = anim_name+"_"+anim_direction
	if !animation_player.has_animation(full_anim): return
	
	animation_player.play(full_anim)
