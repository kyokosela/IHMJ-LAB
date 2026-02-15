extends Control
class_name PortalApp

var salary_section: VBoxContainer
var attendance_section: VBoxContainer
var evaluation_section: VBoxContainer

func _ready() -> void:
	_resolve_sections()
	_update_all_sections()

func _resolve_sections() -> void:
	salary_section = get_node_or_null("%SalarySection") as VBoxContainer
	attendance_section = get_node_or_null("%AttendanceSection") as VBoxContainer
	evaluation_section = get_node_or_null("%EvaluationSection") as VBoxContainer

	if salary_section == null:
		salary_section = get_node_or_null("TabContainer/Salario") as VBoxContainer
	if attendance_section == null:
		attendance_section = get_node_or_null("TabContainer/Asistencia") as VBoxContainer
	if evaluation_section == null:
		evaluation_section = get_node_or_null("TabContainer/Evaluaciones") as VBoxContainer

func _update_all_sections() -> void:
	_update_salary_section()
	_update_attendance_section()
	_update_evaluation_section()

func _update_salary_section() -> void:
	if salary_section == null:
		return
	_clear_section(salary_section)

	var title := Label.new()
	title.text = "NOMINA"
	salary_section.add_child(title)

	var balance := Label.new()
	balance.text = "Saldo actual: S/%d" % EconomyManager.get_balance()
	salary_section.add_child(balance)

	var weekly := Label.new()
	weekly.text = "Salario semanal: S/%d" % EconomyManager.calculate_weekly_gross()
	salary_section.add_child(weekly)

	var deductions: int = AttendanceManager.get_weekly_deductions()
	if deductions > 0:
		var ded_label := Label.new()
		ded_label.text = "Deducciones: -S/%d" % deductions
		ded_label.modulate = Color.RED
		salary_section.add_child(ded_label)

func _update_attendance_section() -> void:
	if attendance_section == null:
		return
	_clear_section(attendance_section)

	var title := Label.new()
	title.text = "ASISTENCIA"
	attendance_section.add_child(title)

	var absences := Label.new()
	absences.text = "Faltas: %d" % AttendanceManager.get_absence_count()
	attendance_section.add_child(absences)

	var lates := Label.new()
	lates.text = "Tardanzas: %d" % AttendanceManager.get_late_count()
	attendance_section.add_child(lates)

	var warnings: Array[Dictionary] = AttendanceManager.get_warnings()
	if warnings.size() > 0:
		var warn_label := Label.new()
		warn_label.text = "Advertencias: %d" % warnings.size()
		warn_label.modulate = Color.ORANGE
		attendance_section.add_child(warn_label)

func _update_evaluation_section() -> void:
	if evaluation_section == null:
		return
	_clear_section(evaluation_section)

	var title := Label.new()
	title.text = "EVALUACION"
	evaluation_section.add_child(title)

	if NarrativeFlags.has_flag("evaluation_completed"):
		var status := Label.new()
		status.text = "Estado: Completada"
		evaluation_section.add_child(status)

		var emails := Label.new()
		emails.text = "Correos procesados: %d" % EmailPoolManager.get_processed_count()
		evaluation_section.add_child(emails)

		if NarrativeFlags.has_flag("token_earned"):
			var token := Label.new()
			token.text = "Token de Ascenso: DISPONIBLE"
			token.modulate = Color.GREEN
			evaluation_section.add_child(token)
	else:
		var pending := Label.new()
		pending.text = "Evaluacion pendiente (Viernes 15:00)"
		evaluation_section.add_child(pending)

func _clear_section(section: VBoxContainer) -> void:
	for child: Node in section.get_children():
		child.queue_free()
