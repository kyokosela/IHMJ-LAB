extends Resource
class_name CraftSlot
## Define un ingrediente requerido para una receta

## ID único del item requerido (item_unique_name)
@export var item_id : String

## Estados que el item debe tener para ser válido
@export var required_states: Array[String] = []

## Estados que el item NO debe tener (bloquean el craft)
@export var excluded_states: Array[String] = []

@export_group("Held Item Requirements")
## Si el item debe tener contenido (held_item != null)
@export var requires_held_item: bool = false

## Si el item NO debe tener contenido (bloquea craft si tiene held_item)
@export var exclude_if_has_held_item: bool = false

## ID del item que debe estar contenido (vacío = cualquier contenido sirve)
@export var required_held_item_id: String = ""

## Estados que el held_item debe tener
@export var required_held_item_states: Array[String] = []

## Estados que el held_item NO debe tener (bloquean el craft)
@export var excluded_held_item_states: Array[String] = []

@export_group("Return Item")
## Item que se devuelve después del craft (ej: pot vacío después de verter café)
## Si es null, el item se consume completamente
@export var item_return : ItemData

## Si el item devuelto debe quedar con estado "dirty"
@export var mark_return_dirty : bool = false

## Estados que se deben copiar al item de retorno
@export var copy_states_to_return: Array[String] = []

## Si el held_item del original debe transferirse al return (en lugar de consumirse)
@export var transfer_held_to_return: bool = false

## Verifica si un item cumple con los requisitos de este slot
func matches(item: Item) -> bool:
	if item == null:
		return false
	
	# Verificar ID del item
	if item.data.item_unique_name != item_id:
		return false
	
	# Verificar estados requeridos del item
	for state in required_states:
		if not item.has_state(state):
			return false
	
	# Verificar estados excluidos (si tiene alguno, no es válido)
	for state in excluded_states:
		if item.has_state(state):
			return false
	
	if exclude_if_has_held_item:
		if item.has_held_item():
			return false
	
	# Verificar held_item si es requerido
	if requires_held_item:
		if not item.has_held_item():
			return false
		
		# Verificar ID del contenido si se especificó
		if required_held_item_id != "":
			if item.held_item.data.item_unique_name != required_held_item_id:
				return false
		
		# Verificar estados del contenido
		for state in required_held_item_states:
			if not item.held_item.has_state(state):
				return false
		
		# Verificar estados excluidos del contenido
		for state in excluded_held_item_states:
			if item.held_item.has_state(state):
				return false
	
	return true

## Crea el item de retorno con las propiedades apropiadas
func create_return_item(original_item: Item) -> Item:
	if item_return == null:
		return null
	
	var returned = Item.new(item_return)
	
	# Transferir held_item si corresponde
	if transfer_held_to_return and original_item.has_held_item():
		returned.held_item = original_item.held_item
	
	# Marcar como dirty si corresponde
	if mark_return_dirty:
		var cleanliness = returned.get_custom_condition("cleanliness")
		if cleanliness != null:
			cleanliness.value = 0
			returned.update_states()
	
	# Copiar estados especificados
	for state_id in copy_states_to_return:
		if original_item.has_state(state_id):
			var state = original_item.states[state_id]
			returned.add_state(state)
	
	# Asegurar que los estados estén actualizados
	returned.update_states()
	
	return returned
