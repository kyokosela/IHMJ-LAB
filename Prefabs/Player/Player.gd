extends Entity
class_name Player

@export var tile_map : TileMapLayer

func _ready() -> void:
	await super()
	add_to_group("Player")
