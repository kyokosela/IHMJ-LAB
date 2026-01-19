extends CanvasLayer

@onready var energy_bar : TextureProgressBar = %EnergyBar
@onready var health_bar : TextureProgressBar = %HealthBar
@onready var time_label : Label = %TimeLabel
@onready var effect_list : HBoxContainer = %EffectList
@onready var energy_container : TextureRect = %EnergyCover

const effect_slot_scene : Resource = preload("res://UI/PLAYERUI/effect_slot.tscn")

@export var tween_time : float = 2

func _ready() -> void:
	energy_bar.value = PlayerManager.get_stat_value("ENERGY")
	#health_bar.value = PlayerManager.get_stat_value("HEALTH")
	
	PlayerManager.connect_to_stat("ENERGY", _on_energy_changed) 
	#PlayerManager.connect_to_stat("HEALTH", _on_health_changed)
	TimeManager.minutes_changed.connect(_on_minutes_changed)
	PlayerManager.effect_added.connect(create_effect_slot)
	PlayerManager.effect_removed.connect(remove_effect_slot)
	
func _on_energy_changed(_new_value):
	var tw = create_tween()
	tw.tween_property(energy_container, "modulate:a", 1, tween_time)
	tw.parallel().tween_property(energy_bar, "value", _new_value, tween_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_interval(tween_time)
	tw.tween_property(energy_container, "modulate:a", 0, tween_time)
	
	
func _on_health_changed(_new_value):
	health_bar.value = _new_value
	
func _on_minutes_changed(_minutes):
	time_label.text = TimeManager.format_minutes(_minutes)

func create_effect_slot(effect : Effect) -> void :
	var node = effect_list.get_node_or_null(effect.effect_unique_name)
	if !effect.render or node != null : return
	
	var effect_slot : TextureRect = effect_slot_scene.instantiate()
	if effect.icon != null : 
		if effect is EffectLevel : 
			effect_slot.texture = effect.get_stress_icon()
			effect.level_changed.connect(func (_new_level) : effect_slot.texture = effect.get_stress_icon())
		else :
			effect_slot.texture = effect.icon
	
	effect_slot.name = effect.effect_unique_name
	effect_slot.tooltip_text = effect.effect_display_name
	effect_list.add_child(effect_slot)
	
func remove_effect_slot(effect : Effect) -> void :
	if !effect.render : return
	var node = effect_list.get_node_or_null(effect.effect_unique_name)
	if node != null : node.queue_free()
