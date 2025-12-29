extends Node2D
class_name TileManager

var layers : Array[TileMapLayer]

func _ready() -> void:
	var children = find_children("*", "TileMapLayer")
	for child in children:
		var layer_node = child as TileMapLayer
		
		if layer_node:
			layers.append(layer_node)
		else:
			push_warning("Error, se encontró un nodo que no pudo ser validado como TileMapLayer: ", child.name)
