extends Marker2D
class_name SpawnPoint

@export var entity : String

func _ready() -> void:
	add_to_group("spawn_point")
