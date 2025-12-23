extends Node2D
class_name TileManager

var layers : Array[TileMapLayer]

func _ready() -> void:
	for layer in find_children("*", "TileMapLayer"):
		layers.append(layer)
