extends World
## Apartamento: arranca la partida la primera vez y Mayui dice la primera frase de tu guion al levantarse. La puerta de salida
## es Scripts/HouseInteracts/exit_door.gd, que usa la lista de tareas del dev.

const FLAG_INTRO_SHOWN := "tutorial_intro_shown"
## Mayui despierta con Maloliente y Hambre (tu Bloque 1-1; SISTEMA_GAMEPLAY §8): se quitan al ducharse y al comer.
const START_EFFECTS : Array[Effect] = [
	preload("res://Resources/Effects/Effects/smelly.tres"),
	preload("res://Resources/Effects/Effects/hunger.tres"),
]

func _ready() -> void:
	super()
	# new_game() reinicia todo: solo debe correr la primera vez, no cada vez que se recarga el apartamento
	if not GameManager.game_started:
		GameManager.new_game()

	# (tras cargar una partida con la manana ya hecha, el arranque no se repite)
	if EventManager.is_event_active("TUTORIAL") and not NarrativeFlags.has_flag(FLAG_INTRO_SHOWN) \
			and not NarrativeFlags.has_flag("tutorial_door_done"):
		NarrativeFlags.set_flag(FLAG_INTRO_SHOWN)
		for effect : Effect in START_EFFECTS:
			if not PlayerManager.has_effect(effect.effect_unique_name):
				PlayerManager.add_effect(effect.duplicate())
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "Tengo que ducharme.")

## integration_action.gd avisa al jugador llamando a este metodo en la escena actual.
func _set_action(text: String) -> void:
	Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], text)
