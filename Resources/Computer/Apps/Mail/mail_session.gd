extends AppSession
class_name MailSession

@export var completed_mails_ids: Array[String] = []

func mark_completed(id: String) -> void:
	if id not in completed_mails_ids:
		completed_mails_ids.append(id)
		emit_changed()
		
func is_mail_completed(id: String) -> bool:
	return id in completed_mails_ids
