extends World

const WORKSPACE_SCENE := preload("res://Prefabs/Workspace/Workspace.tscn")
const PORTAL_SCENE := preload("res://Prefabs/Workspace/Computer/Apps/Portal/portal.tscn")
const EVALUATION_SCENE := preload("res://UI/Evaluation/evaluation_screen.tscn")

@onready var status_label: RichTextLabel = %StatusLabel
@onready var day_spin: SpinBox = %DaySpin
@onready var time_input: LineEdit = %TimeInput
@onready var flag_input: LineEdit = %FlagInput
@onready var action_label: Label = %ActionLabel

@onready var workspace_mount: Node = %WorkspaceMount
@onready var portal_overlay: Control = %PortalOverlay
@onready var portal_host: Control = %PortalHost
@onready var eval_overlay: Control = %EvaluationOverlay
@onready var eval_host: Control = %EvaluationHost
@onready var workspace_overlay: Control = %WorkspaceOverlay
@onready var workspace_host: SubViewportContainer = %WorkspaceHost

const DESKTOP_SCENE := preload("res://Prefabs/Workspace/Computer/Desktop.tscn")
const DESKTOP_PROFILE := preload("res://Resources/Computer/Profiles/CreatedProfiles/mayui_pc.tres")

var workspace_instance: CanvasLayer  # Legacy - kept for compatibility
var desktop_instance: Desktop

var debug_panel: Window

func _ready() -> void:
	super()
	debug_panel = get_node_or_null("DebugPanel") as Window
	_setup_debug_panel()
	_bootstrap_runtime()
	_bind_signals()
	_refresh_status()

func _setup_debug_panel() -> void:
	if debug_panel == null:
		return
	debug_panel.position = Vector2i(10, 10)
	debug_panel.size = Vector2i(400, 350)
	debug_panel.hide()

func _toggle_debug_panel() -> void:
	if debug_panel == null:
		_set_action("Debug panel not available")
		return
	debug_panel.visible = not debug_panel.visible
	_set_action("Debug panel %s" % ("shown" if debug_panel.visible else "hidden"))

func _bootstrap_runtime() -> void:
	# Clear all managers to fresh state
	AttendanceManager.load_save_data({})
	EconomyManager.load_save_data({})
	RelationshipManager.load_save_data({})
	NarrativeFlags.load_save_data({})
	EmailPoolManager.load_save_data({})
	
	# Clear any active events from previous runs
	EventManager.stack_active_events.clear()
	
	# Don't call GameManager.new_game() - it loads tutorial and schedule events
	# which auto-trigger dialogues. For playground, we want manual control only.
	
	# Set up lapse events for effects (without schedule events)
	EventManager.create_lapse_event("16:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/smelly.tres")), "AUTO_SMELLY_LAPSE", "SMELLY_TIMER", true)
	EventManager.create_lapse_event("06:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/hunger.tres")), "AUTO_HUNGER_LAPSE", "HUNGER_TIMER", true)
	EventManager.create_lapse_event("16:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/sleepy.tres")), "AUTO_SLEEPY_LAPSE", "SLEEPY_TIMER", true)
	
	# Reset time to Day 1 morning
	TimeManager.julian_day = 0
	TimeManager.week = 1
	TimeManager.day = 1
	TimeManager.set_current_time("07:30")
	
	# Clear any active effects
	var effect_names: Array[String] = []
	for effect in PlayerManager.effects:
		effect_names.append(effect.effect_unique_name)
	for effect_name in effect_names:
		PlayerManager.remove_effect(effect_name)
	
	# Reset sanity to neutral
	PlayerManager.sanity_value = 50.0

	_set_action("Session bootstrapped (no auto-events)")

