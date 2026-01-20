extends Resource
class_name Item

@warning_ignore("unused_signal") 
signal used
signal item_changed
signal held_item_changed

@export var data : ItemData
@export var condition : float = 100.0:
	set(_v): 
		condition = clamp(_v, 0.0, 100.0)
		if data: update_states()

var states : Dictionary[String, ItemState]
var uses_left : int = 1

## Condiciones personalizadas INSTANCIADAS (duplicadas de data.custom_conditions)
## Cada Item tiene sus propios valores, no comparten con otros items del mismo tipo
var custom_conditions : Array[CustomCondition] = []


var held_item : Item = null :## Item contenido dentro de este (ej: café dentro de mug)
	set(_v):
		held_item = _v
		held_item_changed.emit()
		item_changed.emit()

var can_break : bool = false

func _init(p_data : ItemData = null) -> void:
	if p_data == null: return
	data = p_data
	uses_left = data.uses
	can_break = data.can_break
	_duplicate_custom_conditions()
	update_states()


func _duplicate_custom_conditions() -> void:## Duplica las custom_conditions del data para que cada instancia tenga sus propios valores
	custom_conditions.clear()
	for cc in data.custom_conditions:
		var duplicated = cc.duplicate(true)
		custom_conditions.append(duplicated)

func add_state(state : ItemState) -> void: ## Añade un estado, en caso de que ya contenga un estado de un grupo exclusivo, se reemplazara por el nuevo estado
	if state == null: return
	if state.exclusive_group != "":
		for s : ItemState in states.values():
			if s.exclusive_group == state.exclusive_group:
				states.erase(s.id)
	states[state.id] = state
	item_changed.emit()

func update_states():
	if data == null or data.behavior == null: return
	data.behavior.update_states(self)
	item_changed.emit()

func apply_decay(minutes: int, env_conditions : Array[String]):
	if data == null or data.behavior == null: return
	data.behavior.apply_base_decay(minutes, self, env_conditions)
	item_changed.emit()

func apply_enviroment(minutes: int, env_properties : Array[String]):
	if custom_conditions.is_empty(): return
	if data == null or data.behavior == null: return
	data.behavior.apply_enviroment(minutes, self, env_properties)
	item_changed.emit()

func get_custom_condition(condition_name : String) -> CustomCondition:
	for c in custom_conditions:
		if c.condition == condition_name: return c
	return null

func has_custom_condition(condition_name : String) -> bool:
	for c in custom_conditions:
		if c.condition == condition_name: return true
	return false
	
func decrease_condition_value(condition_name : String, value : float):
	var custom = get_custom_condition(condition_name)
	if custom != null:
		custom.value -= value
		item_changed.emit()
		
func increase_condition_value(condition_name : String, value : float):
	var custom = get_custom_condition(condition_name)
	if custom != null:
		custom.value += value
		item_changed.emit()

func has_state(id : String) -> bool:
	return states.has(id)

#region Holder Functions
## Verifica si este item puede contener otro item
func can_hold_item(content: Item) -> bool:
	if data == null: return false
	if not data.is_holder: return false
	if held_item != null: return false
	if content == null: return false
	
	if not data.holdable_types.is_empty():
		if content.data.item_type not in data.holdable_types:
			return false
	
	return true

## Asigna un item contenido
func hold(content: Item) -> bool:
	if not can_hold_item(content): return false
	held_item = content
	return true

## Libera y retorna el item contenido
func release_held_item() -> Item:
	var released = held_item
	held_item = null
	return released

## Verifica si tiene algo contenido
func has_held_item() -> bool:
	return held_item != null
#endregion
