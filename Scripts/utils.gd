extends Node
class_name Utils

static func valid_single_dir_vector(vector : Vector2) -> bool: ## Verifica si el vector es de una sola direccion, util para manejar el movimiento por tiles sin diagonales
	if vector == Vector2.UP or vector == Vector2.DOWN or vector == Vector2.LEFT or vector == Vector2.RIGHT:
		return true
	return false

static func get_vector_name(vector : Vector2) -> String:
	match vector:
		Vector2.UP: return "up"
		Vector2.DOWN: return "down"
		Vector2.RIGHT: return "right"
		Vector2.LEFT: return "left"
		_: return ""

static func get_vsync_name() -> String:
	match DisplayServer.window_get_vsync_mode():
		DisplayServer.VSYNC_DISABLED: return "OFF"
		DisplayServer.VSYNC_ENABLED: return "ON"
		DisplayServer.VSYNC_ADAPTIVE: return "ADAPTIVE"
		DisplayServer.VSYNC_MAILBOX: return "MAILBOX"
	return "UNKNOWN"

static func format_full_time(t: float) -> String:
	var s = int(t) % 60
	var m = int(t / 60) % 60
	var h = int(t / 3600)
	return "%02d:%02d:%02d" % [h, m, s]
