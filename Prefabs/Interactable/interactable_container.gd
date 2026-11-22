@tool
extends Interactable
class_name InteractableContainer

@export_group("Inventory")
@export var initial_items: Array[ItemData]
@export var container_ui : ContainerUI

var entity_container_ref : InventoryContainer
var container: InventoryContainer

func _ready() -> void:
	super()
	_find_container()
	if not Engine.is_editor_hint():
		assert(container != null, "ERROR: No hay InventoryContainer en " + name)
		# Completado: los items iniciales solo la PRIMERA vez. Si el ContainerManager ya guardo este contenedor
		# (la escena se recrea al cambiar de zona) se restaura lo que quedo; antes se agregaban otra vez.
		var already_saved : bool = container != null and container.container_id != "" \
				and ContainerManager.container_states.has(container.container_id)
		if container and not already_saved:
			for item in initial_items:
				container.add_item_by_data(item)

func _find_container():
	for child in get_children():
		if child is InventoryContainer:
			container = child
			return
	container = null

func open_ui():
	if !container_ui: return
	container_ui.open(self)

func custom_execute():
	#container.open_container o algo para que salga la UI y que esta se encargue
	#de usar la api para cosas etc
	
	open_ui()
	# Completado: Interactable solo reactivaba las acciones "reusables" que tienen dialogo; sin esto el
	# contenedor se podia abrir una sola vez (execute() deja can_interact en false).
	if reusable:
		can_interact = true
