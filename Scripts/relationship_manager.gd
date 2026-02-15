extends Node

signal relationship_changed(npc_id: String, old_level: int, new_level: int)
signal relationship_milestone(npc_id: String, level: int)

const MAX_LEVEL: int = 4
const MIN_LEVEL: int = 0
const POINTS_PER_LEVEL: int = 100

const NPC_MADINA: String = "MADINA"
const NPC_VEDA: String = "VEDA"
const NPC_CASERO: String = "CASERO"
const NPC_SATIVA: String = "SATIVA"
const NPC_M88: String = "M88"

var _levels: Dictionary = {}
var _points: Dictionary = {}

func get_level(npc_id: String) -> int:
	return _levels.get(npc_id, 0)

func get_display_level(npc_id: String) -> int:
	return get_level(npc_id) + 1

func is_level_at_least(npc_id: String, min_level: int) -> bool:
	return get_level(npc_id) >= min_level

func set_level(npc_id: String, level: int) -> void:
	var old_level := get_level(npc_id)
	var new_level: int = clamp(level, MIN_LEVEL, MAX_LEVEL)
	if old_level == new_level:
		return

	_levels[npc_id] = new_level
	_points[npc_id] = new_level * POINTS_PER_LEVEL
	relationship_changed.emit(npc_id, old_level, new_level)
	if new_level > old_level:
		relationship_milestone.emit(npc_id, new_level)

func add_points(npc_id: String, points: int) -> void:
	if not _points.has(npc_id):
		_points[npc_id] = 0
		_levels[npc_id] = 0

	_points[npc_id] += points
	_recalculate_level(npc_id)

func remove_points(npc_id: String, points: int) -> void:
	if not _points.has(npc_id):
		return

	_points[npc_id] = max(0, _points[npc_id] - points)
	_recalculate_level(npc_id)

func can_trigger_m88_subplot() -> bool:
	return is_level_at_least(NPC_MADINA, 1)

func can_trigger_sativa_event() -> bool:
	return is_level_at_least(NPC_SATIVA, 1)

func can_madina_warn_sunday() -> bool:
	return is_level_at_least(NPC_MADINA, 2)

func get_save_data() -> Dictionary:
	return {
		"levels": _levels.duplicate(true),
		"points": _points.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	_levels = data.get("levels", {})
	_points = data.get("points", {})

func _recalculate_level(npc_id: String) -> void:
	var points := int(_points.get(npc_id, 0))
	var new_level: int = int(clamp(points / POINTS_PER_LEVEL, MIN_LEVEL, MAX_LEVEL))
	var old_level: int = int(_levels.get(npc_id, 0))
	if new_level == old_level:
		return

	_levels[npc_id] = new_level
	relationship_changed.emit(npc_id, old_level, new_level)
	if new_level > old_level:
		relationship_milestone.emit(npc_id, new_level)
