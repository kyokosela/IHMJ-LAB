extends Entity
class_name Player

var interaction : InteractionComponent

func _ready() -> void:
	super()
	add_to_group("Player")

func _initialize() -> void:
	fsm = get_component("FSMComponent")
	movement = get_component("MovementComponent")
	sprite = get_component("SpriteStackComponent")
	interaction = get_component("InteractionComponent")
	inventory = get_node_or_null("InventoryComponent")

func _process(_delta: float) -> void:
	set_animation_direction(facing_direction())

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
