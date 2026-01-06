extends Resource
class_name ItemBehavior

signal used

func can_use(_item) -> bool:
	return false

func use(_item) -> void:
	used.emit()

func update_states(_item) -> void:
	pass
