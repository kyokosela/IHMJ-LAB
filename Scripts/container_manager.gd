extends Node

var container_states : Dictionary = {}
var item_database : Dictionary = {}

func _ready() -> void:
	_build_item_database()

func _build_item_database():
	var path = "res://Resources/Items/Data/"
	_scan_for_items(path)

func _scan_for_items(path: String):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					_scan_for_items(path + file_name + "/")
			else:
				if file_name.ends_with(".tres") or file_name.ends_with(".res"):
					var resource = load(path + file_name)
					if resource is ItemData:
						if resource.item_unique_name != "":
							item_database[resource.item_unique_name] = resource
			file_name = dir.get_next()
	else:
		printerr("An error occurred when trying to access the path: " + path)

func register_container(container : InventoryContainer):
	if container.container_id == "": return
	_registered[container.get_instance_id()] = [weakref(container), _generation]

	# Load state if exists
	if container_states.has(container.container_id):
		var state = container_states[container.container_id]
		
		# Restore Inventory
		if state.has("inventory") and container.inventory:
			container.inventory.from_dict(state["inventory"], item_database)
		
		# Apply Decay
		if state.has("timestamp_abs"):
			var last_time = state["timestamp_abs"]
			var current_time = _get_current_absolute_minutes()
			var diff = current_time - last_time
			
			if diff > 0:
				container.apply_decay(diff)
				print("Applied decay of %s minutes to container %s" % [diff, container.container_id])

func save_container(container : InventoryContainer):
	if container.container_id == "": return
	# Completado (guardado): un contenedor de antes de cargar una partida (su escena se cierra despues) no pisa lo cargado
	var registered : Array = _registered.get(container.get_instance_id(), [])
	if not registered.is_empty() and registered[1] != _generation: return

	var data = {}
	if container.inventory:
		data["inventory"] = container.inventory.to_dict()
	
	data["timestamp_abs"] = _get_current_absolute_minutes()

	# Completado: recursos con estado propio que deben seguir vivos mientras la escena no existe (las estaciones de la cocina
	# recuerdan si estan cocinando). Si nadie los sostiene, Godot los descarga al salir de la zona y al volver llegan nuevos:
	# la comida en marcha se perdia.
	if container.has_method("get_live_resources"):
		data["live_resources"] = container.get_live_resources()

	container_states[container.container_id] = data
	# print("Saved state for container: " + container.container_id)

#region Guardado (Completado; Docs/Design/GUARDADO.md)
var _registered : Dictionary = {}   ## id del nodo -> [weakref, generacion]: los contenedores en escena, para guardarlos
var _generation : int = 0           ## sube al cargar una partida

## Lo de cada contenedor, incluidos los que estan en pantalla ahora (normalmente se guardan al salir de su zona) y el estado
## de las estaciones de la cocina (si estan cocinando).
func get_save_data() -> Dictionary:
	for registered : Array in _registered.values():
		var container = registered[0].get_ref()
		if container != null and registered[1] == _generation and container.is_inside_tree():
			save_container(container)
	var saved := {}
	for id in container_states:
		var state : Dictionary = container_states[id]
		var stations : Array = []
		for res in state.get("live_resources", []):
			if res is Station and res.resource_path != "":
				stations.append({"path": res.resource_path, "locked": res.is_locked, "event": res.active_craft_event,
					"slots": Array(res.locked_slot_indices)})
		saved[id] = {"inventory": state.get("inventory", {}).duplicate(true), "timestamp_abs": state.get("timestamp_abs", 0),
			"stations": stations}
	return {"containers": saved}

func load_save_data(data: Dictionary) -> void:
	_generation += 1
	container_states.clear()
	var saved : Dictionary = data.get("containers", {})
	for id in saved:
		var state : Dictionary = {"inventory": saved[id].get("inventory", {}).duplicate(true),
			"timestamp_abs": saved[id].get("timestamp_abs", 0)}
		var live : Array = []
		for entry : Dictionary in saved[id].get("stations", []):
			var station := load(entry.path) as Station
			if station == null: continue
			station.is_locked = entry.get("locked", false)
			station.active_craft_event = entry.get("event", "")
			station.locked_slot_indices.assign(entry.get("slots", []))
			live.append(station)
		if not live.is_empty():
			state["live_resources"] = live
		container_states[id] = state
#endregion

func _get_current_absolute_minutes() -> int:
	return TimeManager.julian_day * TimeManager.DAY_MINUTES + TimeManager.minutes
