@tool
extends InteractableContainer
class_name Stove

func _ready() -> void:
	

func custom_execute():
	var items = container.get_all_items()
	for x in items:
		if !x.has_state("preparation"): return
		x.decrease_condition_value("preparation",1)
		
