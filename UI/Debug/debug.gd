extends Window
class_name DebugPanel
@export var world : World

@onready var line_edit: LineEdit = %LineEdit
@onready var add_time: Button = %"Add Time"
@onready var remove_time: Button = %"Remove Time"
@onready var set_time: Button = %"Set Time"
@onready var game_info: RichTextLabel = %GameInfo
@onready var current_entity_label: RichTextLabel = %EntityLabel
@onready var entity_info: MarginContainer = %EntityInfo
@onready var entity_info_label: RichTextLabel = %EntityInfoLabel
@onready var stat_list: VBoxContainer = %StatList
@onready var event_manager : MarginContainer = %EventManager
@onready var current_time: RichTextLabel = %CurrentTime
@onready var current_day: RichTextLabel = %CurrentDay
@onready var current_month: RichTextLabel = %CurrentMonth
@onready var current_week: RichTextLabel = %CurrentWeek
@onready var current_week_day: RichTextLabel = %CurrentWeekDay
@onready var item_list: VBoxContainer = %ItemList
@onready var active_entities: VBoxContainer = %ActiveEntities
@onready var sanity_value : Label = %sanityValue
@onready var sanity_spin_box : SpinBox = %sanitySpinBox
@onready var sanity_name : Label = %sanityName

var entity_widgets : Dictionary = {}
var stat_widgets : Array[StatContainerDebug]

var item_widgets : Dictionary[Item, ItemContainerDebug]

const ENTITY_BUTTON = preload("uid://dyv1qmo2clngj") # UID MIEDO
const STAT_CONTAINER = preload("uid://bgpho3743di65") # UID MIEDO
const ITEM_CONTAINER = preload("uid://cuu2mriq75id7") # UID MIEDO

var current_entity : Entity:
	set(_v):
		_disconnect_current_entity()
		current_entity = _v
		if _v and _v._has_inventory():
			_connect_entity_inventory(_v)

var _connected_inventory: InventoryComponent = null

var frame_time_ms := 0.0
var playtime := 0.0

## Throttle para updates - no actualizar más de X veces por segundo
var _item_update_pending: bool = false
var _last_item_update_time: float = 0.0
const ITEM_UPDATE_THROTTLE: float = 0.1  # 100ms mínimo entre updates

## Throttle para game_info - no actualizar cada frame
var _game_info_timer: float = 0.0
const GAME_INFO_UPDATE_INTERVAL: float = 0.1  # 100ms

func _ready() -> void:
	close_requested.connect(hide)
	if !world: entity_info.hide()
	else: 
		world_initial_setup()
	setup_stats()
	PlayerManager.stat_connection_added.connect(update_stats)
	EventManager.event_create.connect(_on_event_active)
	EventManager.event_deactivaded.connect(_on_event_deactive)
	TimeManager.time_changed.connect(time_debug)
	PlayerManager.effect_added.connect(_on_effect_active)
	PlayerManager.effect_removed.connect(_on_effect_remove)
	PlayerManager.sanity_changed.connect(_sanity_changed)

func _disconnect_current_entity():
	if _connected_inventory and is_instance_valid(_connected_inventory):
		if _connected_inventory.item_added.is_connected(on_item_added):
			_connected_inventory.item_added.disconnect(on_item_added)
		if _connected_inventory.item_removed.is_connected(on_item_removed):
			_connected_inventory.item_removed.disconnect(on_item_removed)
		if _connected_inventory.inventory_changed.is_connected(_on_inventory_changed):
			_connected_inventory.inventory_changed.disconnect(_on_inventory_changed)
	_connected_inventory = null
	
	# Limpiar widgets de items
	for widget in item_widgets.values():
		if is_instance_valid(widget):
			widget.queue_free()
	item_widgets.clear()

func _connect_entity_inventory(entity: Entity) -> void:
	var inv = entity.inventory_container().inventory
	_connected_inventory = inv
	
	inv.item_added.connect(on_item_added)
	inv.item_removed.connect(on_item_removed)
	inv.inventory_changed.connect(_on_inventory_changed)
	
	# Setup inicial de items
	for x in entity.inventory.get_all_items():
		on_item_added(x)

func on_item_added(item: Item) -> void:
	if item_widgets.has(item):
		return
	var widget : ItemContainerDebug = ITEM_CONTAINER.instantiate()
	widget.item = item
	item_widgets[item] = widget
	item_list.add_child(widget)
	widget.update()

func _sanity_changed(_value, _old_val) -> void :
	sanity_value.text = str(_value)
	match PlayerManager.get_sanity_state() :
		PlayerManager.SANITY_STATES.DOCILE :
			sanity_name.text = "Docile"
		PlayerManager.SANITY_STATES.NEUTRAL :
			sanity_name.text = "Neutral"
		PlayerManager.SANITY_STATES.DISTURBED :
			sanity_name.text = "Disturbed"

func on_item_removed(item: Item) -> void:
	if not item_widgets.has(item):
		return
	var widget = item_widgets[item]
	item_widgets.erase(item)
	if is_instance_valid(widget):
		widget.queue_free()

