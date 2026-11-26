extends Control
class_name WardrobeUI
## UI del armario (especificacion de Ramiro): Mayui con la ropa actual a la izquierda y las prendas colgadas a la derecha.
## Se maneja con el mouse: al pasar sobre una prenda se resalta; al hacer clic Mayui muestra el cuadro "cambiandose" 1 s y
## luego el render con la ropa nueva (vestirse suma 2 min al reloj). La imagen de cada prenda depende de su estado (limpia,
## sucia, mojada, mojada y sucia). La ropa vive en PlayerManager (outfit y wardrobe). Se entra y se sale oscureciendo un
## momento; Esc cierra, salvo justo despues de cambiarse (settle_seconds), para que se vea la ropa puesta.

signal outfit_chosen(item: Item)

@export var render_rect : TextureRect
@export var basket_rect : TextureRect
@export var basket_highlight : TextureRect
@export var basket_hit : Control
## id de outfit ("home", "work") -> nodo con los hijos Layer (la prenda), Highlight (resaltado) y Hit (zona de clic)
@export var garment_slots : Dictionary[String, Control] = {}

@export_group("Frases (tu guion)")
## id de outfit -> lo que dice Mayui si quiere ponersela en la manana del tutorial (no se cambia: solo vale el uniforme)
@export var tutorial_refusals : Dictionary[String, StringChain] = {}
@export var basket_lines : StringChain          ## al tocar la cesta con ropa sucia
@export var uniform_dialog : DialogicTimeline   ## al ponerse el uniforme en el tutorial, ya duchada (una vez)

const UNIFORM_SAID_FLAG : String = "tutorial_uniform_said"
var _basket_full : bool = false
var changing_seconds : float = 1.0   ## cuanto dura el cuadro "cambiandose"
var settle_seconds : float = 1.0     ## despues de cambiarse, Esc espera esto para que se vea la ropa puesta
var fade_seconds : float = 0.25      ## al entrar y salir: oscurece, cambia y aclara (0: sin transicion)
var _esc_ready_at : int = 0          ## instante (ms) desde el que Esc vuelve a cerrar
var _moving : bool = false           ## entrando o saliendo
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
		basket_hit.gui_input.connect(_on_basket_input)

func _exit_tree() -> void:
	if _locked:
		_locked = false
		GameManager.modal_count -= 1

## Abre el armario: Mayui queda quieta mientras esta abierto (mismo contador que el PC y las demas UI).
func open() -> void:
	if visible or _moving: return
	if not _locked:
		_locked = true
		GameManager.modal_count += 1
	await _fade_through(func() -> void:
		refresh()
		visible = true)

func close() -> void:
	if _busy or _moving or not visible: return
	await _fade_through(func() -> void: visible = false)
	if _locked:
		_locked = false
		GameManager.modal_count -= 1

## La transicion: oscurece, hace el cambio y aclara.
func _fade_through(change: Callable) -> void:
	if fade_seconds <= 0.0:
		change.call()
		return
	_moving = true
	TransitionManager.fadeIn(fade_seconds)
	await get_tree().create_timer(fade_seconds).timeout
	change.call()
	TransitionManager.fadeOut(fade_seconds)
	await get_tree().create_timer(fade_seconds).timeout
	_moving = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if Time.get_ticks_msec() >= _esc_ready_at:
			close()

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
	_basket_full = any_dirty
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
	if _busy or _moving or _is_talking(): return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item : Item = _hanging.get(id)
		if item == null: return
		if tutorial_refusals.has(id) and _in_tutorial_morning():
			_say(tutorial_refusals[id])
			return
		_choose(item)

func _on_basket_input(event: InputEvent) -> void:
	if _busy or _is_talking() or not _basket_full or basket_lines == null: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_say(basket_lines)

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
	_esc_ready_at = Time.get_ticks_msec() + int(settle_seconds * 1000.0)
	_busy = false
	outfit_chosen.emit(item)
	_comment_uniform()

#region Frases
## Tu guion: ya duchada y con el uniforme puesto, en el tutorial Mayui lo comenta y le ruge el estomago.
func _comment_uniform() -> void:
	if uniform_dialog == null or PlayerManager.get_outfit_id() != "work" or not _in_tutorial_morning(): return
	if NarrativeFlags.has_flag(UNIFORM_SAID_FLAG) or not _bath_done(): return
	NarrativeFlags.set_flag(UNIFORM_SAID_FLAG)
	Dialogic.start(uniform_dialog)

func _say(lines: StringChain) -> void:
	Dialogic.create_quick_dialog(Dialogic.characters_path["Mayui"], lines.get_message())

func _is_talking() -> bool:
	return Dialogic.current_timeline != null

## La manana del tutorial termina la primera vez que Mayui sale con la rutina completa (exit_door.gd).
func _in_tutorial_morning() -> bool:
	return TaskManager.is_task_list_active("TUTORIAL_DOOR") and not NarrativeFlags.has_flag("tutorial_door_done")

func _bath_done() -> bool:
	var tasks : TaskList = TaskManager.get_task_list_res("TUTORIAL_DOOR")
	var bath : Task = tasks.get_task_res("BATHE") if tasks != null else null
	return bath != null and bath.task_done
#endregion