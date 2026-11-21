extends CanvasLayer

@onready var energy_bar : TextureProgressBar = %EnergyBar
@onready var health_bar : TextureProgressBar = %HealthBar
@onready var time_label : Label = %TimeLabel
@onready var money_label: Label = %MoneyLabel
@onready var day_label: Label = %DayLabel
@onready var effect_list : HBoxContainer = %EffectList

const effect_slot_scene : Resource = preload("res://UI/PLAYERUI/effect_slot.tscn")

func _ready() -> void:
	energy_bar.value = PlayerManager.get_stat_value("ENERGY")
	#health_bar.value = PlayerManager.get_stat_value("HEALTH")
	
	PlayerManager.connect_to_stat("ENERGY", _on_energy_changed) 
	#PlayerManager.connect_to_stat("HEALTH", _on_health_changed)
	TimeManager.minutes_changed.connect(_on_minutes_changed)
	_on_minutes_changed(TimeManager.minutes) # mostrar la hora actual desde el inicio, no "tiempo"
	PlayerManager.effect_added.connect(create_effect_slot)
	PlayerManager.effect_removed.connect(remove_effect_slot)

	EconomyManager.money_changed.connect(_on_money_changed)
	_update_money_display()

	TimeManager.day_changed.connect(_on_day_changed)
	_update_day_display()
	
func _on_energy_changed(_new_value):
	energy_bar.value = _new_value
	
func _on_health_changed(_new_value):
	health_bar.value = _new_value
	
func _on_minutes_changed(_minutes):
	time_label.text = TimeManager.format_minutes(_minutes)

func _on_money_changed(_new_amount: int, _delta: int) -> void:
	_update_money_display()

func _update_money_display() -> void:
	if money_label:
		money_label.text = "S/%d" % EconomyManager.money

func _on_day_changed(_day: int) -> void:
	_update_day_display()

func _update_day_display() -> void:
	if day_label:
		var day_names : Array[String] = ["LUN", "MAR", "MIE", "JUE", "VIE", "SAB", "DOM"]
		var week_day_index : int = TimeManager.week_day
		if week_day_index >= 0 and week_day_index < day_names.size():
			day_label.text = "DIA %d - %s" % [TimeManager.day, day_names[week_day_index]]

func create_effect_slot(effect : Effect) -> void :
	var node = effect_list.get_node_or_null(effect.effect_unique_name)
	if !effect.render or node != null : return
	
	var effect_slot : TextureRect = effect_slot_scene.instantiate()
	if effect is EffectLevel:
		effect_slot.texture = effect.get_stress_icon()
		effect.level_changed.connect(func (_new_level) : effect_slot.texture = effect.get_stress_icon())
	elif effect.icon != null:
		effect_slot.texture = effect.icon
	
	effect_slot.name = effect.effect_unique_name
	effect_slot.tooltip_text = effect.effect_display_name
	effect_list.add_child(effect_slot)
	
func remove_effect_slot(effect : Effect) -> void :
	if !effect.render : return
	var node = effect_list.get_node_or_null(effect.effect_unique_name)
	if node != null : node.queue_free()
