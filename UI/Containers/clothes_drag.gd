extends TextureRect

@export var preset : SpritePreset
# prueba, no sirvio pero ahi ver omg si algo https://www.youtube.com/watch?v=JUR1qQ79eJY <- usar este
# video como referencia sirve bastante

func _get_drag_data(_at_position: Vector2) -> Variant:
	if preset == null: return
	
	#manejo de la instancia
	var preview = duplicate()
	var c = Control.new()
	c.add_child(preview)
	
	#manejo del centro en la posición del mouse
	preview.position -= Vector2(25,25)
	preview.self_modulate = Color.TRANSPARENT
	c.modulate = Color(c.modulate, 0.5)
	
	set_drag_preview(preview)
	
	#se retorna solo el propio self del nodo en lugar del preset para vaciar el slot de origen al soltarlo
	return self

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return true

func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	pass
