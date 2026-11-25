@tool
extends InteractableAction
## Puerta del apartamento en el tutorial de la manana. Usa la lista de tareas del dev (task_lists = TUTORIAL_DOOR): mientras falte
## un paso, InteractableAction hace que Mayui diga las frases de tu guion para ese paso (ducha, uniforme, comida, dientes;
## Textfiles/Interact/Interacts.csv). Con la rutina completa, la primera vez dice "Aqui vamos." y sale; despues sale directo.

@export var destination : ZoneManager.ZONES = ZoneManager.ZONES.LOBBY

const TUTORIAL_LIST : String = "TUTORIAL_DOOR"
const ROUTINE_DONE_FLAG : String = "tutorial_door_done"
const LEAVING_LINE : String = "_DOOR_LEAVE_"

## La manana del tutorial dura hasta que Mayui sale con la rutina completa.
static func in_tutorial_morning() -> bool:
	return TaskManager.is_task_list_active(TUTORIAL_LIST) and not NarrativeFlags.has_flag(ROUTINE_DONE_FLAG)

func execute() -> void:
	_sync_uniform_task()
	super()

func custom_execute() -> void:
	super()
	if Engine.is_editor_hint(): return
	if TaskManager.is_task_list_active(TUTORIAL_LIST) and not NarrativeFlags.has_flag(ROUTINE_DONE_FLAG):
		NarrativeFlags.set_flag(ROUTINE_DONE_FLAG)
		can_interact = false
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], tr(LEAVING_LINE))
		Dialogic.timeline_ended.connect(_leave, CONNECT_ONE_SHOT)
		return
	_leave()

## Para completar la rutina hay que salir con el uniforme PUESTO: si se lo quito (ducha, otra ropa), esa tarea queda pendiente
## otra vez. Despues de la primera salida ya no se exige.
func _sync_uniform_task() -> void:
	if NarrativeFlags.has_flag(ROUTINE_DONE_FLAG): return
	var tasks : TaskList = TaskManager.get_task_list_res(TUTORIAL_LIST)
	if tasks == null: return
	var clothes : Task = tasks.get_task_res("CLOTHES")
	if clothes != null:
		clothes.task_done = PlayerManager.get_outfit_id() == "work"

func _leave() -> void:
	ZoneManager.change_zone(destination)
