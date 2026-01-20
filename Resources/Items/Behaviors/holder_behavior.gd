extends ItemBehavior
class_name HolderBehavior
## Behavior para items que pueden contener otros items (mug, plate, pot)
## La lógica principal está en Item.gd, este behavior maneja el uso del contenido

func can_use(_item: Item) -> bool:
	# Solo se puede usar si tiene algo contenido
	if not _item.has_held_item():
		return false
	return _item.data.can_use

func use(_item: Item) -> void:
	if not _item.has_held_item():
		return
	
	var held = _item.held_item
	
	# Si el item contenido tiene behavior, usarlo
	if held.data.behavior != null:
		if held.data.behavior.can_use(held):
			held.data.behavior.use(held)
			held.uses_left -= 1
			
			# Si el contenido se agotó, liberarlo
			if held.uses_left <= 0 and held.data.consume_after_use:
				_item.release_held_item()
				# Marcar el holder como dirty si corresponde
				_mark_dirty_after_use(_item)
	
	_item.used.emit()

func update_states(_item: Item) -> void:
	super.update_states(_item)
	
	# También actualizar estados del item contenido si existe
	if _item.has_held_item() and _item.held_item.data.behavior != null:
		_item.held_item.data.behavior.update_states(_item.held_item)

func apply_enviroment(minutes: int, item: Item, env_properties: Array[String]):
	super.apply_enviroment(minutes, item, env_properties)
	
	# También aplicar ambiente al item contenido
	if item.has_held_item() and item.held_item.data.behavior != null:
		item.held_item.data.behavior.apply_enviroment(minutes, item.held_item, env_properties)

## Marca el holder como dirty después de usar el contenido
func _mark_dirty_after_use(holder: Item) -> void:
	var cleanliness = holder.get_custom_condition("cleanliness")
	if cleanliness != null:
		cleanliness.value = 0  # Dirty
		holder.update_states()
