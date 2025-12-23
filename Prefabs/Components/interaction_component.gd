@tool
extends Component
class_name InteractionComponent

var collshape : CollisionShape2D
var interactor : Area2D
var movement : MovementComponent

var enabled : bool
@export var shape : Shape2D:
	set(value) : shape = value; if Engine.is_editor_hint() : collshape.shape = shape
@export_custom(PROPERTY_HINT_LAYERS_2D_PHYSICS, "Collision Mask") var collision_layer : int = 1
@export_custom(PROPERTY_HINT_LAYERS_2D_PHYSICS, "Collision Mask") var collision_mask : int = 1


func _initialize() -> void:
	movement = entity.get_component("MovementComponent")
	if !interactor:
		interactor = Area2D.new()
		interactor.collision_layer = collision_layer
		interactor.collision_mask = collision_mask
	collshape = CollisionShape2D.new()
	collshape.shape = shape
	interactor.add_to_group("Interactor")
	add_child(interactor)
	interactor.add_child(collshape)

func _ready() -> void:
	await super()
	_initialize()
	assert(interactor != null, "Interactor should never be NULL")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	interactor.position = movement.last_facing_dir * movement.tile_size
		
