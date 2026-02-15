extends Panel

## Simple inbox panel with scrollable mail list
## Replaces physics-based system with Control-based list

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var mail_list: VBoxContainer = %MailList

func add_mail_item(item: Control) -> void:
	mail_list.add_child(item)
	# Auto-scroll to show new mail (optional)
	await get_tree().process_frame
	scroll_container.scroll_vertical = 0  # Scroll to top for newest

func get_mail_count() -> int:
	return mail_list.get_child_count()

func clear_all() -> void:
	for child in mail_list.get_children():
		child.queue_free()
