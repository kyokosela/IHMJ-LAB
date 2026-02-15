extends Effect
class_name EffectLevel

signal level_changed(level : int)

@export var level_display_list : Array[String]
@export var level : int = 0 :
	get() :
		return level
@export var icons : Array[CompressedTexture2D]
@export var chance_base : float = 0.0
## Time cost multipliers per level (index 0 = Lv1, index 1 = Lv2, etc.)
## Positive = increase time cost, Negative = decrease time cost
@export var time_cost_per_level : Array[float] = []
## Days this effect has been active at current level (for escalation)
var days_active : int = 0

func get_level_display() -> String :
	if level_display_list.is_empty():
		return ""
	var index : int = clampi(level, 0, level_display_list.size() - 1)
	return level_display_list[index]

func change_level_value(_new_value) -> void :
	var prev_level : int = level
	level = clampi(int(_new_value), 0, level_display_list.size() - 1)
	if prev_level != level:
		days_active = 0  # Reset days counter on level change
		level_changed.emit(level)

## Get time cost multiplier for current level
func get_time_cost_multiplier() -> float:
	if time_cost_per_level.is_empty():
		return 0.0
	var index : int = clampi(level, 0, time_cost_per_level.size() - 1)
	return time_cost_per_level[index]

## Increment days active counter (called daily)
func increment_days_active() -> void:
	days_active += 1

func get_stress_icon(_new_value := -1) -> CompressedTexture2D :
	if icons.is_empty():
		return null
	var index : int = clampi(level, 0, icons.size() - 1)
	return icons[index]
