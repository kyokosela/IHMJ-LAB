extends Control

signal sleep_confirmed(hour_deal: String, bed_type: int)

const WAKE_CHANCE_BY_ENERGY : Array[Dictionary] = [
	{ "max_energy": 20.0, "chance": 0.25 },
	{ "max_energy": 40.0, "chance": 0.45 },
	{ "max_energy": 60.0, "chance": 0.65 },
	{ "max_energy": 80.0, "chance": 0.80 },
	{ "max_energy": 100.0, "chance": 0.95 },
]

var _bed_type : int = PlayerManager.BED_TYPE.TYPE_C
var _alarm_hours : int = 8

const INNER := "Center/Panel/VBox/Margin/Inner"

@onready var hour_label : Label = get_node(INNER + "/AlarmSection/HourRow/HourLabel")
@onready var wake_chance_label : Label = get_node(INNER + "/InfoSection/WakeChanceLabel")
@onready var insomnia_warning : Label = get_node(INNER + "/InfoSection/InsomniaWarning")
@onready var confirm_button : Button = get_node(INNER + "/Buttons/ConfirmButton")
@onready var no_alarm_button : Button = get_node(INNER + "/Buttons/NoAlarmButton")

func _ready() -> void:
	AudioManager.play_alarm()
	_refresh_hour_display()
	_refresh_wake_chance()
	confirm_button.pressed.connect(_on_confirm)
	no_alarm_button.pressed.connect(_on_no_alarm)
	get_node(INNER + "/AlarmSection/HourRow/PlusButton").pressed.connect(_on_hour_up)
	get_node(INNER + "/AlarmSection/HourRow/MinusButton").pressed.connect(_on_hour_down)
	confirm_button.grab_focus()

func setup(bed_type: int) -> void:
	_bed_type = bed_type
	var current_hour : int = TimeUtils.get_minutes(TimeManager.get_current_time()) / 60
	_alarm_hours = clampi(current_hour + 8, current_hour + 1, 23)
	_refresh_hour_display()
	_refresh_wake_chance()

func _on_hour_up() -> void:
	_alarm_hours = clampi(_alarm_hours + 1, 0, 23)
	_refresh_hour_display()
	_refresh_wake_chance()

func _on_hour_down() -> void:
	_alarm_hours = clampi(_alarm_hours - 1, 0, 23)
	_refresh_hour_display()
	_refresh_wake_chance()

func _refresh_hour_display() -> void:
	hour_label.text = "%02d:00" % _alarm_hours

func _refresh_wake_chance() -> void:
	var insomnia : EffectLevel = PlayerManager.get_effect_res("INSOMNIA") as EffectLevel
	if insomnia == null:
		wake_chance_label.visible = false
		insomnia_warning.visible = false
		return

	var energy : float = PlayerManager.get_stat_value("ENERGY")
	var chance : float = _get_wake_chance(energy)
	wake_chance_label.visible = true
	insomnia_warning.visible = true
	wake_chance_label.text = "Probabilidad de despertar: %d%%" % roundi(chance * 100)

	match insomnia.level:
		0: insomnia_warning.text = "Insomnio Lv1: dormirás entre 4-7h si la alarma falla"
		1: insomnia_warning.text = "Insomnio Lv2: dormirás entre 2-6h si la alarma falla"
		2: insomnia_warning.text = "Insomnio Lv3: dormirás entre 0-3h si la alarma falla"

func _get_wake_chance(energy: float) -> float:
	for entry in WAKE_CHANCE_BY_ENERGY:
		if energy <= entry.max_energy:
			return entry.chance
	return 0.95

func _on_confirm() -> void:
	var hour_deal : String = "%02d:00" % _alarm_hours
	var insomnia : EffectLevel = PlayerManager.get_effect_res("INSOMNIA") as EffectLevel
	if insomnia != null:
		var energy : float = PlayerManager.get_stat_value("ENERGY")
		var chance : float = _get_wake_chance(energy)
		if randf() > chance:
			hour_deal = "00:00"
	sleep_confirmed.emit(hour_deal, _bed_type)
	queue_free()

func _on_no_alarm() -> void:
	sleep_confirmed.emit("00:00", _bed_type)
	queue_free()
