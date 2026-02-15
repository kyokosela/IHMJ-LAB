extends Node

signal email_sent(email_id: String)
signal daily_emails_loaded(count: int)

const EMAIL_ENTRIES_PATH: String = "res://Resources/Computer/Apps/Mail/Entries/Narrative/"

var all_emails: Array[MailEntry] = []
var sent_email_ids: Array[String] = []
var _emails_by_day: Dictionary = {}

func _ready() -> void:
	_load_all_emails()
	_organize_by_day()

func get_emails_for_day(day: int) -> Array[MailEntry]:
	var result: Array[MailEntry] = []
	if not _emails_by_day.has(day):
		daily_emails_loaded.emit(0)
		return result

	for entry: Variant in _emails_by_day[day]:
		if not entry is MailEntry:
			continue
		var email: MailEntry = entry
		if email.email_id in sent_email_ids:
			continue
		if email.can_appear():
			result.append(email)

	daily_emails_loaded.emit(result.size())
	return result

func mark_sent(email_id: String) -> void:
	if email_id in sent_email_ids:
		return
	sent_email_ids.append(email_id)
	email_sent.emit(email_id)

func was_sent(email_id: String) -> bool:
	return email_id in sent_email_ids

func get_processed_count() -> int:
	return sent_email_ids.size()

func get_fixed_email_count() -> int:
	var count: int = 0
	for email: MailEntry in all_emails:
		if not email.is_conditional:
			count += 1
	return count

func get_save_data() -> Dictionary:
	return {
		"sent_email_ids": sent_email_ids.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	sent_email_ids.clear()
	var raw_ids: Array = data.get("sent_email_ids", [])
	for id_value: Variant in raw_ids:
		sent_email_ids.append(str(id_value))

func _load_all_emails() -> void:
	all_emails.clear()

	var dir: DirAccess = DirAccess.open(EMAIL_ENTRIES_PATH)
	if dir == null:
		push_warning("EmailPoolManager: Could not open email directory: %s" % EMAIL_ENTRIES_PATH)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			var loaded: Resource = load(EMAIL_ENTRIES_PATH + file_name)
			if loaded is MailEntry:
				var email: MailEntry = loaded
				if not email.email_id.is_empty():
					all_emails.append(email)
		file_name = dir.get_next()
	dir.list_dir_end()

func _organize_by_day() -> void:
	_emails_by_day.clear()
	for email: MailEntry in all_emails:
		var day: int = email.day_available
		if not _emails_by_day.has(day):
			_emails_by_day[day] = []
		_emails_by_day[day].append(email)
