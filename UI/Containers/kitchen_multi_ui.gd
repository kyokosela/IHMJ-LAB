extends ContainerUI
class_name KitchenMultiUI
## UI para la cocina multi-estación
## Muestra: estaciones + craft simple (3 slots) + storage + inventario del player

signal craft_requested(station_id: String)
signal overflow_resolution_needed(items: Array[Item])

@export_group("Station Grids")
@export var station_containers: Dictionary[String,GridContainer] = {}
@export var station_labels: Dictionary[String,Label] = {}
@export var station_progress_bars: Dictionary[String,ProgressBar] = {}
@export var station_craft_buttons: Dictionary[String,Button] = {}
## Completado: boton "Esperar" (visible mientras la estacion trabaja) y el aviso de cuanto tiempo pasara.
@export var station_wait_buttons: Dictionary[String,Button] = {}
@export var wait_dialog: ConfirmationDialog
## Completado: tus frases de "[Estufa] sin comida" (DIALOGOS): con la estufa vacia "Cocinar" sigue activo y Mayui las dice.
@export var stove_empty_lines: StringChain
const STOVE_ID : String = "stove"
## Completado (arte ilustrado de la cocina, Assets/UI/Kitchen): props que cambian segun el estado de la estacion.
@export var station_item_props: Dictionary[String,CanvasItem] = {}    ## visibles mientras la estacion tiene un objeto (la olla)
@export var station_active_props: Dictionary[String,CanvasItem] = {}  ## visibles mientras la estacion trabaja (fuego y humo, agua)

@export_group("Simple Craft")
@export var simple_craft_input_grid: Container
@export var simple_craft_result_grid: Container
@export var craft_button: Button
@export var craft_preview_label: Label

@export_group("Storage")
@export var storage_grid: Container
## Completado: la cocina tiene dos alacenas. Las primeras storage_first_count casillas del almacenamiento van a storage_grid y el
## resto a storage_grid_2 (si no hay segunda, todas van a la primera).
@export var storage_grid_2: Container
@export var storage_first_count: int = 6
@export var storage_slot_size: Vector2 = Vector2(96, 96)

## Completado (tu guion DIALOGOS, comida instantanea), en la manana del tutorial y una vez cada uno.
@export_group("Frases de la comida instantanea")
@export var instant_found_dialog: DialogicTimeline   ## al sacarla de la alacena
@export var instant_ready_dialog: DialogicTimeline   ## cuando queda lista (al combinarla con agua caliente)
const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")
const INSTANT_BOX : String = "instant_box"
const INSTANT_MEAL : String = "instant_meal"

## Completado: lo que dice Mayui al soltar algo donde no va (tus frases de la estufa; PROVISIONAL para las demas).
const REJECT_LINE : String = "_STOVE_EMPTY_#1_"   ## "No tiene sentido."
const REJECT_LINES : Dictionary = {"CONTAINER_EMPTY": "_STOVE_EMPTY_#2_"}   ## "Necesito algo para cocinar."

@export_group("Player Inventory")
@export var player_hands_grid: Container
@export var player_bag_grid: Container

@export_group("Overflow Dialog")
@export var overflow_dialog: Control
@export var overflow_items_grid: Container
@export var overflow_target_grid: Container

var kitchen: KitchenContainer
var player_inventory: PlayerInventoryContainer
var _waiting_station: String = ""  ## estacion por la que se esta preguntando en wait_dialog

func _ready():
	if craft_button:
		craft_button.pressed.connect(_on_craft_button_pressed)
	
	if overflow_dialog:
		overflow_dialog.visible = false
	

	for station_id in station_craft_buttons.keys():
		var btn = station_craft_buttons[station_id] as Button
		if btn:
			btn.pressed.connect(_on_station_craft_button_pressed.bind(station_id))
	for station_id in station_wait_buttons.keys():
		var wait_btn = station_wait_buttons[station_id] as Button
		if wait_btn:
			wait_btn.pressed.connect(_on_station_wait_pressed.bind(station_id))
	if wait_dialog:
		wait_dialog.confirmed.connect(_on_wait_confirmed)

func open(p_container: InteractableContainer):
	super.open(p_container)
	
	if current_container is KitchenContainer:
		kitchen = current_container as KitchenContainer
		_connect_kitchen_signals()
	
	if PlayerManager.player and PlayerManager.player.inventory:
		player_inventory = PlayerManager.player.inventory as PlayerInventoryContainer
		_connect_player_signals()
	
	_update_all_ui()
	visible = true

