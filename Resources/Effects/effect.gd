extends Resource
class_name Effect

@export var effect_unique_name : String
@export var effect_display_name : String :
	get() :
		return tr(effect_display_name)
@export var render : bool
@export var stat_changes : Array[statChanger]
