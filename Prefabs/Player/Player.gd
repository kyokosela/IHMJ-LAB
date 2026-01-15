extends Entity
class_name Player

var interaction : InteractionComponent
@onready var spin_box: SpinBox = $CanvasLayer/Control/SpinBox

var test_index = 0

func _ready() -> void:
	super()
	add_to_group("Player")

func _initialize() -> void:
	super()
	interaction = get_component("InteractionComponent")
	
	Dialogic.timeline_started.connect(_on_dialogic_timeline_started)
	Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
	
func _on_dialogic_timeline_started():
	movement.can_move = false
	
func _on_dialogic_timeline_ended():
	movement.can_move = true

#TODO: borrar this shit :sob:
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("test_2"):
		add_item_by_data(preload("uid://dd0yw2ehhs2s5"))
		add_item_by_data(preload("uid://bmt41wvyxm0ut"))
		add_item_by_data(preload("uid://dn6xorxxwrnh3"))
		sprite.change_layer("body",preload("uid://cnwqcbdmj2h5j"))
	if event.is_action_pressed("test"):
		inventory.use_item_at(test_index)


func _process(_delta: float) -> void:
	pass

func _on_spin_box_value_changed(value: float) -> void:
	test_index = value
	spin_box.focus_exited.emit()
	


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
