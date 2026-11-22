extends World

@onready var workspace : CanvasLayer = $Workspace

func interaction_open_workspace() -> void:
	if workspace.visible:
		return
	workspace.visible = true
	GameManager.modal_count += 1   # Mayui se queda quieta mientras el PC esta abierto

func _input(event: InputEvent) -> void:
	if workspace.visible and event.is_action_pressed("ui_cancel"):
		workspace.visible = false
		GameManager.modal_count -= 1
		get_viewport().set_input_as_handled()
