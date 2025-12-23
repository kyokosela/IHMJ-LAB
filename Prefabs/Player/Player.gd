extends Entity
class_name Player

@export var tile_size: Vector2

func _ready() -> void:
	super()
	add_to_group("Player")
	
func _process(_delta: float) -> void:
	print(get_component("MovementComponent").last_facing_dir)
