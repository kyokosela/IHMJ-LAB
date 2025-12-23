extends CharacterBody2D
class_name Entity

#region SETUP
signal entity_created
signal entity_removed
signal entity_ready

var components : Dictionary[String,Component]
var world : World

func _init() -> void:
	entity_created.emit()

func _ready() -> void:
	for component : Component in find_children("*", "Component"):
		add_component(component)
	entity_ready.emit()
#endregion

#region API
func get_component(component_name : String) -> Component:
	if components.has(component_name):
		return components[component_name]
	return null

func add_component(component: Component) -> void:
	if !components.has(component.name):
		components[component.name] = component
		if !find_child(component.name): add_child(component)

func remove_component(component: Component) -> void:
	if component.has(component.name):
		components.erase(component.name)
		component.queue_free()

func kill_entity() -> void:
	if world.entities.has(self):
		world.entities.erase(self)
		entity_removed.emit()
	queue_free()
#endregion