func close():
	if kitchen:
		# Completado: lo que se deja en "Combinar" se queda ahi, igual que en las estaciones (antes saltaba solo a las manos al
		# cerrar). La cocina guarda todas sus casillas.
		_disconnect_kitchen_signals()
	
	if player_inventory:
		_disconnect_player_signals()

	_waiting_station = ""
	if wait_dialog:
		wait_dialog.hide()
	kitchen = null
	player_inventory = null
	super.close()

#region Signal Connections
func _connect_kitchen_signals():
	if not kitchen: return
	
	kitchen.inventory.inventory_changed.connect(_update_kitchen_ui)
	kitchen.station_craft_started.connect(_on_station_craft_started)
	kitchen.station_craft_completed.connect(_on_station_craft_completed)
	kitchen.station_craft_failed.connect(_on_station_craft_failed)
	kitchen.simple_craft_available.connect(_on_simple_craft_available)
	kitchen.simple_craft_executed.connect(_on_simple_craft_executed)
	kitchen.overflow_detected.connect(_show_overflow_dialog)

func _disconnect_kitchen_signals():
	if not kitchen: return
	
	if kitchen.inventory.inventory_changed.is_connected(_update_kitchen_ui):
		kitchen.inventory.inventory_changed.disconnect(_update_kitchen_ui)
	if kitchen.station_craft_started.is_connected(_on_station_craft_started):
		kitchen.station_craft_started.disconnect(_on_station_craft_started)
	if kitchen.station_craft_completed.is_connected(_on_station_craft_completed):
		kitchen.station_craft_completed.disconnect(_on_station_craft_completed)
	if kitchen.station_craft_failed.is_connected(_on_station_craft_failed):
		kitchen.station_craft_failed.disconnect(_on_station_craft_failed)
	if kitchen.simple_craft_available.is_connected(_on_simple_craft_available):
		kitchen.simple_craft_available.disconnect(_on_simple_craft_available)
	if kitchen.simple_craft_executed.is_connected(_on_simple_craft_executed):
		kitchen.simple_craft_executed.disconnect(_on_simple_craft_executed)
	if kitchen.overflow_detected.is_connected(_show_overflow_dialog):
		kitchen.overflow_detected.disconnect(_show_overflow_dialog)

func _connect_player_signals():
	if not player_inventory: return
	
	player_inventory.inventory.inventory_changed.connect(_update_player_ui)

func _disconnect_player_signals():
	if not player_inventory: return
	
	if player_inventory.inventory.inventory_changed.is_connected(_update_player_ui):
		player_inventory.inventory.inventory_changed.disconnect(_update_player_ui)
#endregion

#region UI Updates
func _update_all_ui():
	_update_kitchen_ui()
	_update_player_ui()

func _update_kitchen_ui():
	if not kitchen: return
	
	_update_stations_ui()
	_update_simple_craft_ui()
	_update_storage_ui()

func _update_stations_ui():
	for station in kitchen.stations:
		var container = station_containers.get(station.station_id)
		if not container or not is_instance_valid(container): continue
		
		_clear_grid(container)
		
		var item = kitchen.get_station_item(station.station_id)
		var slot_ui = _create_slot_ui(item, kitchen.get_station_slot_index(station.station_id))
		# sin cuadro: la casilla ocupa el sitio del dibujo (el tamano de la rejilla en la escena)
		slot_ui.custom_minimum_size = Vector2(container.offset_right - container.offset_left, container.offset_bottom - container.offset_top)
		container.add_child(slot_ui)

		# Completado (arte ilustrado, Assets/UI/Kitchen): la olla aparece cuando la estacion tiene la olla
		# y el fuego, el humo o el agua se ven mientras la estacion trabaja.
		var item_prop = station_item_props.get(station.station_id)
		if item_prop and is_instance_valid(item_prop):
			item_prop.visible = item != null and item.data.has_util("cookware")
		var active_prop = station_active_props.get(station.station_id)
		if active_prop and is_instance_valid(active_prop):
			active_prop.visible = station.is_locked

	
		var label = station_labels.get(station.station_id)
		if label and is_instance_valid(label):
			label.text = station.station_name
			if station.is_locked:
				label.text += " (En proceso...)"
		
	
		var progress = station_progress_bars.get(station.station_id)
		if progress and is_instance_valid(progress):
			progress.visible = station.is_locked
			if station.is_locked:
				_update_station_progress(station, progress)
		
	
		var craft_btn = station_craft_buttons.get(station.station_id)
		if craft_btn and is_instance_valid(craft_btn):
		
			var has_valid_recipe = kitchen.has_valid_station_craft(station.station_id)
			
			craft_btn.disabled = station.is_locked or (not has_valid_recipe and not _stove_without_food(station.station_id))
			craft_btn.visible = not station.is_locked

		var wait_button = station_wait_buttons.get(station.station_id)
		if wait_button and is_instance_valid(wait_button):
			wait_button.visible = station.is_locked

