extends Resource
class_name CraftResult
## Define un resultado de crafteo basado en condiciones de los ingredientes
## Permite resultados variables según el estado de los items usados

@export_group("Conditions")
## Requisitos de estados por ingrediente: {"item_id": ["state1", "state2"]}
## Ej: {"coffee_pot": ["hot"]} -> el coffee_pot debe estar hot
@export var required_ingredient_states: Dictionary = {}

@export_group("Result")
## Item que se obtiene como resultado
@export var result_item: ItemData

## Item que el resultado contendrá (held_item)
@export var result_held_item: ItemData

## Valores iniciales para las condiciones del held_item: {"coldness": 10}
@export var result_held_item_conditions: Dictionary = {}

## Estados iniciales del resultado
@export var result_initial_states: Array[ItemState] = []

## Condiciones personalizadas a heredar de los ingredientes
## Ej: ["coldness"] -> el resultado hereda el valor de coldness del ingrediente
@export var inherit_conditions: Array[String] = []

## Item del cual heredar las condiciones (item_id)
## Si está vacío, intenta heredar del primer ingrediente que tenga la condición
@export var inherit_from_item: String = ""

@export_group("Modifiers")
## Modificar el valor de condition del resultado basado en ingredientes
@export var inherit_condition_average: bool = false  ## Promedia la condition de los ingredientes

## Valor inicial de condition del resultado (si no se hereda)
@export_range(0.0, 100.0) var initial_condition: float = 100.0

## Verifica si este resultado aplica para los items dados
func matches(items: Array[Item]) -> bool:
	if required_ingredient_states.is_empty():
		return true  # Sin requisitos = siempre aplica (fallback)
	
	for item_id in required_ingredient_states.keys():
		var required_states: Array = required_ingredient_states[item_id]
		var found_item: Item = null
		
		# Buscar el item por id
		for item in items:
			if item.data.item_unique_name == item_id:
				found_item = item
				break
		
		if found_item == null:
			return false  # No se encontró el item requerido
		
		# Verificar que tenga todos los estados requeridos
		for state_id in required_states:
			if not found_item.has_state(state_id):
				return false
	
	return true

## Crea el item resultado con las propiedades heredadas
func create_result(items: Array[Item]) -> Item:
	var result = Item.new(result_item)
	
	# Aplicar estados iniciales
	for state in result_initial_states:
		result.add_state(state)
	
	# Si hay held_item configurado, crearlo y asignarlo
	if result_held_item != null:
		var held = Item.new(result_held_item)
		# Aplicar valores de condiciones iniciales al held_item
		for condition_name in result_held_item_conditions.keys():
			var cc = held.get_custom_condition(condition_name)
			if cc != null:
				cc.value = result_held_item_conditions[condition_name]
		held.update_states()
		result.held_item = held
	
	# Heredar condiciones
	if not inherit_conditions.is_empty():
		_inherit_conditions_from(result, items)
	
	# Heredar/calcular condition
	if inherit_condition_average and not items.is_empty():
		var total: float = 0.0
		for item in items:
			total += item.condition
		result.condition = total / items.size()
	else:
		result.condition = initial_condition
	
	# Asegurar que los estados del resultado estén actualizados
	result.update_states()
	
	return result

## Hereda las condiciones especificadas de los ingredientes
func _inherit_conditions_from(result: Item, items: Array[Item]) -> void:
	for condition_name in inherit_conditions:
		var source_condition: CustomCondition = null
		
		# Buscar la condición en el item especificado o en cualquier ingrediente
		if inherit_from_item != "":
			for item in items:
				if item.data.item_unique_name == inherit_from_item:
					source_condition = item.get_custom_condition(condition_name)
					break
		else:
			for item in items:
				source_condition = item.get_custom_condition(condition_name)
				if source_condition != null:
					break
		
		if source_condition == null:
			continue
		
		# Buscar la condición correspondiente en el resultado
		var target_condition = result.get_custom_condition(condition_name)
		if target_condition != null:
			target_condition.value = source_condition.value
			result.update_states()
