extends TextureRect

# Usamos un setter para que la UI se actualice automáticamente al cambiar el recurso
@export var preset : SpritePreset:
	set(value):
		preset = value
		update_ui()
		
# prueba, no sirvio pero ahi ver omg si algo https://www.youtube.com/watch?v=JUR1qQ79eJY <- usar este
# video como referencia sirve bastante

func _ready() -> void:
	update_ui()
	
func update_ui():
	if preset == null:
		texture = null
		tooltip_text = ""
	else:
		# Asumiendo que SpritePreset tiene una propiedad 'texture' o similar
		# o si preset tiene una propiedad llamada text
		texture = preset.texture
		tooltip_text = preset.text

func _get_drag_data(_at_position: Vector2) -> Variant:
	if preset == null: return
	
	#manejo de la instancia
	var preview = duplicate()
	var c = Control.new()
	c.add_child(preview)
	
	#manejo del centro en la posición del mouse
	#preview.position -= Vector2(25,25)
	
	# En lugar de -25, -25, usamos la mitad del tamaño real para que funcione con cualquier escala
	preview.position = -size / 2
	
	#manejo del color mientas está seleccionado
	preview.self_modulate = Color.TRANSPARENT
	c.modulate = Color(c.modulate, 0.5)
	
	set_drag_preview(c)
	
	#se retorna solo el propio self del nodo en lugar del preset para vaciar el slot de origen al soltarlo
	return self

func _can_drop_data(_at_position: Vector2, _data: Variant) -> bool:
	return _data is TextureRect

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	#lógica de intercambio o swap en la UI
	#se guarda temporalmente el contenido de destino
	var temp_preset = preset
	#el destino toma el preset del origen (data)
	preset = data.preset
	
	#el origen toma lo que tenía el destino
	data.preset = temp_preset
	
	# NOTA: No hace falta limpiar texturas a mano, 
	# los setters se encargan de llamar a update_ui().
