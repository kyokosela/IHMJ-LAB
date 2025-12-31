extends World

@onready var main_door : InteractableTask = %MainDoor

func _ready() -> void:
	super()
	GameManager.new_game()
	if EventManager.is_event_active("TUTORIAL") :
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "Tengo que ducharme.")
		main_door.executed.connect(func () : 
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "Aquí vamos.")
			#TODO cuando exita aplicar
			#Dialogic.timeline_ended.connect(ZoneManager.change_zone.bind(ZoneManager.CALLE O ALGO ASI))
			)
