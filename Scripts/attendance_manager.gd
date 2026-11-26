extends Node

signal arrived_at_work(on_time: bool)
signal left_work(early: bool)
signal late_recorded(total_lates: int)
signal absence_recorded(total_absences: int)
signal warning_issued(type: String, count: int)
signal salary_deduction_applied(amount: int, reason: String)
signal fired(reason: String)

const WORK_START: String = "08:00"
const WORK_END: String = "17:00"
const LUNCH_START: String = "13:00"
const LUNCH_END: String = "13:45"

const ABSENCE_WARNING_1: int = 1
const ABSENCE_WARNING_2: int = 2
const ABSENCE_SALARY_CUT: int = 3
const ABSENCE_FIRED: int = 4

const LATE_SALARY_PENALTY: int = 20
const EARLY_LEAVE_PENALTY: int = 50

var late_count: int = 0
var absence_count: int = 0
var warnings: Array[Dictionary] = []

var is_at_work: bool = false
var arrived_today: bool = false
var absence_recorded_today: bool = false ## una falta cuenta una sola vez por dia (la anota el evento de las 17:00 o la medianoche)
var left_early_today: bool = false
var current_day_on_time: bool = true

var days_worked_this_week: int = 0
var total_deductions_this_week: int = 0
var salary_pending: bool = false ## el viernes a las 17:00 Mayui seguia fichada: se paga cuando marque la salida

func _ready() -> void:
	TimeManager.day_changed.connect(_on_day_changed)
	TimeManager.week_changed.connect(_on_week_changed)

func clock_in() -> void:
	if arrived_today:
		return

	arrived_today = true
	is_at_work = true

	var current_minutes := TimeManager.minutes
	var start_minutes := TimeManager.get_minutes(WORK_START)
	if current_minutes > start_minutes:
		current_day_on_time = false
		late_count += 1
		late_recorded.emit(late_count)
		_add_warning("LATE", "Llegada tarde: %s" % TimeManager.get_current_time())
		_apply_late_penalty()
		arrived_at_work.emit(false)
		return

	arrived_at_work.emit(true)

func clock_out(has_permission: bool = false) -> void:
	if not is_at_work:
		return

	is_at_work = false

	var current_minutes := TimeManager.minutes
	var end_minutes := TimeManager.get_minutes(WORK_END)
	if current_minutes < end_minutes and not has_permission:
		left_early_today = true
		_add_warning("EARLY_LEAVE", "Salida anticipada sin permiso")
		_apply_early_leave_penalty()
		left_work.emit(true)
		return

	days_worked_this_week += 1
	EconomyManager.record_daily_earnings(TimeManager.week_day, EconomyManager.DAILY_SALARY)
	left_work.emit(false)
	if salary_pending:
		pay_week_salary()

## Paga de la semana (D7: viernes 17:00, una sola vez; la pide el evento DAY5_SALARY). Si Mayui sigue fichada, espera a
## que marque la salida para contar tambien el viernes.
func pay_week_salary() -> void:
	salary_pending = is_at_work
	if not is_at_work:
		EconomyManager.pay_weekly_salary(total_deductions_this_week)

func is_work_hours() -> bool:
	var current := TimeManager.minutes
	var start := TimeManager.get_minutes(WORK_START)
	var end_time := TimeManager.get_minutes(WORK_END)
	return current >= start and current < end_time

func is_lunch_break() -> bool:
	var current := TimeManager.minutes
	var lunch_start := TimeManager.get_minutes(LUNCH_START)
	var lunch_end := TimeManager.get_minutes(LUNCH_END)
	return current >= lunch_start and current < lunch_end

func record_absence() -> void:
	if arrived_today or absence_recorded_today:
		return

	absence_recorded_today = true
	absence_count += 1
	absence_recorded.emit(absence_count)
	_add_warning("ABSENCE", "Ausencia dia %d" % TimeManager.day)
	_check_absence_consequences()

func get_weekly_deductions() -> int:
	return total_deductions_this_week

func get_late_count() -> int:
	return late_count

func get_absence_count() -> int:
	return absence_count

func get_warnings() -> Array[Dictionary]:
	return warnings

func is_fired() -> bool:
	return absence_count >= ABSENCE_FIRED

func get_save_data() -> Dictionary:
	return {
		"late_count": late_count,
		"absence_count": absence_count,
		"warnings": warnings.duplicate(true),
		"is_at_work": is_at_work,
		"arrived_today": arrived_today,
		"days_worked_this_week": days_worked_this_week,
		"total_deductions_this_week": total_deductions_this_week,
		"salary_pending": salary_pending
	}

func load_save_data(data: Dictionary) -> void:
	late_count = data.get("late_count", 0)
	absence_count = data.get("absence_count", 0)
	warnings.clear()
	var saved_warnings: Array = data.get("warnings", [])
	for item in saved_warnings:
		if item is Dictionary:
			warnings.append(item)
	is_at_work = data.get("is_at_work", false)
	arrived_today = data.get("arrived_today", false)
	days_worked_this_week = data.get("days_worked_this_week", 0)
	total_deductions_this_week = data.get("total_deductions_this_week", 0)
	salary_pending = data.get("salary_pending", false)

func _check_absence_consequences() -> void:
	match absence_count:
		ABSENCE_WARNING_1:
			warning_issued.emit("ABSENCE_1", 1)
		ABSENCE_WARNING_2:
			warning_issued.emit("ABSENCE_2", 2)
		ABSENCE_SALARY_CUT:
			var deduction := 100
			total_deductions_this_week += deduction
			salary_deduction_applied.emit(deduction, "ABSENCES")
			warning_issued.emit("ABSENCE_SALARY_CUT", 3)
		ABSENCE_FIRED:
			fired.emit("EXCESSIVE_ABSENCES")   # una sola vez: antes se repetia con cada falta nueva

func _apply_late_penalty() -> void:
	total_deductions_this_week += LATE_SALARY_PENALTY
	salary_deduction_applied.emit(LATE_SALARY_PENALTY, "LATE_ARRIVAL")

func _apply_early_leave_penalty() -> void:
	total_deductions_this_week += EARLY_LEAVE_PENALTY
	salary_deduction_applied.emit(EARLY_LEAVE_PENALTY, "EARLY_LEAVE")

func _add_warning(type: String, description: String) -> void:
	warnings.append({
		"type": type,
		"description": description,
		"day": TimeManager.day,
		"time": TimeManager.get_current_time()
	})

func _on_day_changed(_day: int) -> void:
	# Dentro de esta senal week_day todavia es el dia que TERMINA (antes se restaba uno de mas:
	# contaba el sabado como laboral y se saltaba el lunes).
	var ended_week_day := int(TimeManager.week_day)
	if ended_week_day >= 0 and ended_week_day <= 4 and not arrived_today:
		record_absence()

	absence_recorded_today = false
	arrived_today = false
	is_at_work = false
	left_early_today = false
	current_day_on_time = true

	# Si la paga del viernes no llego (no marco la salida, o el reloj salto las 17:00 mientras dormia), llega al acabar el dia
	if ended_week_day == TimeUtils.WEEKDAY.VIERNES:
		pay_week_salary()

func _on_week_changed(_week: int) -> void:
	days_worked_this_week = 0
	total_deductions_this_week = 0
