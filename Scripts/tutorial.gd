extends World

@onready var main_door : InteractableTask = %MainDoor

func _ready() -> void:
	if GameManager.is_on_tutorial :
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "Tengo que ducharme.")
		main_door.executed.connect(func () : Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "Aquí vamos.")) # TODO aplicar el cambio de escena hacia el trabajo o calle
