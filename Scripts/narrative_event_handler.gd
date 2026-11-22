extends Node

const EVALUATION_SCREEN := preload("res://UI/Evaluation/evaluation_screen.tscn")

## DONDE debe ocurrir cada evento con dialogo. Si Mayui no esta en una de estas zonas cuando
## llega la hora, el evento queda PENDIENTE y se entrega al entrar a la zona correcta.
## Los eventos que no aparecen aqui (solo ponen banderas, etc.) corren donde sea.
## Editar esta tabla para cambiar donde sucede un evento.
var event_zones : Dictionary = {
	"DAY1_CASERO_INTRO": [ZoneManager.ZONES.LOBBY],       # el casero la intercepta al salir del edificio
	"DAY1_VEDA_APPEAR": [ZoneManager.ZONES.OFFICE],
	"DAY2_MADINA_CAFE": [ZoneManager.ZONES.OFFICE],
	"DAY3_MADINA_TENSION": [ZoneManager.ZONES.OFFICE],
	"DAY4_MADINA_OBJECT": [ZoneManager.ZONES.OFFICE],
	"DAY4_RENT_REMINDER": [ZoneManager.ZONES.LOBBY],
	"DAY5_EVALUATION": [ZoneManager.ZONES.OFFICE],
	"DAY7_CASERO_FINAL": [ZoneManager.ZONES.LOBBY],
	"DAY7_WEEK_PREP": [ZoneManager.ZONES.APARTMENT],
}
var rent_overdue_zones : Array = [ZoneManager.ZONES.LOBBY] # advertencias del casero por renta vencida

## Historia de relleno APAGADA hasta que Ramiro escriba el guion (pidio evitar cosas inventadas).
## Los eventos de `story_events` no se ejecutan y tampoco el despido; para encenderla: story_enabled = true.
## El casero (renta), el arcade y el mercado NO son relleno: siguen funcionando.
var story_enabled : bool = false
var story_events : Array[String] = [
	"DAY1_VEDA_APPEAR", "DAY2_MADINA_CAFE", "DAY3_MADINA_TENSION", "DAY4_MADINA_OBJECT",
	"DAY5_EVALUATION", "DAY7_MADINA_LAUNDRY", "DAY7_WEEK_PREP",
]

var _pending : Array[Dictionary] = [] ## eventos que ya llegaron a su hora pero esperan a que Mayui este en su zona

func _ready() -> void:
	ZoneManager.zone_ready.connect(_on_zone_ready)
	TimeManager.day_changed.connect(_on_day_changed)
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

#region Entrega por zona
## Zona donde esta Mayui ahora: la del mundo realmente cargado (no la "destino" mientras viaja).
func _current_zone() -> int:
	if ZoneManager.zone_node != null:
		return ZoneManager.zone_node.zone_id
	return ZoneManager.current_zone

## Ejecuta la accion ya si Mayui esta en una zona valida; si no, queda pendiente.
func _deliver(key: String, zones: Array, action: Callable) -> void:
	if zones.is_empty() or _current_zone() in zones:
		action.call()
		return
	_pending.append({"key": key, "zones": zones, "action": action})
	print("[Eventos] '%s' pendiente: espera a que Mayui llegue a %s" % [key, zones])

func _on_zone_ready(zone_id: int) -> void:
	var due : Array = _pending.filter(func(p : Dictionary) -> bool: return zone_id in p.zones)
	if due.is_empty():
		return
	await get_tree().create_timer(0.8).timeout # dejar que termine el fundido de entrada
	for p : Dictionary in due:
		if not _pending.has(p):
			continue
		_pending.erase(p)
		if Dialogic.current_timeline != null: # uno por uno, sin superponer dialogos
			await Dialogic.timeline_ended
		print("[Eventos] entregando '%s' en la zona %d" % [p.key, zone_id])
		await p.action.call()

## Un evento pendiente que no se pudo entregar el mismo dia se descarta (ya paso su momento).
func _on_day_changed(_day: int) -> void:
	if not _pending.is_empty():
		print("[Eventos] descartados por cambio de dia: ", _pending.map(func(p : Dictionary) -> String: return p.key))
	_pending.clear()
#endregion

func _on_event_activated(event_name: String) -> void:
	if not story_enabled and event_name in story_events:
		print("[Eventos] '%s' es historia de relleno: apagada (story_enabled = false)" % event_name)
		return
	var zones : Array = event_zones.get(event_name, [])
	_deliver(event_name, zones, _run_event.bind(event_name))

func _run_event(event_name: String) -> void:
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
	_deliver("RENT_OVERDUE_%d" % warnings, rent_overdue_zones, _rent_overdue_now.bind(warnings))

func _rent_overdue_now(warnings: int) -> void:
	match warnings:
		1:
			Dialogic.start("casero_rent_warning1")
		2:
			NarrativeFlags.set_flag("desalojo_lunes")
			Dialogic.start("casero_rent_final")

func _on_fired(reason: String) -> void:
	if not story_enabled:
		return   # el despido (dialogo y correo) todavia no se necesita
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
