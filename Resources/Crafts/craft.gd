extends Resource
class_name Crafts
## Define una receta de crafteo con soporte para resultados variables

@export var check_order : bool
@export var needed_time : String = "00:00"  ## Formato HH:MM, "00:00" = instantáneo
var time_left : String

@export_group("Recipe")
@export var needed_items : Array[CraftSlot]
@export var needed_util : String = ""  ## Util requerido (inherente de estación o de item)

@export_group("Result")
## Resultado por defecto si ningún CraftResult aplica
@export var result_item : ItemData

## Item que el resultado contendrá (held_item)
@export var result_held_item : ItemData

## Valores iniciales para las condiciones del held_item: {"coldness": 10}
@export var result_held_item_conditions : Dictionary[String,float] = {}

## Resultados variables basados en estados de ingredientes
## Se evalúan en orden, el primero que coincida se usa
@export var variable_results : Array[CraftResult] = []

## Obtiene el CraftResult apropiado basado en los items
func get_matching_result(items: Array[Item]) -> CraftResult:
	for craft_result in variable_results:
		if craft_result.matches(items):
			return craft_result
	return null

## Crea el item resultado apropiado
func create_result(items: Array[Item]) -> Item:
	var matching_result = get_matching_result(items)
	
	if matching_result != null:
		return matching_result.create_result(items)
	
	# Usar resultado por defecto
	var result = Item.new(result_item)
	
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
	
	# Asegurar que los estados del resultado estén actualizados
	result.update_states()
	
	return result

## Verifica si esta receta puede ejecutarse con los items dados
func can_craft(items: Array[Item]) -> bool:
	if items.size() < needed_items.size():
		return false
	
	if check_order:
		return _check_ordered(items)
	else:
		return _check_unordered(items)

func _check_ordered(items: Array[Item]) -> bool:
	for i in range(needed_items.size()):
		if i >= items.size():
			return false
		if not needed_items[i].matches(items[i]):
			return false
	return true

func _check_unordered(items: Array[Item]) -> bool:
	var used_indices: Array[int] = []
	
	for needed in needed_items:
		var found = false
		for i in range(items.size()):
			if i in used_indices:
				continue
			if needed.matches(items[i]):
				used_indices.append(i)
				found = true
				break
		if not found:
			return false
	
	return true

## Obtiene los items que coinciden con la receta (en orden de needed_items)
func get_matched_items(items: Array[Item]) -> Array[Item]:
	var matched: Array[Item] = []
	var used_indices: Array[int] = []
	
	for needed in needed_items:
		for i in range(items.size()):
			if i in used_indices:
				continue
			if needed.matches(items[i]):
				matched.append(items[i])
				used_indices.append(i)
				break
	
	return matched

## Verifica si es un craft instantáneo
func is_instant() -> bool:
	return needed_time == "" or needed_time == "00:00"
