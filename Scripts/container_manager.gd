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
	
	var data = {}
	if container.inventory:
		data["inventory"] = container.inventory.to_dict()
	
	data["timestamp_abs"] = _get_current_absolute_minutes()
	
	container_states[container.container_id] = data
	# print("Saved state for container: " + container.container_id)

func _get_current_absolute_minutes() -> int:
	return TimeManager.julian_day * TimeManager.DAY_MINUTES + TimeManager.minutes
