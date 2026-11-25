extends Control
class_name MirrorUI
## UI del espejo del lavamanos (tu guion DIALOGOS, "LAVAMANOS / BAÑO", y tu arte de Docs/lavamanos mayui): Mayui frente al
## espejo con la ropa que lleva puesta. Se maneja con el mouse:
##  - el cepillo (se resalta al pasar): Cepillarse, UNA vez al dia -> Mayui con el brazo en la boca 1.5 s, 5 min y tarea TEETH.
##  - el espejo (Mayui): Verse la cara -> un comentario segun su estado.
##  - la llave: Lavar la ropa -> solo con ropa sucia en las manos y no durante el tutorial (opcion bloqueada).
## Para salir: Esc, o llevar el mouse abajo (sube una flecha; clic para salir). Las primeras veces la flecha se muestra sola.
## Capas (de atras a adelante): Bg, Towel, FaucetHighlight, Mayui (su imagen TRAE el marco del espejo, que tapa el vaso), CupFront
## (recorte del Bg con el vaso, el tubo y su sombra: vuelve a ponerlos DELANTE del marco, porque el espejo esta pegado a la pared),
## Brush y BrushHighlight. Si cambia el arte, CupFront se vuelve a recortar de mirror_bg.jpg (x 634..735, y 733..782, borde difuminado).

signal brushed

const LINE_BRUSH : String = "Te cepillas los dientes"
const LINE_ALREADY_BRUSHED : String = "Ya me cepillé."   ## texto provisional (tu guion no dice nada de repetir)
const LINE_LOOK_GOOD : String = "No me veo tan mal."
const LINE_LOOK_BAD : String = "He estado peor."
const HINT_FIRST_TIMES : int = 3
const EXIT_SHOWN_Y : float = 985.0
const EXIT_HIDDEN_Y : float = 1085.0

static var _times_opened : int = 0

@export var mayui_rect : TextureRect
@export var brush_rect : TextureRect
@export var towel_rect : TextureRect
@export var feedback_label : Label
@export var exit_panel : Control
@export var highlights : Dictionary[String, TextureRect] = {}   ## "brush" y "faucet": resaltado al pasar el mouse
@export var hits : Dictionary[String, Control] = {}             ## "brush", "faucet" y "mirror": zonas de clic

var brush_seconds : float = 1.5        ## cuanto se ve a Mayui con el brazo en la boca
var feedback_seconds : float = 2.5     ## cuanto se ve el comentario de Mayui
var exit_hint_seconds : float = 3.0    ## cuanto se ve sola la flecha de salir las primeras veces
var exit_visible : bool = false
var _busy : bool = false
var _locked : bool = false
var _feedback_id : int = 0
var _open_token : int = 0
var _exit_hint_active : bool = false
var _exit_tween : Tween

func _ready() -> void:
	for id in hits.keys():
		var hit : Control = hits[id]
		hit.mouse_entered.connect(_on_hover.bind(id, true))
		hit.mouse_exited.connect(_on_hover.bind(id, false))
		hit.gui_input.connect(_on_hit_input.bind(id))
	exit_panel.gui_input.connect(_on_exit_input)
	exit_panel.position.y = EXIT_HIDDEN_Y

func _exit_tree() -> void:
	if _locked:
		_locked = false
		GameManager.modal_count -= 1

## Abre el espejo: Mayui queda quieta mientras esta abierto (mismo contador que el PC y las demas UI).
func open() -> void:
	if visible: return
	refresh()
	visible = true
	_open_token += 1
	if not _locked:
		_locked = true
		GameManager.modal_count += 1
	_times_opened += 1
	if _times_opened <= HINT_FIRST_TIMES:
		_hint_exit()

func close() -> void:
	if _busy or not visible: return
	visible = false
	_open_token += 1
	_exit_hint_active = false
	exit_visible = false
	exit_panel.position.y = EXIT_HIDDEN_Y
	if _locked:
		_locked = false
		GameManager.modal_count -= 1

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseMotion:
		_update_exit_from_mouse()

## Redibuja segun la ropa que lleva Mayui: su imagen frente al espejo; la toalla cuelga solo si no la lleva puesta.
func refresh() -> void:
	var data : ClothingData = _clothing_of(PlayerManager.outfit)
	mayui_rect.texture = data.mirror if data != null else null
	mayui_rect.visible = mayui_rect.texture != null
	brush_rect.visible = true
	towel_rect.visible = PlayerManager.get_outfit_id() != "towel"
	_hide_highlights()
	feedback_label.text = ""
	feedback_label.visible = false

func _clothing_of(item: Item) -> ClothingData:
	if item == null or item.data == null: return null
	var behavior = item.data.behavior as ClothBehavior
	return behavior.clothing if behavior != null else null

func _hide_highlights() -> void:
	for id in highlights.keys():
		highlights[id].visible = false

