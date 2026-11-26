extends PanelContainer
class_name InventorySlotUI

@onready var icon_rect : TextureRect = $Icon
@onready var amount_label : Label = $Amount
@onready var name_label : Label = $NameLabel
@onready var locked_overlay : Control = $LockedOverlay

var item : Item
var slot_index : int = -1
var parent_inventory : InventoryComponent

var _pending_update : bool = false
var _pending_locked : bool = false
var _has_pending_locked : bool = false

## Completado: quien crea la casilla puede revisar lo que se suelta en ella (la cocina: cada estacion acepta solo lo suyo).
## Se llama con (esta casilla, inventario de origen, casilla de origen); false = no se mueve nada.
var drop_filter : Callable
var hide_icon : bool = false ## la casilla no dibuja el objeto: la pantalla ya lo dibuja (la olla sobre la estufa)
var dim_when_locked : bool = true ## oscurecerse mientras la estacion trabaja (en las estaciones no hay cuadro)

func _ready():
	if _pending_update:
		_update_display()
		_pending_update = false
	if _has_pending_locked:
		_apply_locked(_pending_locked)
		_has_pending_locked = false

func set_item(p_item: Item):
	if item and item.item_changed.is_connected(_on_item_changed):
		item.item_changed.disconnect(_on_item_changed)
	item = p_item
	if item: item.item_changed.connect(_on_item_changed)
	if not is_node_ready():
		_pending_update = true
		return
	_update_display()

## El mismo objeto cambio (ej. se comio lo de la olla): se vuelve a dibujar.
func _on_item_changed() -> void:
	if is_node_ready(): _update_display()

func _update_display():
	icon_rect.visible = not hide_icon
	if item:
		var item_texture : Texture2D = item.get_display_texture()
		icon_rect.texture = item_texture if item_texture else PlaceholderTexture2D.new()

		tooltip_text = tr(item.data.item_name)   # el nombre sale al pasar el cursor
		if name_label:
			name_label.text = item.data.item_name
			name_label.visible = item_texture == null   # escrito sobre la casilla solo si no hay dibujo que lo identifique
		
		if item.uses_left > 1:
			amount_label.text = str(item.uses_left)
			amount_label.visible = true
		else:
			amount_label.visible = false
	else:
		icon_rect.texture = null
		tooltip_text = ""
		if name_label: name_label.visible = false
		amount_label.visible = false

func set_locked(locked: bool):
	if not is_node_ready():
		_pending_locked = locked
		_has_pending_locked = true
		return
	_apply_locked(locked)

func _apply_locked(locked: bool):
	if locked_overlay:
		locked_overlay.visible = locked   # tambien impide arrastrar o soltar mientras trabaja
		if not dim_when_locked:
			(locked_overlay as ColorRect).color = Color(0, 0, 0, 0)
	modulate = Color(0.7, 0.7, 0.7, 1.0) if locked and dim_when_locked else Color.WHITE

func display_item(p_item: Item):
	set_item(p_item)

func _get_drag_data(at_position: Vector2) -> Variant:
	if item == null: return null
	if parent_inventory == null or slot_index == -1: return null
	
	var preview = TextureRect.new()
	preview.texture = icon_rect.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	preview.custom_minimum_size = Vector2(64, 64)
	preview.modulate = Color(1, 1, 1, 0.7)
	
	var c = Control.new()
	c.add_child(preview)
	preview.position = -Vector2(32, 32)
	set_drag_preview(c)
	
	return { 
		"inventory": parent_inventory, 
		"index": slot_index,
		"origin_node": self
	}

## Completado: la UI no tenia forma de USAR un objeto (solo la tecla de depuracion `test`). Clic derecho o doble
## clic sobre un objeto de TUS manos lo usa (comer, beber...) con el use_item_at que ya existia.
func _gui_input(event: InputEvent) -> void:
	if item == null or parent_inventory == null: return
	if not (event is InputEventMouseButton and event.pressed): return
	var quiere_usar : bool = event.button_index == MOUSE_BUTTON_RIGHT \
			or (event.button_index == MOUSE_BUTTON_LEFT and event.double_click)
	if not quiere_usar: return
	var player_inventory = PlayerManager.player.inventory if PlayerManager.player else null
	if player_inventory != null and parent_inventory == player_inventory.inventory:
		player_inventory.use_item_at(slot_index)

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("inventory") and data.has("index")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if parent_inventory:
		if drop_filter.is_valid() and not drop_filter.call(self, data["inventory"], data["index"]):
			return
		parent_inventory.interact_inventory(slot_index, data["inventory"], data["index"])
