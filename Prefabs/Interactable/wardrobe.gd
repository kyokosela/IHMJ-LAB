@tool
extends InteractableContainer
class_name Wardrobe

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
	
	
