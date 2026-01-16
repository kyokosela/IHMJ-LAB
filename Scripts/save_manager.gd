class_name SaveManager

#region SIGNALS

signal save_completed(slot: String)
signal save_failed(slot: String, error: String)
signal load_completed(slot: String)
signal load_failed(slot: String, error: String)

static var _instance: SaveManager

static func _get_instance() -> SaveManager:
	if _instance == null:
		_instance = SaveManager.new()
	return _instance

#endregion

#region INTERNAL

const SAVE_DIR: String = "user://saves/"

static var _components: Dictionary = {}  # instance_id -> SaveComponent
static var _save_data: SaveData = SaveData.new()
static var _is_loading: bool = false


static func _static_init() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

#endregion

#region API

## Registra el componente, guardando los datos al runtime si existen
static func register(comp: SaveComponent) -> void:
	var id := comp.get_instance_id()
	var was_registered := _components.has(id)
	_components[id] = comp
	
	if not was_registered and _save_data.entries.has(comp.uid):
		comp.apply_data(_save_data.entries[comp.uid] as ComponentData)


## Desregistra el componente al salir de la escena (para evitar errores)
# Deferred automático al detectar que es reparenting
static func unregister(comp: SaveComponent) -> void:
	var id := comp.get_instance_id()
	var uid := comp.uid  # Capture before defer
	
	if _is_loading:
		_components.erase(id)
		return
	
	if is_instance_valid(comp) and not uid.is_empty():
		Engine.get_main_loop().process_frame.connect(
			func(): _deferred_unregister(id, uid, comp), CONNECT_ONE_SHOT
		)
	else:
		_components.erase(id)



static func save_to_disk(slot: String = "auto") -> void:
	_is_loading = false
	
	# Busca los datos de todos los componentes registrados
	for comp: SaveComponent in _components.values():
		if is_instance_valid(comp):
			# TODO: fix error donde al guardar al completar un email
			# sale:
			"""
			E 0:00:18:689   save_to_disk: Trying to assign invalid previously freed instance.
		  <GDScript Source>save_manager.gd:70 @ save_to_disk()
		  <Stack Trace> save_manager.gd:70 @ save_to_disk()
		                game_manager.gd:45 @ save_file()
		                game_manager.gd:96 @ _unhandled_input()

			"""
			_save_data.entries[comp.uid] = comp.get_data()
	
	var path := _get_slot_path(slot)
	var err := ResourceSaver.save(_save_data, path)
	if err != OK:
		var msg := error_string(err)
		push_error("Save error: %s" % msg)
		_get_instance().save_failed.emit(slot, msg)
		return
	
	_get_instance().save_completed.emit(slot)


static func load_from_disk(slot: String = "auto") -> void:
	var path := _get_slot_path(slot)
	if not ResourceLoader.exists(path):
		_get_instance().load_failed.emit(slot, "Save file not found")
		return
	
	var loaded := load(path)
	if not loaded is SaveData:
		push_error("Corrupt save file: %s" % path)
		_get_instance().load_failed.emit(slot, "Corrupt save file")
		return
	
	_is_loading = true
	_save_data = loaded
	
	for comp: SaveComponent in _components.values():
		if is_instance_valid(comp) and _save_data.entries.has(comp.uid):
			comp.apply_data(_save_data.entries[comp.uid] as ComponentData)
	
	_is_loading = false
	_get_instance().load_completed.emit(slot)

#endregion

#region UTIL

static func has_save(slot: String = "auto") -> bool:
	return ResourceLoader.exists(_get_slot_path(slot))


static func delete_save(slot: String) -> void:
	var path := _get_slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


## Lista de saves (útil para el UI)
static func list_saves() -> Array[String]:
	var saves: Array[String] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return saves
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with("save_") and file_name.ends_with(".res"):
			saves.append(file_name.trim_prefix("save_").trim_suffix(".res"))
		file_name = dir.get_next()
	return saves


static func clear() -> void:
	_save_data = SaveData.new()


## Retorna un valor específico del save
## Util para achievements, comparaciones, etc etc
## Returna default si no se encontró algo
static func get_value(uid: String, alias: String, default: Variant = null) -> Variant:
	var comp_data: ComponentData = _save_data.entries.get(uid)
	if comp_data == null:
		return default
	return comp_data.values.get(alias, default)


## TODO: no sé si vamos a usar esto csm
## Modifica un valor directamente del save
static func set_value(uid: String, alias: String, value: Variant) -> void:
	var comp_data: ComponentData = _save_data.entries.get(uid)
	if comp_data == null:
		comp_data = ComponentData.new()
		_save_data.entries[uid] = comp_data
	comp_data.values[alias] = value


static func has_entry(uid: String) -> bool:
	return _save_data.entries.has(uid)


static func has_value(uid: String, alias: String) -> bool:
	var comp_data: ComponentData = _save_data.entries.get(uid)
	if comp_data == null:
		return false
	return comp_data.values.has(alias)


static func get_data() -> Dictionary:
	return _save_data.entries.duplicate(true)


static func debug_print() -> void:
	var output := {}
	for uid in _save_data.entries:
		var comp_data: ComponentData = _save_data.entries[uid]
		output[uid] = comp_data.values if comp_data else {}
	print("[SaveManager] entries:\n", JSON.stringify(output, "\t"))


static func _get_slot_path(slot: String) -> String:
	return SAVE_DIR + "save_" + slot + ".res"


static func _deferred_unregister(id: int, uid: String, comp: SaveComponent) -> void:
	# si se ha re-registrado un componente, skip
	if _components.has(id) and is_instance_valid(_components[id]): return
	
	if is_instance_valid(comp):
		var new_data := comp.get_data()
		var existing: ComponentData = _save_data.entries.get(uid) as ComponentData
		if new_data.values.is_empty() and existing and not existing.values.is_empty():
			pass  # no sobreescribir datos vacíos
		else:
			_save_data.entries[uid] = new_data
	
	_components.erase(id)

#endregion
