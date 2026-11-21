extends World

const FLAG_SHOWERED   := "morning_showered"
const FLAG_DRESSED    := "morning_dressed"
const FLAG_ATE        := "morning_ate"
const FLAG_DOOR_DONE  := "tutorial_door_done"
const FLAG_INTRO_SHOWN := "tutorial_intro_shown"

@onready var main_door : Area2D = %MainDoor

func _ready() -> void:
	super()
	# new_game() reinicia todo: solo debe correr la primera vez, no cada vez que se recarga el apartamento
	if not GameManager.game_started:
		GameManager.new_game()

	main_door.body_entered.connect(_on_door_entered)

	if NarrativeFlags.has_flag(FLAG_DOOR_DONE):
		return
	if not EventManager.is_event_active("TUTORIAL"):
		return

	_connect_routine_interactables()

	if not NarrativeFlags.has_flag(FLAG_INTRO_SHOWN):
		NarrativeFlags.set_flag(FLAG_INTRO_SHOWN)
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "Tengo que ducharme.")

## integration_action.gd avisa al jugador llamando a este metodo en la escena actual.
func _set_action(text: String) -> void:
	Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], text)

func _connect_routine_interactables() -> void:
	for node in get_tree().get_nodes_in_group("Interactable"):
		match node.interaction_name:
			"APT_SHOWER":
				node.executed.connect(func(): NarrativeFlags.set_flag(FLAG_SHOWERED))
			"APT_WARDROBE":
				node.executed.connect(func(): NarrativeFlags.set_flag(FLAG_DRESSED))
			"APT_FRIDGE":
				node.executed.connect(func(): NarrativeFlags.set_flag(FLAG_ATE))

func _on_door_entered(body) -> void:
	if not body is Player:
		return

	if NarrativeFlags.has_flag(FLAG_DOOR_DONE):
		_do_leave()
		return

	var missing : Array[String] = []
	if not NarrativeFlags.has_flag(FLAG_SHOWERED):
		missing.append("ducharte")
	if not NarrativeFlags.has_flag(FLAG_DRESSED):
		missing.append("cambiarte")

	if not missing.is_empty():
		Dialogic.create_quick_dialog(
			Dialogic.characters_path["Mayui"],
			"Espera, necesito %s." % ", ".join(missing)
		)
		return

	NarrativeFlags.set_flag(FLAG_DOOR_DONE)
	Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], "Aquí vamos.")
	Dialogic.timeline_ended.connect(_do_leave, CONNECT_ONE_SHOT)

func _do_leave() -> void:
	ZoneManager.change_zone(ZoneManager.ZONES.LOBBY)
