extends Node
class_name World

var entities : Dictionary[String,Entity]
@onready var label: Label = %Label

func _ready() -> void:
	
	EventManager.load_event(load("res://Resources/events/test_basic_event.tres"))
	
	for entity : Entity in find_children("*", "Entity", true):
		entities[entity.name] = entity
		entity.world = self
	
func _process(_delta: float) -> void:
	pass

func _test():
	TimeManager.set_current_time("04:00")
	await get_tree().create_timer(2).timeout
	TimeManager.add_to_current_time("02:00")
	await get_tree().create_timer(2).timeout
	TimeManager.add_to_current_time("01:00")
	await get_tree().create_timer(2).timeout
	TimeManager.add_to_current_time("00:10")
	await get_tree().create_timer(2).timeout
	TimeManager.add_to_current_time("00:60")
	
