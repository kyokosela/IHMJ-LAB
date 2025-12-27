extends Resource
class_name Effect

@warning_ignore_start("unused_signal")
signal effect_start
signal effect_end

@export var effect_unique_name : String
@export var effect_display_name : String :
	get() :
		return tr(effect_display_name)
@export var render : bool
@export var stat_changes : Array[statChanger]
