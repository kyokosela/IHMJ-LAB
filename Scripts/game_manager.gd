extends Node

var money: int = 1000
#this bool can be used in dialogue for manage Mayui movement
var is_dialogue_active: bool = false
var tile_size : Vector2 = Vector2(16,16) # No se si se cambiara o algo por ahora lo dejare aca, si lo cambian, cambien el movement component

var fps: float = 0.0

func _process(_delta: float) -> void:
	fps = Engine.get_frames_per_second()
