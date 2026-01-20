extends Node
class_name SaveComponent

#region SETUP

## Requerido para cada componente
@export var uid: String = ""

## Propiedades a guardar. Su formato es:
## - "alias:propiedad"	cuando la propiedad y el alias difieren en nombre
## - "propiedad" 		shortcut cuando la propiedad y el alias tienen el mismo nombre
## 
## El alias es inmutable (por motivos de compatibilidad, una vez creado 
## solo puedes cambiar la propiedad
## e.g. cuando un valor que estaba leyendo cambia 
## su nombre por un refactor
## "slots:player_slots" -> "slots:inventory_slots"
@export var props_to_save: Array[String] = []

var _parent: Node
var _map: Dictionary = {}  # alias -> propiedad


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if uid.strip_edges().is_empty():
		warnings.append("UID required")
	
	for entry in props_to_save:
		var parsed = _parse_entry(entry)
		if parsed.is_empty():
			warnings.append("Invalid format: '%s'. Use 'alias:property' or 'property'" % entry)
	
	return warnings


func _enter_tree() -> void:
	_parent = get_parent()
	if uid.strip_edges().is_empty():
		push_error("SaveComponent: UID required at %s" % get_path())
		return
	_parse_props()
	SaveManager.register(self)


func _exit_tree() -> void:
	if is_queued_for_deletion():
		SaveManager.unregister(self)

#endregion

#region API

## TODO: wtf redundancia (refactorizar)
## retorna ComponentData con sus propiedades serializadas
func get_data() -> ComponentData:
	var data := ComponentData.new()
	for alias in _map:
		data.values[alias] = _deep_copy(_parent.get(_map[alias]))
	return data


## Aplica los datos de ComponentData, mapeando los alias a sus propiedades
func apply_data(data: ComponentData) -> void:
	if data == null:
		return
	for alias in _map:
		if alias in data.values:
			_set_value(_map[alias], data.values[alias])

#endregion

#region INTERNAL

func _parse_props() -> void:
	_map.clear()
	for entry in props_to_save:
		var parsed = _parse_entry(entry)
		if parsed.is_empty():
			push_error("SaveComponent [%s]: Invalid format '%s'" % [uid, entry])
			continue
		var alias: String = parsed[0]
		var prop: String = parsed[1]
		if not _has_property(_parent, prop):
			push_error("SaveComponent [%s]: Property '%s' not found in %s" % [uid, prop, _parent.name])
			continue
		_map[alias] = prop


## Verifica si un Object tiene una propiedad de script (no son hijos)
static func _has_property(obj: Object, prop_name: String) -> bool:
	for prop in obj.get_property_list():
		if prop.name == prop_name and prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			return true
	return false


## el parser (alias:propiedad)
static func _parse_entry(entry: String) -> Array:
	var trimmed = entry.strip_edges()
	if trimmed.is_empty():
		return []
	
	var idx = trimmed.find(":")
	if idx == -1:
		# Shorthand: "property" -> "property:property"
		return [trimmed, trimmed]
	
	var alias = trimmed.left(idx).strip_edges()
	var prop = trimmed.substr(idx + 1).strip_edges()
	
	if alias.is_empty() or prop.is_empty():
		return []
	
	return [alias, prop]


func _set_value(prop: String, val: Variant) -> void:
	var current = _parent.get(prop)
	# Para arrays tipados, limpia y rellena para preservar su tipo
	if current is Array and val is Array:
		current.clear()
		for item in val:
			current.append(item)
	else:
		_parent.set(prop, val)


## Deep copy de un valor. Recursos son duplicados, primitivos van directamente al return
static func _deep_copy(val: Variant) -> Variant:
	if val == null:
		return null
	if val is bool or val is int or val is float or val is String:
		return val
	if val is Array:
		return val.map(_deep_copy)
	if val is Dictionary:
		var d := {}
		for k in val:
			d[k] = _deep_copy(val[k])
		return d
	if val is Resource:
		return val.duplicate(true)
		
	# Tipos nativos (vector2, color, ...)
	return val

#endregion
