extends Entity
class_name Player

var interaction : InteractionComponent
const MAYUI_WORK_BODY_TEST = preload("uid://cnwqcbdmj2h5j")

func _ready() -> void:
	super()
	add_to_group("Player")

func _initialize() -> void:
	fsm = get_component("FSMComponent")
	movement = get_component("MovementComponent")
	sprite = get_component("SpriteComponent")
	interaction = get_component("InteractionComponent")
	inventory = get_component("InventoryContainer")
	
	Dialogic.timeline_started.connect(func(): movement.can_move = false)
	Dialogic.timeline_ended.connect(func(): movement.can_move = true)

func _process(_delta: float) -> void:
	pass

# MEME
#func random_color() -> Color:
	#randomize()
#
	## Generate a random hue (0.0 to 1.0)
	#var random_hue = randf()
	#
	## Set saturation and value to full or near full for vibrant colors
	#var saturation = 1.0 
	#var value = 1.0
#
	## Create the color using the static method Color.from_hsv()
	#var random_vibrant_color = Color.from_hsv(random_hue, saturation, value)
	#
	#return random_vibrant_color
