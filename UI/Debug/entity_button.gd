extends HBoxContainer

var entity: Entity
var debug : DebugPanel
@onready var button: Button = $Button

func _ready() -> void:
	button.pressed.connect(func(): debug.current_entity = entity)

func setup(p_debug: DebugPanel,p_entity : Entity) -> void:
	debug = p_debug
	entity = p_entity
	button.text = p_entity.name
	