func _update_simple_craft_ui():
	if not simple_craft_input_grid: return
	
	_clear_grid(simple_craft_input_grid)
	
	var input_indices = kitchen.get_simple_craft_input_indices()
	for idx in input_indices:
		var slot = kitchen.inventory.slots[idx]
		var slot_ui = _create_slot_ui(slot.item if not slot.is_empty() else null, idx)
		simple_craft_input_grid.add_child(slot_ui)
	

	if simple_craft_result_grid:
		_clear_grid(simple_craft_result_grid)
		
		var result_idx = kitchen.get_simple_craft_result_index()
		var result_slot = kitchen.inventory.slots[result_idx]
		var result_ui = _create_slot_ui(result_slot.item if not result_slot.is_empty() else null, result_idx)
		simple_craft_result_grid.add_child(result_ui)
	

	_update_craft_preview()

func _update_craft_preview():
	var recipe = kitchen.check_simple_craft()
	
	if craft_preview_label:
		if recipe:
			craft_preview_label.text = "= " + tr(recipe.result_item.item_name)
		else:
			craft_preview_label.text = ""
	
	if craft_button:
		craft_button.disabled = recipe == null or not kitchen.is_simple_craft_result_free()

func _update_storage_ui():
	if not storage_grid: return
	
	_clear_grid(storage_grid)
	_clear_grid(storage_grid_2)
	
	var n := 0
	for idx in kitchen.get_storage_indices():
		var slot = kitchen.inventory.slots[idx]
		var slot_ui = _create_slot_ui(slot.item if not slot.is_empty() else null, idx)
		# Completado: segunda alacena (ver storage_first_count)
		var grid = storage_grid_2 if (storage_grid_2 and n >= storage_first_count) else storage_grid
		grid.add_child(slot_ui)
		n += 1

func _update_player_ui():
	if not player_inventory: return
	

	if player_hands_grid:
		_clear_grid(player_hands_grid)
		
		for idx in player_inventory.get_hands_indices():
			var slot = player_inventory.inventory.slots[idx]
			var slot_ui = _create_player_slot_ui(slot.item if not slot.is_empty() else null, idx)
			player_hands_grid.add_child(slot_ui)
	

	if player_bag_grid:
		_clear_grid(player_bag_grid)
		
		if player_inventory.has_bag():
			for idx in player_inventory.get_bag_indices():
				var slot = player_inventory.inventory.slots[idx]
				var slot_ui = _create_player_slot_ui(slot.item if not slot.is_empty() else null, idx)
				player_bag_grid.add_child(slot_ui)

func _update_station_progress(station: Station, progress: ProgressBar):
	if station.active_craft_event.is_empty():
		progress.value = 0
		return
	
	var time_left = EventManager.get_time_left_to_end(station.active_craft_event)
	# TODO: Calcular porcentaje basado en tiempo restante vs tiempo total
	progress.value = 50  # Placeholder
#endregion

#region Slot Creation
func _create_slot_ui(item: Item, slot_index: int) -> Control:
	if not slot_scene:
		return _create_basic_slot(item, slot_index)
	
	var slot_ui = slot_scene.instantiate()
	var slot_type = kitchen.get_slot_type(slot_index)

	if slot_ui is InventorySlotUI:
		slot_ui.slot_index = slot_index
		slot_ui.parent_inventory = kitchen.inventory
		slot_ui.drop_filter = _allow_drop
		if slot_type == "station":
			var station = kitchen.get_station_for_slot(slot_index)
			slot_ui.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			slot_ui.hide_icon = station != null and station_item_props.has(station.station_id)
			slot_ui.dim_when_locked = false
		elif slot_type == "storage":
			slot_ui.custom_minimum_size = storage_slot_size

	if slot_ui.has_method("set_item"):
		slot_ui.set_item(item)

	if slot_type == "station":
		var station = kitchen.get_station_for_slot(slot_index)
		if station and station.is_locked and slot_ui.has_method("set_locked"):
			slot_ui.set_locked(true)

	return slot_ui

