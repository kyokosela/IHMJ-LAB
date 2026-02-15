extends Node

signal flag_set(flag_name: String, value: Variant)
signal flag_cleared(flag_name: String)

var _flags: Dictionary = {}

func set_flag(name: String, value: bool = true) -> void:
	_flags[name] = value
	flag_set.emit(name, value)

func set_value(name: String, value: Variant) -> void:
	_flags[name] = value
	flag_set.emit(name, value)

func get_flag(name: String) -> bool:
	return _flags.get(name, false)

func get_value(name: String, default: Variant = null) -> Variant:
	return _flags.get(name, default)

func has_flag(name: String) -> bool:
	return _flags.has(name) and _flags[name] == true

func clear_flag(name: String) -> void:
	if _flags.has(name):
		_flags.erase(name)
		flag_cleared.emit(name)

func has_all_flags(flag_names: Array[String]) -> bool:
	for flag in flag_names:
		if not has_flag(flag):
			return false
	return true

func has_any_flag(flag_names: Array[String]) -> bool:
	for flag in flag_names:
		if has_flag(flag):
			return true
	return false

func get_save_data() -> Dictionary:
	return _flags.duplicate(true)

func load_save_data(data: Dictionary) -> void:
	_flags = data.duplicate(true)
