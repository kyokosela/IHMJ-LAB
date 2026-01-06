extends CanvasLayer

@onready var energy_var : TextureProgressBar = %EnergyBar
@onready var health_bar : TextureProgressBar = %HealthBar
@onready var time_label : Label = %TimeLabel

func _ready() -> void:
	energy_var.value = PlayerManager.get_stat_value("ENERGY")
	health_bar.value = PlayerManager.get_stat_value("HEALTH")
	
	PlayerManager.connect_to_stat("ENERGY", func (_new_value) : energy_var.value = _new_value) 
	PlayerManager.connect_to_stat("HEALTH", func (_new_value) : health_bar.value = _new_value)
	TimeManager.minutes_changed.connect(func (_minutes) : time_label.text = TimeManager.format_minutes(_minutes))