func _create_player_slot_ui(item: Item, slot_index: int) -> Control:
	if not slot_scene:
		return _create_basic_slot(item, slot_index)
	
	var slot_ui = slot_scene.instantiate()
	
	if slot_ui is InventorySlotUI:
		slot_ui.slot_index = slot_index
		slot_ui.parent_inventory = player_inventory.inventory
		slot_ui.drop_filter = _allow_drop

	if slot_ui.has_method("set_item"):
		slot_ui.set_item(item)
	
	return slot_ui

func _create_basic_slot(item: Item, _slot_index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(64, 64)
	
	if item:
		var texture_rect = TextureRect.new()
		texture_rect.texture = item.get_display_texture()
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(texture_rect)
	
	return panel

func _clear_grid(grid: Container):
	if not grid or not is_instance_valid(grid): return
	for child in grid.get_children():
		child.queue_free()
#endregion

#region Que acepta cada casilla
## Completado: cada estacion acepta solo lo suyo (las reglas de tu Station) y el resultado de Combinar solo sale. Si no se
## puede, no se mueve nada y Mayui lo dice.
func _allow_drop(slot_ui: InventorySlotUI, from: InventoryComponent, from_index: int) -> bool:
	var reason : String = _drop_rejection(slot_ui.parent_inventory, slot_ui.slot_index, from, from_index)
	if reason == "":
		_notice_instant_box(slot_ui, from, from_index)
		return true
	if reason != "STATION_BUSY" and Dialogic.current_timeline == null:
		Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], tr(REJECT_LINES.get(reason, REJECT_LINE)))
	return false

## Por que no se puede mover ("" si se puede): se mira lo que llega y, si se intercambian, lo que vuelve.
func _drop_rejection(to: InventoryComponent, to_index: int, from: InventoryComponent, from_index: int) -> String:
	if to == from and to_index == from_index: return ""
	var arriving : Item = from.slots[from_index].item
	var leaving : Item = to.slots[to_index].item
	var reason : String = _slot_rejection(to, to_index, arriving)
	if reason == "" and leaving != null:
		reason = _slot_rejection(from, from_index, leaving)
	return reason

## Sacar la comida instantanea de la alacena (a las manos o a otra casilla que no sea de almacenamiento).
func _notice_instant_box(slot_ui: InventorySlotUI, from: InventoryComponent, from_index: int) -> void:
	if kitchen == null or from != kitchen.inventory or kitchen.get_slot_type(from_index) != "storage": return
	var item : Item = from.slots[from_index].item
	if item == null or item.data.item_unique_name != INSTANT_BOX: return
	if slot_ui.parent_inventory == kitchen.inventory and kitchen.get_slot_type(slot_ui.slot_index) == "storage": return
	_say_once("instant_found_said", instant_found_dialog)

func _say_once(flag: String, timeline: DialogicTimeline) -> void:
	if timeline == null or not ExitDoor.in_tutorial_morning() or NarrativeFlags.has_flag(flag): return
	if Dialogic.current_timeline != null: return
	NarrativeFlags.set_flag(flag)
	Dialogic.start(timeline)

func _slot_rejection(inventory: InventoryComponent, index: int, item: Item) -> String:
	if kitchen == null or inventory != kitchen.inventory or item == null: return ""
	if index == kitchen.get_simple_craft_result_index(): return "OUTPUT_ONLY"
	var station : Station = kitchen.get_station_for_slot(index)
	return station.get_rejection_reason(item) if station != null else ""
#endregion

#region Event Handlers
func _on_station_craft_started(station_id: String, _recipe: Crafts):
	_update_stations_ui()

func _on_station_craft_completed(station_id: String, result: Item):
	_update_kitchen_ui()

func _on_station_craft_failed(station_id: String, reason: String):
	# TODO: Mostrar mensaje al player
	_update_kitchen_ui()

func _on_simple_craft_available(_recipe: Crafts):
	# No llamar _update_craft_preview() aquí - ya fue llamado desde quien detectó el craft
	# Esto evita recursión infinita
	pass

func _on_simple_craft_executed(result: Item):
	print("KitchenUI: Simple craft executed - ", result.data.item_name)
	_update_simple_craft_ui()