func _bind_signals() -> void:
	%BootstrapButton.pressed.connect(_bootstrap_runtime)
	%RefreshButton.pressed.connect(_refresh_status)
	%ToggleDebugButton.pressed.connect(_toggle_debug_panel)
	%ApplyTimeButton.pressed.connect(_on_apply_time)
	%AddHourButton.pressed.connect(func() -> void: TimeManager.add_to_current_time("01:00"))

	%ClockInButton.pressed.connect(func() -> void: AttendanceManager.clock_in())
	%ClockOutButton.pressed.connect(func() -> void: AttendanceManager.clock_out())
	%MarkAbsenceButton.pressed.connect(func() -> void: AttendanceManager.record_absence())

	%AddMoneyButton.pressed.connect(func() -> void: EconomyManager.add_money(100, "DEV_HARNESS"))
	%PayRentButton.pressed.connect(_on_pay_rent)
	%CheckRentButton.pressed.connect(func() -> void: EconomyManager.check_rent_due())
	%BusFareButton.pressed.connect(_on_bus_fare)

	%SetFlagButton.pressed.connect(_on_set_flag)
	%ClearFlagButton.pressed.connect(_on_clear_flag)

	%ToggleWorkspaceButton.pressed.connect(_toggle_workspace)
	%CloseWorkspaceButton.pressed.connect(func() -> void: workspace_overlay.hide())
	%OpenPortalButton.pressed.connect(_open_portal)
	%ClosePortalButton.pressed.connect(func() -> void: portal_overlay.hide())
	%OpenEvaluationButton.pressed.connect(_open_evaluation)
	%CloseEvaluationButton.pressed.connect(func() -> void: eval_overlay.hide())

	%SaveButton.pressed.connect(func() -> void: SaveManager.save_to_disk("integration"))
	%LoadButton.pressed.connect(func() -> void: SaveManager.load_from_disk("integration"))

	%TriggerEvalButton.pressed.connect(func() -> void: EventManager.execute_event("DAY5_EVALUATION"))
	%TriggerM88Button.pressed.connect(func() -> void: NarrativeFlags.set_flag("email_37_available"))
	%TriggerWarning1Button.pressed.connect(func() -> void: NarrativeFlags.set_flag("absence_warning_1"))
	%TriggerWarning2Button.pressed.connect(func() -> void: NarrativeFlags.set_flag("absence_warning_2"))
	%TestSleepButton.pressed.connect(func() -> void: PlayerManager.request_sleep(PlayerManager.BED_TYPE.TYPE_C))

	%ScenarioDay1Button.pressed.connect(_scenario_day1)
	%ScenarioDay5Button.pressed.connect(_scenario_day5)
	%ScenarioWeekendButton.pressed.connect(_scenario_weekend)
	%ScenarioSundayButton.pressed.connect(_scenario_sunday)

	TimeManager.time_changed.connect(_on_runtime_changed)
	EconomyManager.money_changed.connect(_on_runtime_changed.bind())
	AttendanceManager.warning_issued.connect(_on_warning)
	NarrativeFlags.flag_set.connect(_on_flag_changed)
	NarrativeFlags.flag_cleared.connect(_on_flag_cleared)
	EmailPoolManager.email_sent.connect(_on_email_sent)
	ZoneManager.street_risk_triggered.connect(_on_street_risk_triggered)

func _on_apply_time() -> void:
	TimeManager.day = int(day_spin.value)
	if TimeUtils.is_valid_format(time_input.text):
		TimeManager.set_current_time(time_input.text)
		_set_action("Time updated to D%s %s" % [TimeManager.day, TimeManager.get_current_time()])
	else:
		_set_action("Invalid time format, expected HH:MM")
	_refresh_status()

func _on_pay_rent() -> void:
	var paid := EconomyManager.pay_rent()
	_set_action("Rent paid" if paid else "Rent payment failed")
	_refresh_status()

func _on_bus_fare() -> void:
	var paid := EconomyManager.pay_bus()
	_set_action("Bus fare paid" if paid else "Insufficient bus fare")
	_refresh_status()

func _on_set_flag() -> void:
	var key := flag_input.text.strip_edges()
	if key.is_empty():
		_set_action("Flag name is empty")
		return
	NarrativeFlags.set_flag(key)

func _on_clear_flag() -> void:
	var key := flag_input.text.strip_edges()
	if key.is_empty():
		_set_action("Flag name is empty")
		return
	NarrativeFlags.clear_flag(key)

func _toggle_workspace() -> void:
	if desktop_instance == null:
		# Create desktop inside the SubViewport
		var viewport := workspace_host.get_node("SubViewport") as SubViewport
		desktop_instance = DESKTOP_SCENE.instantiate() as Desktop
		desktop_instance.current_profile = DESKTOP_PROFILE
		viewport.add_child(desktop_instance)
	
	workspace_overlay.visible = not workspace_overlay.visible
	_set_action("Workspace %s" % ("opened" if workspace_overlay.visible else "hidden"))

func interaction_open_workspace() -> void:
	if not workspace_overlay.visible:
		_toggle_workspace()
	else:
		_set_action("Workspace already open")

func _open_portal() -> void:
	for child in portal_host.get_children():
		child.queue_free()
	portal_host.add_child(PORTAL_SCENE.instantiate())
	portal_overlay.show()
	_set_action("Portal opened")

func interaction_open_portal() -> void:
	_open_portal()

func _open_evaluation() -> void:
	for child in eval_host.get_children():
		child.queue_free()
	var eval_screen := EVALUATION_SCENE.instantiate()
	eval_host.add_child(eval_screen)
	if eval_screen.has_method("show_evaluation"):
		eval_screen.show_evaluation()
	eval_overlay.show()
	_set_action("Evaluation opened")

func interaction_open_evaluation() -> void:
	_open_evaluation()

func _on_warning(type: String, count: int) -> void:
	_set_action("Warning %s (#%d)" % [type, count])
	_refresh_status()

func _on_flag_changed(flag_name: String, _value: Variant) -> void:
	_set_action("Flag set: %s" % flag_name)
	_refresh_status()

func _on_flag_cleared(flag_name: String) -> void:
	_set_action("Flag cleared: %s" % flag_name)
	_refresh_status()

func _on_email_sent(email_id: String) -> void:
	_set_action("Email completed: %s" % email_id)
	_refresh_status()

func _on_street_risk_triggered(chance: float, roll: float) -> void:
	_set_action("Street risk triggered (roll %.2f <= %.2f)" % [roll, chance])
	_refresh_status()

