extends Component
class_name InteractionComponent

@export var interactor : Area2D

func _ready() -> void:
	await super()
	if !interactor:
		find_child("Interactor")
	assert(interactor != null, "Interactor should never be NULL")

func _process(delta: float) -> void:
	var movement : MovementComponent = entity.get_component("MovementComponent")
	interactor.position = movement.last_facing_dir * movement.tile_size
