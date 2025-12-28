extends Node2D
class_name World

var entities : Dictionary[String,Entity]

signal entity_created(entity : Entity)
signal entity_removed(entity : Entity)

func _ready() -> void:
	EventManager.load_event(load("res://Resources/events/test_schedule.tres"))
	
	EventManager.connect_to_event("SCHEDULETEST", print.bind("hola"))
	
	for entity : Entity in find_children("*", "Entity", true):
		entities[entity.name] = entity
		entity.world = self
		entity_created.emit(entity)
	
	print("Energy: ",PlayerManager.get_stat_value("ENERGY"))
	print("Health: ",PlayerManager.get_stat_value("HEALTH"))
	PlayerManager.apply_effects()
	print("Energy: ",PlayerManager.get_stat_value("ENERGY"))
	print("Health: ",PlayerManager.get_stat_value("HEALTH"))


func kill_entity(entity: Entity) -> void:
	if !entities.has(entity): return
	entities.erase(entity)
	entity_removed.emit(entity)
	entity.queue_free()

func _process(_delta: float) -> void:
	pass
