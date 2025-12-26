extends Window
class_name DebugPanel
@export var world : World

@onready var line_edit: LineEdit = %LineEdit
@onready var add_time: Button = %"Add Time"
@onready var remove_time: Button = %"Remove Time"
@onready var set_time: Button = %"Set Time"
@onready var current_time: RichTextLabel = %CurrentTime
@onready var current_day: RichTextLabel = %CurrentDay
@onready var game_info: RichTextLabel = %GameInfo
@onready var current_entity_label: RichTextLabel = %EntityLabel
@onready var entity_info: MarginContainer = %EntityInfo
@onready var active_entities: FoldableContainer = %ActiveEntities
@onready var entity_info_label: RichTextLabel = %EntityInfoLabel

var entity_widgets : Dictionary = {}

const ENTITY_BUTTON = preload("uid://dyv1qmo2clngj") # UID MIEDO

var current_entity : Entity
var frame_time_ms := 0.0
var playtime := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !world: entity_info.hide()
	else: 
		world.entity_created.connect(_on_entity_added)
		world.entity_removed.connect(_on_entity_removed)

func _on_entity_added(entity: Node) -> void:
	if entity_widgets.has(entity):
		return
	var widget = ENTITY_BUTTON.instantiate()
	active_entities.add_child(widget)
	widget.setup(self,entity)
	entity_widgets[entity] = widget
	
	
func _on_entity_removed(entity: Node) -> void:
	if not entity_widgets.has(entity):
		return
	if entity == current_entity: current_entity = null
	var widget = entity_widgets[entity]
	entity_widgets.erase(entity)

	widget.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	current_time.text = "Current Timer: %s" % TimeManager.get_current_time()
	current_day.text = "Current Day: %s" % TimeManager.day
	game_info_update(_delta)
	entity_info_update(_delta)
	if not get_tree().paused:
		playtime+= _delta

func entity_info_update(_delta : float)-> void:
	if current_entity == null: current_entity_label.text = "Select an Entity"; return
	current_entity_label.text = "CURRENT ENTITY: "+current_entity.name
	if entity_widgets.has(current_entity):
		entity_info_label.text = \
		"""
		[font_size=12]
		Name: {name}
		Components: {components}
		Inventory: {inventory}
		State: {state}
		Animation: {animation}
		Facing: {facing}
		Can move: {can_move}
		Is moving: {is_moving}
		[/font_size]
		""".format({
			"name": current_entity.name,
			"components": current_entity.get_all_components(),
			"inventory": current_entity.inventory.get_unique_items(),
			"state": current_entity.get_curr_state_name(),
			"animation": current_entity.current_animation(),
			"facing": Utils.get_vector_name(current_entity.facing_direction()),
			"can_move": current_entity.can_move(),
			"is_moving": current_entity.moving()
		})

func game_info_update(_delta : float)->void:
	frame_time_ms = _delta * 1000.0
	
	game_info.text = """
	[font_size=12]
	FPS: {fps}
	Playtime: {playtime}
	Frame Time: {frame}
	Process Delta: {pdelta}
	Physics Delta: {phdelta}
	Vsync: {vsync}
	Render Mode: {render}
	Frame Count: {frames}
	Time Scale: {scale}
	[/font_size]
	""".format({
		"fps": Engine.get_frames_per_second(),
		"playtime": "%.2f ms" % playtime,
		"frame": "%.2f ms" % frame_time_ms,
		"pdelta": get_process_delta_time(),
		"phdelta": get_physics_process_delta_time(),
		"vsync": Utils.get_vsync_name(),
		"render": ProjectSettings.get_setting("rendering/renderer/rendering_method"),
		"frames": Engine.get_frames_drawn(),
		"scale": Engine.time_scale
	})



func _on_add_time_pressed() -> void:
	if TimeManager.is_valid_time(line_edit.text):
		TimeManager.add_to_current_time(line_edit.text)


func _on_remove_time_pressed() -> void:
	if TimeManager.is_valid_time(line_edit.text):
		TimeManager.substract_to_current_time(line_edit.text)


func _on_set_time_pressed() -> void:
	if TimeManager.is_valid_time(line_edit.text):
		TimeManager.set_current_time(line_edit.text)
