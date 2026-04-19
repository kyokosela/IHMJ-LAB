extends Node

const EVALUATION_SCREEN := preload("res://UI/Evaluation/evaluation_screen.tscn")

func _ready() -> void:
	EventManager.event_activated.connect(_on_event_activated)
	EventManager.event_deactivaded.connect(_on_event_deactivated)

	EconomyManager.rent_due.connect(_on_rent_due)
	EconomyManager.rent_overdue.connect(_on_rent_overdue)
	AttendanceManager.fired.connect(_on_fired)
	AttendanceManager.warning_issued.connect(_on_warning_issued)
	RelationshipManager.relationship_milestone.connect(_on_relationship_milestone)
	EmailPoolManager.email_sent.connect(_on_email_sent)

	if Dialogic.has_signal("signal_event") and not Dialogic.signal_event.is_connected(_on_dialogic_signal_event):
		Dialogic.signal_event.connect(_on_dialogic_signal_event)

func _on_event_activated(event_name: String) -> void:
	match event_name:
		"DAY1_ALARM":
			_trigger_alarm_tutorial()
		"DAY1_CASERO_INTRO":
			_trigger_casero_intro()
		"DAY1_VEDA_APPEAR":
			_trigger_veda_day1()
		"DAY2_MADINA_CAFE":
			_trigger_madina_cafe_day2()
		"DAY3_MADINA_TENSION":
			_trigger_madina_tension()
		"DAY4_MADINA_OBJECT":
			_trigger_madina_m88_object()
		"DAY4_VEDA_STARE":
			_trigger_veda_stare()
		"DAY4_RENT_REMINDER":
			_trigger_rent_reminder()
		"DAY5_EVALUATION":
			_trigger_friday_evaluation()
		"DAY5_RENT_DUE":
			EconomyManager.check_rent_due()
		"DAY5_M88_EMAIL":
			_check_m88_email()
		"DAY6_MARKET":
			_trigger_weekend_market()
		"DAY6_ARCADE":
			NarrativeFlags.set_flag("arcade_open")
		"DAY7_MADINA_LAUNDRY":
			_trigger_madina_laundry()
		"DAY7_CASERO_FINAL":
			_trigger_casero_final()
		"DAY7_WEEK_PREP":
			_trigger_week_preparation()
		"DAY2_VEDA_EMAIL":
			NarrativeFlags.set_flag("day2_veda_email")
		"DAY3_PISO2_ORDER":
			NarrativeFlags.set_flag("spam_printer")
		"DAY4_VEDA_NOTICE":
			NarrativeFlags.set_flag("night_restriction")
			NarrativeFlags.set_flag("survey_enabled")
		"DAY5_SALARY":
			var salary_flag := "salary_paid_week_%d" % TimeManager.week
			if not NarrativeFlags.has_flag(salary_flag):
				EconomyManager.pay_weekly_salary(AttendanceManager.get_weekly_deductions())
				NarrativeFlags.set_flag(salary_flag)
		"WORK_HOURS_DAY2", "WORK_HOURS_DAY3", "WORK_HOURS_DAY4", "WORK_HOURS_DAY5":
			AttendanceManager.arrived_today = false

func _on_event_deactivated(event_name: String) -> void:
	match event_name:
		"WORK_HOURS", "WORK_HOURS_DAY2", "WORK_HOURS_DAY3", "WORK_HOURS_DAY4", "WORK_HOURS_DAY5":
			if not AttendanceManager.arrived_today:
				AttendanceManager.record_absence()

func _trigger_alarm_tutorial() -> void:
	NarrativeFlags.set_flag("tutorial_started")

func _trigger_casero_intro() -> void:
	if NarrativeFlags.has_flag("casero_intro_done"):
		return

	Dialogic.start("casero_intro")
	await Dialogic.timeline_ended
	NarrativeFlags.set_flag("casero_intro_done")

func _trigger_veda_day1() -> void:
	if NarrativeFlags.has_flag("met_veda_day1"):
		return

	Dialogic.start("veda_day1")
	await Dialogic.timeline_ended
	NarrativeFlags.set_flag("met_veda_day1")

