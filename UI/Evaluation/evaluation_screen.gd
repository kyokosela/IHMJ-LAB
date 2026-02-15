extends Control

signal evaluation_closed

var performance_label: Label
var emails_processed_label: Label
var attendance_label: Label
var salary_label: Label
var token_label: Label
var close_button: Button

var _evaluation_data: Dictionary = {}

func _ready() -> void:
	_resolve_ui()
	if close_button != null:
		close_button.pressed.connect(_on_close_pressed)
	hide()

func _resolve_ui() -> void:
	performance_label = get_node_or_null("%PerformanceLabel") as Label
	emails_processed_label = get_node_or_null("%EmailsProcessedLabel") as Label
	attendance_label = get_node_or_null("%AttendanceLabel") as Label
	salary_label = get_node_or_null("%SalaryLabel") as Label
	token_label = get_node_or_null("%TokenLabel") as Label
	close_button = get_node_or_null("%CloseButton") as Button

	if performance_label == null:
		performance_label = get_node_or_null("Container/Efficiency") as Label
	if emails_processed_label == null:
		emails_processed_label = get_node_or_null("Container/EmailsProcessed") as Label
	if attendance_label == null:
		attendance_label = get_node_or_null("Container/ErrorsMade") as Label
	if salary_label == null:
		salary_label = get_node_or_null("Container/TasksCompleted") as Label
	if token_label == null:
		token_label = get_node_or_null("Container/Result") as Label

func show_evaluation() -> void:
	_calculate_results()
	_update_display()
	show()

func _calculate_results() -> void:
	var emails_done: int = EmailPoolManager.get_processed_count()
	var emails_expected: int = 27
	var rate: float = (float(emails_done) / float(emails_expected)) * 100.0 if emails_expected > 0 else 0.0

	var absences: int = AttendanceManager.get_absence_count()
	var lates: int = AttendanceManager.get_late_count()
	var deductions: int = AttendanceManager.get_weekly_deductions()

	var gross_salary: int = EconomyManager.calculate_weekly_gross()
	var net_salary: int = max(0, gross_salary - deductions)

	var token_eligible: bool = rate >= 100.0 and absences == 0 and lates <= 1

	_evaluation_data = {
		"emails_done": emails_done,
		"emails_expected": emails_expected,
		"performance_rate": rate,
		"absences": absences,
		"lates": lates,
		"gross_salary": gross_salary,
		"net_salary": net_salary,
		"deductions": deductions,
		"token_eligible": token_eligible
	}

func _update_display() -> void:
	if performance_label != null:
		performance_label.text = "Rendimiento: %.1f%%" % _evaluation_data["performance_rate"]

	if emails_processed_label != null:
		emails_processed_label.text = "Correos: %d/%d" % [
			_evaluation_data["emails_done"],
			_evaluation_data["emails_expected"]
		]

	if attendance_label != null:
		attendance_label.text = "Asistencia: %d faltas, %d tardanzas" % [
			_evaluation_data["absences"],
			_evaluation_data["lates"]
		]

	if salary_label != null:
		if _evaluation_data["deductions"] > 0:
			salary_label.text = "Salario: S/%d (-%d deducciones)" % [
				_evaluation_data["net_salary"],
				_evaluation_data["deductions"]
			]
		else:
			salary_label.text = "Salario: S/%d" % _evaluation_data["net_salary"]

	if token_label != null:
		if _evaluation_data["token_eligible"]:
			token_label.text = "Token de Ascenso: DISPONIBLE"
			token_label.modulate = Color.GREEN
			NarrativeFlags.set_flag("token_earned")
		else:
			token_label.text = "Token de Ascenso: No calificado"
			token_label.modulate = Color.GRAY

	NarrativeFlags.set_flag("evaluation_completed")

func _on_close_pressed() -> void:
	hide()
	evaluation_closed.emit()
