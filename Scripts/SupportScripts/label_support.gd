extends Label

func _process(_delta: float) -> void:
	var current_fps = GameManager.fps
	text = "fps: " + str(current_fps)