func _trigger_madina_cafe_day2() -> void:
	if AttendanceManager.is_lunch_break():
		NarrativeFlags.set_flag("cafeteria_meal")
		Dialogic.start("madina_cafe_day2")
		RelationshipManager.add_points(RelationshipManager.NPC_MADINA, 25)

func _trigger_madina_tension() -> void:
	if AttendanceManager.is_lunch_break():
		Dialogic.start("madina_tension")
		RelationshipManager.add_points(RelationshipManager.NPC_MADINA, 25)

func _trigger_madina_m88_object() -> void:
	if AttendanceManager.is_lunch_break():
		Dialogic.start("madina_m88_object")

func _trigger_veda_stare() -> void:
	NarrativeFlags.set_flag("veda_stare_day4")

func _trigger_rent_reminder() -> void:
	NarrativeFlags.set_flag("rent_reminder_active")
	Dialogic.start("casero_rent_reminder")

func _trigger_friday_evaluation() -> void:
	if NarrativeFlags.has_flag("evaluation_completed"):
		return
	NarrativeFlags.set_flag("evaluation_started")
	Dialogic.start("friday_evaluation")
	await Dialogic.timeline_ended
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	get_tree().root.add_child(canvas)
	var screen := EVALUATION_SCREEN.instantiate()
	canvas.add_child(screen)
	screen.show_evaluation()
	await screen.evaluation_closed
	canvas.queue_free()

func _check_m88_email() -> void:
	if NarrativeFlags.has_flag("nota_madina"):
		NarrativeFlags.set_flag("email_37_available")

func _trigger_weekend_market() -> void:
	NarrativeFlags.set_flag("market_open")

func _trigger_week_preparation() -> void:
	Dialogic.start("sunday_prep")

func _trigger_madina_laundry() -> void:
	if RelationshipManager.get_level(RelationshipManager.NPC_MADINA) >= 2:
		Dialogic.start("madina_warning")

func _trigger_casero_final() -> void:
	if not EconomyManager.is_rent_paid():
		Dialogic.start("casero_rent_final")

func _on_rent_due() -> void:
	pass

func _on_rent_overdue(warnings: int) -> void:
	match warnings:
		1:
			Dialogic.start("casero_rent_warning1")
		2:
			NarrativeFlags.set_flag("desalojo_lunes")
			Dialogic.start("casero_rent_final")

func _on_fired(reason: String) -> void:
	NarrativeFlags.set_flag("fired")
	var timeline := "fired_absence"
	match reason:
		"EXCESSIVE_ABSENCES":
			timeline = "fired_absence"
		"LATE":
			timeline = "fired_late"
		"PERFORMANCE":
			timeline = "fired_performance"
	Dialogic.start(timeline)

func _on_warning_issued(type: String, _count: int) -> void:
	match type:
		"ABSENCE_1":
			NarrativeFlags.set_flag("absence_warning_1")
		"ABSENCE_2":
			NarrativeFlags.set_flag("absence_warning_2")
		"ABSENCE_SALARY_CUT":
			NarrativeFlags.set_flag("absence_salary_cut")

func _on_email_sent(email_id: String) -> void:
	if email_id == "email_04":
		NarrativeFlags.set_flag("reported_maintenance")

func _on_dialogic_signal_event(argument: Variant) -> void:
	var signal_name := ""
	if argument is String:
		signal_name = argument
	elif argument is Dictionary:
		if argument.has("arg"):
			signal_name = str(argument["arg"])
		elif argument.has("argument"):
			signal_name = str(argument["argument"])
		elif argument.has("signal_name"):
			signal_name = str(argument["signal_name"])

	match signal_name:
		"received_m88_note":
			NarrativeFlags.set_flag("nota_madina")
			NarrativeFlags.set_flag("email_37_available")
		"rejected_m88_note":
			NarrativeFlags.clear_flag("nota_madina")
		"casero_intro_complete":
			NarrativeFlags.set_flag("casero_intro_done")
		"rent_reminder_complete":
			NarrativeFlags.set_flag("rent_reminder_active")

func _on_relationship_milestone(_npc_id: String, _level: int) -> void:
	pass