func _on_craft_button_pressed():
	# Completado: lo combinado se queda en la casilla de resultado (antes saltaba solo a las manos)
	if not kitchen or not kitchen.is_simple_craft_result_free(): return
	var result = kitchen.execute_simple_craft()
	if result:
		kitchen.set_simple_craft_result(result)
		if result.data.item_unique_name == INSTANT_MEAL:
			_say_once("instant_ready_said", instant_ready_dialog)

## Completado: estufa sin nada encima y con frases para eso.
func _stove_without_food(station_id: String) -> bool:
	return station_id == STOVE_ID and stove_empty_lines != null and kitchen.get_station_item(station_id) == null

func _on_station_craft_button_pressed(station_id: String):
	if not kitchen: return

	if _stove_without_food(station_id):
		if Dialogic.current_timeline == null:
			Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], stove_empty_lines.get_message())
		# sin esto el boton se queda con el foco y Enter o Espacio lo vuelven a pulsar en vez de pasar lo que dice Mayui
		(station_craft_buttons[station_id] as Button).release_focus()
		return

	# Iniciar el craft de la estación manualmente
	var success = kitchen.start_manual_station_craft(station_id)
	if success:
		_update_stations_ui()
	else:
		print("KitchenUI: Could not start craft at ", station_id)
#endregion

#region Esperar
## Completado: el reloj solo avanza con acciones; "Esperar" avisa cuanto tiempo pasara y, si se acepta, adelanta el reloj
## justo hasta que la estacion termine.
func _on_station_wait_pressed(station_id: String) -> void:
	if not kitchen or not wait_dialog: return
	var left : String = kitchen.get_station_time_left(station_id)
	if left == "": return
	_waiting_station = station_id
	var minutes : int = TimeUtils.get_minutes(left)
	var end_time : String = TimeManager.format_minutes((TimeManager.minutes + minutes) % TimeManager.DAY_MINUTES)
	wait_dialog.dialog_text = "Pasarán %s hasta que esté listo (serán las %s).\n¿Esperar?" % [_duration_text(minutes), end_time]
	wait_dialog.popup_centered()

func _on_wait_confirmed() -> void:
	var station_id : String = _waiting_station
	_waiting_station = ""
	wait_dialog.hide()
	if not kitchen or station_id == "": return
	var left : String = kitchen.get_station_time_left(station_id)
	if left != "":
		TimeManager.add_to_current_time(left)

func _duration_text(minutes: int) -> String:
	if minutes < 60: return "%d min" % minutes
	if minutes % 60 == 0: return "%d h" % (minutes / 60)
	return "%d h %d min" % [minutes / 60, minutes % 60]
#endregion

#region Overflow Dialog
func _show_overflow_dialog(items: Array[Item]):
	if not overflow_dialog: 
		push_error("KitchenUI: No overflow dialog configured!")
		return
	
	overflow_dialog.visible = true
	overflow_resolution_needed.emit(items)
	
	# Mostrar items sin espacio
	if overflow_items_grid:
		_clear_grid(overflow_items_grid)
		for item in items:
			var slot_ui = _create_basic_slot(item, -1)
			overflow_items_grid.add_child(slot_ui)
	
	# Mostrar items que se pueden eliminar
	if overflow_target_grid:
		_clear_grid(overflow_target_grid)
		
		# Items en manos del player
		for idx in player_inventory.get_hands_indices():
			var slot = player_inventory.inventory.slots[idx]
			if not slot.is_empty():
				var btn = _create_delete_button(slot.item, player_inventory, idx)
				overflow_target_grid.add_child(btn)
		
		# Items en storage
		for idx in kitchen.get_storage_indices():
			var slot = kitchen.inventory.slots[idx]
			if not slot.is_empty():
				var btn = _create_delete_button(slot.item, kitchen, idx)
				overflow_target_grid.add_child(btn)

func _create_delete_button(item: Item, container: InventoryContainer, index: int) -> Button:
	var btn = Button.new()
	btn.text = item.data.item_name
	btn.icon = item.get_display_texture()
	btn.add_theme_constant_override("icon_max_width", 48)
	btn.pressed.connect(_on_delete_item.bind(container, index))
	return btn

func _on_delete_item(container: InventoryContainer, index: int):
	container.inventory.remove_item_at(index)
	overflow_dialog.visible = false
	_update_all_ui()
	
	# Intentar cerrar UI si ya no hay overflow pendiente
	# (el player debería intentar cerrar de nuevo)
#endregion
