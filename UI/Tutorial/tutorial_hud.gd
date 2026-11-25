extends CanvasLayer
## Ayudas de la manana del tutorial (tu Bloque 1-1 y Flow de juego): la lista de tareas arriba a la derecha, como moverse y
## usar las cosas abajo, y como usar el raton en el armario, la cocina y el espejo. Solo en casa y hasta salir por primera vez.

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")
const MOUSE_UI_GROUP := "tutorial_mouse_ui"
const LEAVE_TASK := "_TASK_LEAVE_"
const PENDING_COLOR := Color(1, 1, 1)
const NEXT_COLOR := Color(1, 0.85, 0.35)
const DONE_COLOR := Color(0.55, 0.8, 0.55)

@onready var tasks_panel : Control = %Tasks
@onready var task_rows : VBoxContainer = %TaskRows
@onready var walk_panel : Control = %WalkHint
@onready var walk_label : Label = %WalkLabel
@onready var mouse_panel : Control = %MouseHint
@onready var mouse_label : Label = $MouseHint/MouseLabel

var _shown_tasks : String = "" ## para no redibujar la lista si no cambio

func _process(_delta: float) -> void:
	var morning : bool = _morning_at_home()
	var mouse_ui : CanvasItem = _mouse_ui_open()
	mouse_panel.visible = morning and Dialogic.current_timeline == null and mouse_ui != null
	if mouse_panel.visible:   # cada pantalla puede traer su ayuda (metadato "tutorial_hint"; la cocina explica como comer)
		mouse_label.text = tr(mouse_ui.get_meta("tutorial_hint", "_HINT_MOUSE_"))
	tasks_panel.visible = morning and GameManager.modal_count == 0
	if tasks_panel.visible:
		_refresh_tasks()
	var lines : PackedStringArray = []
	if morning and not GameManager.is_input_blocked():
		if not _task_done("BATHE"):
			lines.append(tr("_HINT_MOVE_"))
		if _something_in_front():
			lines.append(tr("_HINT_USE_"))
	walk_panel.visible = not lines.is_empty()
	walk_label.text = "\n".join(lines)

func _morning_at_home() -> bool:
	var zone : World = ZoneManager.zone_node if is_instance_valid(ZoneManager.zone_node) else null
	return zone != null and ZoneManager.is_home(zone.zone_id) and ExitDoor.in_tutorial_morning()

func _task_done(task_name: String) -> bool:
	var task : Task = TaskManager.get_task_list_res(ExitDoor.TUTORIAL_LIST).get_task_res(task_name)
	return task != null and task.task_done

func _something_in_front() -> bool:
	for node in get_tree().get_nodes_in_group("Interactable"):
		var thing := node as Interactable
		if thing != null and thing.is_inside and thing.can_interact and not thing.collision_trigger:
			return true
	return false

## La pantalla de raton que esta abierta, o null.
func _mouse_ui_open() -> CanvasItem:
	for node in get_tree().get_nodes_in_group(MOUSE_UI_GROUP):
		if node is CanvasItem and node.is_visible_in_tree():
			return node
	return null

## Una fila por tarea de la lista del dev (en su orden) y al final salir. La primera que falta va resaltada.
func _refresh_tasks() -> void:
	var entries : Array = []
	for task : Task in TaskManager.get_task_list_res(ExitDoor.TUTORIAL_LIST).task_list:
		entries.append([task.display_name if not task.display_name.is_empty() else task.task_unique_name, task.task_done])
	entries.append([LEAVE_TASK, false])
	var signature := str(entries)
	if signature == _shown_tasks:
		return
	_shown_tasks = signature
	while task_rows.get_child_count() < entries.size():
		var row := Label.new()
		row.add_theme_font_size_override("font_size", 22)
		task_rows.add_child(row)
	var next_found := false
	for i in task_rows.get_child_count():
		var row : Label = task_rows.get_child(i)
		row.visible = i < entries.size()
		if not row.visible:
			continue
		var done : bool = entries[i][1]
		var is_next : bool = not done and not next_found
		next_found = next_found or is_next
		row.text = "[%s] %s" % ["x" if done else "  ", tr(entries[i][0])]
		row.add_theme_color_override("font_color", DONE_COLOR if done else (NEXT_COLOR if is_next else PENDING_COLOR))
