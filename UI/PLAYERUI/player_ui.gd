extends CanvasLayer

@onready var energy_var : TextureProgressBar = %EnergyBar
@onready var health_bar : TextureProgressBar = %HealthBar
@onready var time_label : Label = %TimeLabel
@onready var effect_list : HBoxContainer = %EffectList

const effect_slot_scene : Resource = preload("res://UI/PLAYERUI/effect_slot.tscn")

func _ready() -> void:
	energy_var.value = PlayerManager.get_stat_value("ENERGY")
	#health_bar.value = PlayerManager.get_stat_value("HEALTH")
	
	PlayerManager.connect_to_stat("ENERGY", func (_new_value) : energy_var.value = _new_value) 
	#PlayerManager.connect_to_stat("HEALTH", func (_new_value) : health_bar.value = _new_value)
	TimeManager.minutes_changed.connect(func (_minutes) : time_label.text = TimeManager.format_minutes(_minutes))
	PlayerManager.effect_added.connect(create_effect_slot)
	PlayerManager.effect_removed.connect(remove_effect_slot)

func create_effect_slot(effect : Effect) -> void :
	if !effect.render : return
	var effect_slot : TextureRect = effect_slot_scene.instantiate()
	effect_slot.name = effect.effect_unique_name
	effect_slot.tooltip_text = effect.effect_display_name
	effect_list.add_child(effect_slot)
	

func remove_effect_slot(effect : Effect) -> void :
	if !effect.render : return
	var node = effect_list.get_node_or_null(effect.effect_unique_name)
	if node != null : node.queue_free()
