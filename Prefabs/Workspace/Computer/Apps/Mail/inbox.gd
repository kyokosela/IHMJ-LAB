extends Panel

# TODO: implement draggable logic
func _ready() -> void:
	_build_segments()
	resized.connect(_build_segments)

func get_spawn_pos() -> Vector2:
	return %Spawn.global_position
	
func _build_segments():
	var w = size.x
	var h = size.y
	
	%Collision.polygon = PackedVector2Array([
		Vector2(0, 0), # inicia en top-left
		Vector2(0, h), # va a bottom-left
		Vector2(w, h), # va a bottom-right
		Vector2(w, 0) # termina en top-right
	])