func _on_hover(id: String, inside: bool) -> void:
	if _busy or not highlights.has(id): return
	if id == "faucet" and not can_wash():
		inside = false
	if id == "brush" and not can_brush():
		inside = false
	highlights[id].visible = inside

func _on_hit_input(event: InputEvent, id: String) -> void:
	if _busy: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match id:
			"brush": _brush()
			"mirror": _look()
			"faucet": _wash()

## Comentario de Mayui sobre la pantalla (arriba, unos segundos). Los dialogos de Dialogic se ven por debajo de esta UI.
func _say(text: String) -> void:
	_feedback_id += 1
	var id : int = _feedback_id
	feedback_label.text = text
	feedback_label.visible = true
	await get_tree().create_timer(feedback_seconds).timeout
	if id == _feedback_id:
		feedback_label.visible = false

## Cepillarse (una vez al dia): Mayui se muestra con el brazo en la boca 1.5 s, tarda 5 min y marca la tarea TEETH del tutorial.
func can_brush() -> bool:
	return not PlayerManager.daily.brushed

func _brush() -> void:
	if not can_brush():
		_say(LINE_ALREADY_BRUSHED)
		return
	_busy = true
	_hide_highlights()
	brush_rect.visible = false
	_say(LINE_BRUSH)
	var data : ClothingData = _clothing_of(PlayerManager.outfit)
	var idle : Texture2D = data.mirror if data != null else null
	var alt : Texture2D = data.mirror_alt if data != null else null
	mayui_rect.texture = alt if alt != null else idle
	await get_tree().create_timer(brush_seconds).timeout
	mayui_rect.texture = idle
	brush_rect.visible = true
	PlayerManager.register_brush()
	TimeManager.add_to_current_time(PlayerManager.BRUSH_TIME)
	if TaskManager.is_task_list_active("TUTORIAL_DOOR"):
		TaskManager.done_task("TUTORIAL_DOOR", "TEETH")
	_busy = false
	brushed.emit()

## Verse la cara: un comentario segun su estado (propuesta: mal estado = Maloliente, Debilitamiento o Estres).
func _look() -> void:
	var bad : bool = PlayerManager.has_effect("SMELLY") or PlayerManager.has_effect("WEAK") or PlayerManager.has_effect("STRESS")
	_say(LINE_LOOK_BAD if bad else LINE_LOOK_GOOD)

## Prendas sucias en las manos de Mayui (el lavamanos solo lava ropa que lleva en las manos).
func dirty_clothes_in_hands() -> Array:
	var sucias := []
	if PlayerManager.player == null: return sucias
	for item in PlayerManager.player.inventory.get_all_player_items():
		if item.data.item_type == ItemData.TYPE.CLOTH and item.has_state("dirty"):
			sucias.append(item)
	return sucias

func tutorial_blocks_wash() -> bool:
	return TaskManager.is_task_list_active("TUTORIAL_DOOR") and not TaskManager.is_task_list_done("TUTORIAL_DOOR")

func can_wash() -> bool:
	return not tutorial_blocks_wash() and not dirty_clothes_in_hands().is_empty()

## Lavar la ropa: queda limpia y mojada ("Lavaste [prenda]"). Bloqueado durante el tutorial.
func _wash() -> void:
	if not can_wash(): return
	var item : Item = dirty_clothes_in_hands()[0]
	var clean : CustomCondition = item.get_custom_condition("cleanliness")
	var wet : CustomCondition = item.get_custom_condition("wetness")
	if clean != null:
		clean.value = 100.0
	if wet != null:
		wet.value = 100.0
	item.update_states()
	var data : ClothingData = _clothing_of(item)
	_say("Lavaste %s" % (data.item_name.to_lower() if data != null else "la prenda"))

#region Salir
func _on_exit_input(event: InputEvent) -> void:
	if _busy: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _update_exit_from_mouse() -> void:
	if _busy: return
	var y : float = get_local_mouse_position().y
	if y > 940.0:
		_set_exit_visible(true)
	elif y < 860.0 and not _exit_hint_active:
		_set_exit_visible(false)

func _set_exit_visible(shown: bool) -> void:
	if shown == exit_visible: return
	exit_visible = shown
	if _exit_tween != null and _exit_tween.is_valid():
		_exit_tween.kill()
	_exit_tween = create_tween()
	_exit_tween.tween_property(exit_panel, "position:y", EXIT_SHOWN_Y if shown else EXIT_HIDDEN_Y, 0.18)

## Las primeras veces la flecha de salir se muestra sola unos segundos (como la animacion de deslizar de las redes).
func _hint_exit() -> void:
	_exit_hint_active = true
	_set_exit_visible(true)
	var token : int = _open_token
	await get_tree().create_timer(exit_hint_seconds).timeout
	if token != _open_token: return
	_exit_hint_active = false
	_update_exit_from_mouse()
#endregion