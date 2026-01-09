@tool
extends InteractableContainer
class_name Wardrobe


#TODO: Quizas move todo esto a los items ya que estos contienen el preset y de esta m anera inventory container
#controla todo, ademas podria hacer que inventory container llame al ui y el ui pide de este,
#manejar los presets con los items cloth

signal preset_added(preset : SpritePreset)
signal preset_removed(preset : SpritePreset)
signal preset_swapped( player_preset : SpritePreset,wardrobe_preset : SpritePreset)

@export var presets : Array[SpritePreset]

func custom_execute():
	if !area_ref: return
	if area_ref.get_parent() is not InteractionComponent: return
	
	var player : Player = area_ref.get_parent().player
	var current_preset : SpritePreset = player.sprite.current_preset
	var random_preset : SpritePreset = presets.pick_random()
	
	player.change_preset(random_preset)
	presets.erase(random_preset)
	presets.append(current_preset)
	
	print(current_preset.preset_name)
	print(random_preset.preset_name)

func add_preset(preset : SpritePreset) -> void:
	if presets.has(preset): return
	presets.append(preset)
	preset_added.emit(preset)

func remove_preset(preset: SpritePreset) -> void:
	if !presets.has(preset): return
	presets.erase(preset)
	preset_removed.emit(preset)

func swap_preset(current: SpritePreset, swapped_preset: SpritePreset) -> void:
	if not current or not swapped_preset in presets: return
	preset_swapped.emit(current, swapped_preset)
	
	var temp = current
	current = swapped_preset
	swapped_preset = temp
