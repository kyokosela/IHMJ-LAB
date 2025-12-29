extends Resource
class_name ItemBehavior

signal used

func can_use(_item, _entity) -> bool:
	return false

func use(_item, _entity) -> void:
	used.emit()
