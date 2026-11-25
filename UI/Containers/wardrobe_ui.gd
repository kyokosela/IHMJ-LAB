extends Control
class_name WardrobeUI
## UI del armario (especificacion de Ramiro): Mayui con la ropa actual a la izquierda y las prendas colgadas a la derecha.
## Se maneja con el mouse: al pasar sobre una prenda se resalta; al hacer clic Mayui muestra el cuadro "cambiandose" 1 s y
## luego el render con la ropa nueva (vestirse suma 2 min al reloj). La imagen de cada prenda depende de su estado (limpia,
## sucia, mojada, mojada y sucia). La ropa vive en PlayerManager (outfit y wardrobe). Esc cierra.

signal outfit_chosen(item: Item)

@export var render_rect : TextureRect
@export var basket_rect : TextureRect
@export var basket_highlight : TextureRect
@export var basket_hit : Control
## id de outfit ("home", "work") -> nodo con los hijos Layer (la prenda), Highlight (resaltado) y Hit (zona de clic)
@export var garment_slots : Dictionary[String, Control] = {}

var changing_seconds : float = 1.0   ## cuanto dura el cuadro "cambiandose"
var _busy : bool = false
var _locked : bool = false
var _hanging : Dictionary = {}       ## id de outfit -> Item colgado
var _basket : ClothingData = preload("res://Resources/Clothing/basket.tres")

func _ready() -> void:
	for id in garment_slots.keys():
		var hit : Control = garment_slots[id].get_node("Hit")
		hit.mouse_entered.connect(_on_garment_hover.bind(id, true))
		hit.mouse_exited.connect(_on_garment_hover.bind(id, false))
		hit.gui_input.connect(_on_garment_input.bind(id))
	if basket_hit != null:
		basket_hit.mouse_entered.connect(_on_basket_hover.bind(true))
		basket_hit.mouse_exited.connect(_on_basket_hover.bind(false))

func _exit_tree() -> void:
	if _locked:
		_locked = false
		GameManager.modal_count -= 1

## Abre el armario: Mayui queda quieta mientras esta abierto (mismo contador que el PC y las demas UI).
func open() -> void:
	if visible: return
	refresh()
	visible = true
	if not _locked:
		_locked = true
		GameManager.modal_count += 1

func close() -> void:
	if _busy or not visible: return
	visible = false
	if _locked:
		_locked = false
		GameManager.modal_count -= 1

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

## Redibuja segun lo que lleva puesto Mayui y lo que cuelga en el armario.
func refresh() -> void:
	_hanging.clear()
	for item in PlayerManager.wardrobe:
		var id : String = PlayerManager.outfit_id_of(item)
		if garment_slots.has(id):
			_hanging[id] = item
	for id in garment_slots.keys():
		var slot : Control = garment_slots[id]
		var item : Item = _hanging.get(id)
		slot.visible = item != null
		slot.get_node("Highlight").visible = false
		if item != null:
			slot.get_node("Layer").texture = _clothing_of(item).get_hanger_texture(item.has_state("dirty"), item.has_state("wet"))
	var worn : ClothingData = _clothing_of(PlayerManager.outfit)
	render_rect.texture = worn.render if worn != null else null
	# Cesta (propuesta mia, pendiente de tu OK): se ve llena si alguna prenda esta sucia
	var any_dirty : bool = PlayerManager.outfit != null and PlayerManager.outfit.has_state("dirty") and PlayerManager.get_outfit_id() != "towel"
	for item in PlayerManager.wardrobe:
		if item.has_state("dirty"):
			any_dirty = true
	basket_rect.texture = _basket.full if any_dirty else _basket.empty
	basket_highlight.texture = _basket.full_selection if any_dirty else _basket.empty_selection
	basket_highlight.visible = false

func _clothing_of(item: Item) -> ClothingData:
	if item == null or item.data == null: return null
	var behavior = item.data.behavior as ClothBehavior
	return behavior.clothing if behavior != null else null

func _on_garment_hover(id: String, inside: bool) -> void:
	if _busy or not garment_slots.has(id): return
	garment_slots[id].get_node("Highlight").visible = inside

func _on_basket_hover(inside: bool) -> void:
	if not _busy:
		basket_highlight.visible = inside

func _on_garment_input(event: InputEvent, id: String) -> void:
	if _busy: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item : Item = _hanging.get(id)
		if item != null:
			_choose(item)

## Clic en una prenda: cuadro "cambiandose" -> Mayui se la pone (sprite, estado y efectos) -> render nuevo.
func _choose(item: Item) -> void:
	_busy = true
	for id in garment_slots.keys():
		garment_slots[id].get_node("Highlight").visible = false
	basket_highlight.visible = false
	var target : ClothingData = _clothing_of(item)
	if target != null and target.render_changing != null:
		render_rect.texture = target.render_changing
	if changing_seconds > 0.0:
		await get_tree().create_timer(changing_seconds).timeout
	PlayerManager.wear_clothes(item)
	TimeManager.add_to_current_time(PlayerManager.CHANGE_CLOTHES_TIME)
	refresh()
	_busy = false
	outfit_chosen.emit(item)