func _on_runtime_changed(_a: Variant = null, _b: Variant = null, _c: Variant = null, _d: Variant = null, _e: Variant = null) -> void:
	_refresh_status()

func _set_action(text: String) -> void:
	action_label.text = "Last action: %s" % text

func _refresh_status() -> void:
	day_spin.value = TimeManager.day
	time_input.text = TimeManager.get_current_time()

	var flags := NarrativeFlags.get_save_data().keys()
	flags.sort()

	var active_events: Array[String] = []
	for event in EventManager.stack_active_events:
		if event != null:
			active_events.append(event.event_unique_name)
	active_events.sort()

	var zone_name := ZoneManager.get_zone_name(ZoneManager.current_zone)
	var active_effects: Array[String] = []
	for effect in PlayerManager.effects:
		var effect_name := effect.effect_unique_name
		if effect is EffectLevel:
			var lvl_effect := effect as EffectLevel
			effect_name += " (Lv%d, %dd)" % [int(lvl_effect.level + 1), lvl_effect.days_active]
		active_effects.append(effect_name)
	
	var work_success_rate := PlayerManager.get_work_success_rate() * 100.0
	var work_fail_chance := PlayerManager.get_work_failure_chance() * 100.0
	
	status_label.text = """[b]ZONE[/b]
Current: %s

[b]EFFECTS[/b]
Active: %s

[b]STATS[/b]
Energy: %.0f  Sanity: %.0f

[b]WORK TASK[/b]
Success Rate: %.0f%%  Fail Chance: %.0f%%

[b]TIME[/b]
Day: %d  Week: %d  Weekday: %s  Time: %s

[b]ECONOMY[/b]
Money: S/%d  RentPaid: %s  RentWarnings: %d

[b]ATTENDANCE[/b]
AtWork: %s  ArrivedToday: %s
Absences: %d  Lates: %d  Deductions: S/%d

[b]EMAIL[/b]
Processed: %d  Today's available: %d

[b]EVENTS[/b]
Active (%d): %s

[b]FLAGS[/b]
Count: %d
%s
""" % [
		zone_name,
		", ".join(active_effects) if not active_effects.is_empty() else "none",
		PlayerManager.get_stat_value("ENERGY"),
		PlayerManager.sanity_value,
		work_success_rate,
		work_fail_chance,
		TimeManager.day,
		TimeManager.week,
		TimeManager.get_week_day_name(),
		TimeManager.get_current_time(),
		EconomyManager.get_balance(),
		str(EconomyManager.is_rent_paid()),
		EconomyManager.get_rent_warnings(),
		str(AttendanceManager.is_at_work),
		str(AttendanceManager.arrived_today),
		AttendanceManager.get_absence_count(),
		AttendanceManager.get_late_count(),
		AttendanceManager.get_weekly_deductions(),
		EmailPoolManager.get_processed_count(),
		EmailPoolManager.get_emails_for_day(TimeManager.day).size(),
		active_events.size(),
		", ".join(active_events) if not active_events.is_empty() else "none",
		flags.size(),
		", ".join(flags) if not flags.is_empty() else "none"
	]


# ─── Scenario Quick-Starts ───────────────────────────────────────────────────

func _scenario_day1() -> void:
	_bootstrap_runtime()
	TimeManager.day = 1
	TimeManager.set_current_time("07:30")
	PlayerManager.slept_today = false
	_set_action("ESCENARIO Día 1 — despierta, habla con casero, ve al trabajo")
	_refresh_status()

func _scenario_day5() -> void:
	_bootstrap_runtime()
	TimeManager.day = 5
	TimeManager.set_current_time("14:55")
	PlayerManager.slept_today = false
	NarrativeFlags.set_flag("casero_intro_done")
	NarrativeFlags.set_flag("met_veda_day1")
	EconomyManager.add_money(50, "SCENARIO_SETUP")
	_set_action("ESCENARIO Día 5 — evaluación se activa a las 15:00 (faltan 5 min)")
	_refresh_status()

func _scenario_weekend() -> void:
	_bootstrap_runtime()
	TimeManager.day = 6
	TimeManager.set_current_time("10:00")
	PlayerManager.slept_today = false
	NarrativeFlags.set_flag("casero_intro_done")
	NarrativeFlags.set_flag("met_veda_day1")
	NarrativeFlags.set_flag("arcade_open")
	NarrativeFlags.set_flag("market_open")
	EconomyManager.add_money(150, "SCENARIO_SETUP")
	_set_action("ESCENARIO Fin de semana — ve a COMMERCIAL, usa arcade y mercado")
	_refresh_status()

func _scenario_sunday() -> void:
	_bootstrap_runtime()
	TimeManager.day = 7
	TimeManager.set_current_time("16:55")
	PlayerManager.slept_today = false
	NarrativeFlags.set_flag("casero_intro_done")
	NarrativeFlags.set_flag("met_veda_day1")
	_set_action("ESCENARIO Domingo — sunday_prep se activa a las 17:00 (faltan 5 min)")
	_refresh_status()
