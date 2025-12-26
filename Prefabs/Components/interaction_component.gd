@tool
extends Component
class_name InteractionComponent

var collshape : CollisionShape2D
var interactor : Area2D
var player : Player:
	get: return entity as Player
@export var shape : Shape2D:
	set(value) : shape = value; if Engine.is_editor_hint() : collshape.shape = shape
@export_custom(PROPERTY_HINT_LAYERS_2D_PHYSICS, "Collision Mask") var collision_layer : int = 1
@export_custom(PROPERTY_HINT_LAYERS_2D_PHYSICS, "Collision Mask") var collision_mask : int = 1

func _initialize() -> void:
	if !interactor:
		interactor = Area2D.new()
		interactor.collision_layer = collision_layer
		interactor.collision_mask = collision_mask
	collshape = CollisionShape2D.new()
	collshape.shape = shape
	interactor.add_to_group("Interactor")
	add_child(interactor)
	interactor.add_child(collshape)
	player.move_component().direction_changed.connect(update)
	assert(interactor != null, "Interactor should never be NULL")

func _ready() -> void:
	super()
	call_deferred("_initialize")

func update(_prev_dir,new_direction):
	if Engine.is_editor_hint(): return
	interactor.position = new_direction * GameManager.tile_size
