extends World

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	TimeManager.minutes = 360
	GameManager.new_game()
