extends PanelContainer
## Lo que Mayui lleva encima, arriba a la izquierda y de arriba hacia abajo (pedido de Ramiro, 2026-11-26): primero las
## manos y despues la mochila, si la tiene. Se esconde si no lleva nada o con una pantalla abierta (la cocina ya las muestra).

const ICON_SIZE := Vector2(64, 64)

@onready var rows : VBoxContainer = %CarriedRows

var _shown : String = "" ## para redibujar solo cuando cambia

func _process(_delta: float) -> void:
	var items : Array[Item] = _carried()
	visible = not items.is_empty() and GameManager.modal_count == 0
	var signature : String = str(items.map(func(item: Item) -> String:
		return "%d+%d" % [item.get_instance_id(), item.held_item.get_instance_id() if item.held_item != null else 0]))
	if signature != _shown:
		_shown = signature
		_draw_rows(items)

## Los objetos de las manos y despues los de la mochila.
func _carried() -> Array[Item]:
	var items : Array[Item] = []
	var player = PlayerManager.player
	if not is_instance_valid(player) or player.inventory == null:
		return items
	var carrier = player.inventory
	var indices : Array = []
	indices.append_array(carrier.get_hands_indices())
	indices.append_array(carrier.get_bag_indices())
	for i in indices:
		var slot = carrier.inventory.slots[i]
		if not slot.is_empty():
			items.append(slot.item)
	return items

func _draw_rows(items: Array[Item]) -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	for item in items:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 12)
		var icon := TextureRect.new()
		icon.texture = item.get_display_texture()
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var label := Label.new()
		label.text = tr(item.data.item_name)
		if item.held_item != null:
			label.text += "\ncon %s" % tr(item.held_item.data.item_name).to_lower()
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 22)
		row.add_child(label)
		rows.add_child(row)