func _on_inventory_changed() -> void:
	# Marcar para update
	_item_update_pending = true
	
		# Sincronizar orden visual con el inventario
	if _connected_inventory:
		# Mapear item -> slot_index
		var item_slots = {}
		var ordered_items = []
		
		for i in range(_connected_inventory.slots.size()):
			var slot = _connected_inventory.slots[i]
			if not slot.is_empty():
				item_slots[slot.item] = i
				ordered_items.append(slot.item)
		
		# Eliminar widgets de items que ya no están
		var items_to_remove = []
		for item in item_widgets.keys():
			if not item_slots.has(item):
				items_to_remove.append(item)
		
		for item in items_to_remove:
			on_item_removed(item)
			
		# Añadir o mover widgets y actualizar slot info
		for i in range(ordered_items.size()):
			var item = ordered_items[i]
			if not item_widgets.has(item):
				on_item_added(item)
			
			var widget = item_widgets[item]
			
			# Mover visualmente
			if widget.get_parent() == item_list:
				item_list.move_child(widget, i)
			
			# Actualizar slot index en el widget
			if widget.has_method("set_slot_index"):
				widget.set_slot_index(item_slots[item])

func _process_item_updates():
	if not _item_update_pending:
		return
	
	var current_time_ms = Time.get_ticks_msec() / 1000.0
	if current_time_ms - _last_item_update_time < ITEM_UPDATE_THROTTLE:
		return  # Esperar más tiempo
	
	_item_update_pending = false
	_last_item_update_time = current_time_ms
	
	# Solo actualizar widgets visibles
	if not visible:
		return
	
	for widget in item_widgets.values():
		if is_instance_valid(widget):
			widget.update()

func _on_effect_active(effect : Effect) -> void :
	var _label := Label.new()
	_label.text = effect.effect_display_name + str( " ", effect.effect_unique_name)
	_label.name = effect.effect_unique_name
	%EffectsList.add_child(_label)

func _on_effect_remove(effect : Effect) -> void :
	var node = %EffectsList.get_node_or_null(effect.effect_unique_name)
	if node : node.queue_free()

func _on_event_active(event_unique_name : String) -> void:
	var _label := Label.new()
	_label.text = event_unique_name
	_label.name = event_unique_name
	%eventmanagervbox.add_child(_label)

func _on_event_deactive(event_unique_name : String) -> void:
	var node = %eventmanagervbox.get_node_or_null(event_unique_name)
	if node : node.queue_free()

func world_initial_setup():
	world.entity_created.connect(_on_entity_added)
	world.entity_removed.connect(_on_entity_removed)

func _on_entity_added(entity: Entity) -> void:
	if entity_widgets.has(entity):
		return
	var widget = ENTITY_BUTTON.instantiate()
	active_entities.add_child(widget)
	widget.setup(self,entity)
	entity_widgets[entity] = widget

func setup_stats() -> void:
	for stat in PlayerManager.stats:
		var widget = STAT_CONTAINER.instantiate()
		widget.stat = stat
		stat_list.add_child(widget)
		stat_widgets.append(widget)
		widget.info_update()

func update_stats() -> void:
	for x in stat_widgets:
		x.info_update()

func _on_entity_removed(entity: Entity) -> void:
	if not entity_widgets.has(entity):
		return
	if entity == current_entity: current_entity = null
	var widget = entity_widgets[entity]
	entity_widgets.erase(entity)

	if is_instance_valid(widget):
		widget.queue_free()

func _process(_delta: float) -> void:
	if not get_tree().paused:
		playtime += _delta
	
	# Solo actualizar UI si el panel está visible
	if not visible:
		return
	
	# Procesar updates pendientes de items (throttled)
	_process_item_updates()
	
	# Throttle game_info updates
	_game_info_timer += _delta
	if _game_info_timer >= GAME_INFO_UPDATE_INTERVAL:
		_game_info_timer = 0.0
		game_info_update(_delta)
		entity_info_update(_delta)

func time_debug(_m,_w,_d,_r,_wi) -> void:
	if not visible:
		return
	current_time.text = "Current Timer: %s" % TimeManager.get_current_time()
	current_day.text = "Current Day: %s" % TimeManager.day
	current_week.text = "Current Week: %s" % TimeManager.week
	current_week_day.text = "Current Week Day: %s" % TimeManager.get_week_day_name()
	current_month.text = "Current Month: %s" % TimeManager.get_month_name()

func entity_info_update(_delta : float)-> void:
	if current_entity == null: current_entity_label.text = "Select an Entity"; return
	current_entity_label.text = "CURRENT ENTITY: "+current_entity.name
	if entity_widgets.has(current_entity):
		entity_info_label.text = \
		"""
		[font_size=12]
		Name: {name}
		Components: {components}
		State: {state}
		Facing: {facing}
		Can move: {can_move}
		Is moving: {is_moving}
		[/font_size]
		""".format({
			"name": current_entity.name,
			"components": current_entity.get_all_components(),
			"state": current_entity.get_curr_state_name(),
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
	if TimeUtils.is_valid_format(line_edit.text):
		TimeManager.add_to_current_time(line_edit.text)

func _on_remove_time_pressed() -> void:
	if TimeUtils.is_valid_format(line_edit.text):
		TimeManager.substract_to_current_time(line_edit.text)

func _on_set_time_pressed() -> void:
	if TimeUtils.is_valid_format(line_edit.text):
		TimeManager.set_current_time(line_edit.text)

func _on_sanity_increase_pressed() -> void:
	PlayerManager.sanity_value += sanity_spin_box.value

func _on_sanity_decrease_pressed() -> void:
	PlayerManager.sanity_value -= sanity_spin_box.value
