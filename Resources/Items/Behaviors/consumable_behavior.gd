extends ItemBehavior
class_name ConsumableBehavior

func can_use(_item, _entity) -> bool:
	#casi siempre si, no?
	return true

func use(_item, _entity) -> void:
	#quitar hambre o dar dependiendo del estado del item no se
	print("item used: ", _item)
	used.emit()
