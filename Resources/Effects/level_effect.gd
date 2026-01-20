extends Effect
class_name EffectLevel

signal level_changed(level : int)

@export var level_display_list : Array[String]
@export var level : int = 1 :
	get() :
		return level - 1
@export var icons : Array[CompressedTexture2D]
@export var chance_base : float = 0.0

func get_level_display() -> String :
	return level_display_list[level]

func change_level_value(_new_value) -> void :
	var prev_level : int = level
	level = clamp(_new_value, 0, level_display_list.size() - 1)
	if prev_level == level : level_changed.emit(level)

func get_stress_icon(_new_value) -> CompressedTexture2D :
	if icons.size() != level : return null
	return icons[level]
