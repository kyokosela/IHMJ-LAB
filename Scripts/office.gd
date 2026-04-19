extends World

@onready var workspace : CanvasLayer = $Workspace

func interaction_open_workspace() -> void:
	workspace.visible = true

func _input(event: InputEvent) -> void:
	if workspace.visible and event.is_action_pressed("ui_cancel"):
		workspace.visible = false
		get_viewport().set_input_as_handled()
