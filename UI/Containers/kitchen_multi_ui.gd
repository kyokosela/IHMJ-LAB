extends ContainerUI
class_name KitchenMultiUI
## UI para la cocina multi-estación
## Muestra: estaciones + craft simple (3 slots) + storage + inventario del player

signal craft_requested(station_id: String)
signal overflow_resolution_needed(items: Array[Item])

@export_group("Station Grids")
@export var station_containers: Dictionary[String,GridContainer] = {}  ## {"stove": Container, "sink": Container, ...}
@export var station_labels: Dictionary[String,Label] = {}  ## {"stove": Label, ...}
@export var station_progress_bars: Dictionary[String,ProgressBar] = {}  ## {"stove": ProgressBar, ...}
@export var station_craft_buttons: Dictionary[String,Button] = {}  ## {"stove": Button, "sink": Button, ...}

@export_group("Simple Craft")
@export var simple_craft_input_grid: Container
@export var simple_craft_result_grid: Container
@export var craft_button: Button
@export var craft_preview_label: Label

@export_group("Storage")
@export var storage_grid: Container

@export_group("Player Inventory")
@export var player_hands_grid: Container
@export var player_bag_grid: Container

@export_group("Overflow Dialog")
@export var overflow_dialog: Control
@export var overflow_items_grid: Container
@export var overflow_target_grid: Container

var kitchen: KitchenContainer
var player_inventory: PlayerInventoryContainer

func _ready():
	if craft_button:
		craft_button.pressed.connect(_on_craft_button_pressed)
	
	if overflow_dialog:
		overflow_dialog.visible = false
	

	for station_id in station_craft_buttons.keys():
		var btn = station_craft_buttons[station_id] as Button
		if btn:
			btn.pressed.connect(_on_station_craft_button_pressed.bind(station_id))

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
	
		var overflow = kitchen.return_simple_craft_items(player_inventory)
		if not overflow.is_empty():
			_show_overflow_dialog(overflow)
			return 
		
		_disconnect_kitchen_signals()
	
	if player_inventory:
		_disconnect_player_signals()
	
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
		print("Station: ", station.station_id, " Container: ", container, " Valid: ", is_instance_valid(container) if container else false)
		if not container or not is_instance_valid(container): continue
		
		print("  -> Clearing and adding slot to: ", container.name if container else "null")
		_clear_grid(container)
		
		var item = kitchen.get_station_item(station.station_id)
		var slot_ui = _create_slot_ui(item, kitchen.get_station_slot_index(station.station_id))
		container.add_child(slot_ui)
		
	
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
			
			craft_btn.disabled = not has_valid_recipe or station.is_locked
			craft_btn.visible = not station.is_locked

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
			craft_preview_label.text = "= " + recipe.result_item.item_name
		else:
			craft_preview_label.text = ""
	
	if craft_button:
		craft_button.disabled = recipe == null

func _update_storage_ui():
	if not storage_grid: return
	
	_clear_grid(storage_grid)
	
	for idx in kitchen.get_storage_indices():
		var slot = kitchen.inventory.slots[idx]
		var slot_ui = _create_slot_ui(slot.item if not slot.is_empty() else null, idx)
		storage_grid.add_child(slot_ui)

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
	
	if slot_ui is InventorySlotUI:
		slot_ui.slot_index = slot_index
		slot_ui.parent_inventory = kitchen.inventory
	
	if slot_ui.has_method("set_item"):
		slot_ui.set_item(item)
	
	# Marcar como bloqueado si está en una estación bloqueada
	var slot_type = kitchen.get_slot_type(slot_index)
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
	
	if slot_ui.has_method("set_item"):
		slot_ui.set_item(item)
	
	return slot_ui

func _create_basic_slot(item: Item, _slot_index: int) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(64, 64)
	
	if item:
		var texture_rect = TextureRect.new()
		texture_rect.texture = item.data.texture
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(texture_rect)
	
	return panel

func _clear_grid(grid: Container):
	if not grid or not is_instance_valid(grid): return
	for child in grid.get_children():
		child.queue_free()
#endregion

#region Event Handlers
func _on_station_craft_started(station_id: String, _recipe: Crafts):
	print("KitchenUI: Craft started at ", station_id)
	_update_stations_ui()

func _on_station_craft_completed(station_id: String, result: Item):
	print("KitchenUI: Craft completed at ", station_id, " - ", result.data.item_name)
	_update_kitchen_ui()

func _on_station_craft_failed(station_id: String, reason: String):
	print("KitchenUI: Craft failed at ", station_id, " - ", reason)
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
	var result = kitchen.execute_simple_craft()
	if result:
		# Intentar dar al player
		if player_inventory.has_any_space():
			player_inventory.add_item(result)
		else:
			_show_overflow_dialog([result])

func _on_station_craft_button_pressed(station_id: String):
	if not kitchen: return
	
	# Iniciar el craft de la estación manualmente
	var success = kitchen.start_manual_station_craft(station_id)
	if success:
		_update_stations_ui()
	else:
		print("KitchenUI: Could not start craft at ", station_id)
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
	btn.icon = item.data.texture
	btn.pressed.connect(_on_delete_item.bind(container, index))
	return btn

func _on_delete_item(container: InventoryContainer, index: int):
	container.inventory.remove_item_at(index)
	overflow_dialog.visible = false
	_update_all_ui()
	
	# Intentar cerrar UI si ya no hay overflow pendiente
	# (el player debería intentar cerrar de nuevo)
#endregion
