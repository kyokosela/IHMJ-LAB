extends Control
class_name ShowerScene
## La escena de la ducha (Flow de juego.txt: "aparece una transicion, dibujo de la silueta de Mayui a traves de las cortinas").
## PROVISIONAL hasta que haya arte: la silueta es su render con la toalla oscurecido y los azulejos, la cortina y el agua se
## dibujan por codigo (nodos Wall y Curtain). El agua suena cuando exista Audio/SFX/shower.ogg.
## La abre bathe.gd. En el tutorial dice "Que frio." y estornuda dentro (senal "estornudo": la silueta da un respingo) y se va
## con la senal "ducha_fuera" de ducha_tutorial.dtl; sin dialogo, sola a los scene_seconds segundos. Mientras se ve, Mayui
## queda quieta (GameManager.modal_count).

signal closed

const OUT_SIGNAL : String = "ducha_fuera"
const SNEEZE_SIGNAL : String = "estornudo"
const STALL := Rect2(560, 90, 800, 950)   ## el hueco de la ducha, en el lienzo de 1920x1080
const FOLDS : int = 10                    ## pliegues de la cortina
const DROPS : int = 70

@export var wall : Control
@export var curtain : Control
@export var fade_seconds : float = 0.4
@export var scene_seconds : float = 2.0   ## cuanto se ve cuando no hay dialogo

var _locked : bool = false
var _closing : bool = false
var _tween : Tween
var _drops : Array[Vector3] = []          ## x, y y velocidad de cada hilo de agua

func _ready() -> void:
	add_to_group("shower_scene")
	visible = false
	set_process(false)
	wall.draw.connect(_draw_wall)
	curtain.draw.connect(_draw_curtain)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	for i in DROPS:
		_drops.append(Vector3(randf_range(STALL.position.x + 30.0, STALL.end.x - 30.0), randf_range(STALL.position.y, STALL.end.y), randf_range(900.0, 1400.0)))

func _exit_tree() -> void:
	AudioManager.stop_loop("shower")
	_unlock()

## wait_for_dialog: la escena se queda hasta la senal del dialogo (o hasta que el dialogo termine).
func play(wait_for_dialog: bool) -> void:
	if visible: return
	_closing = false
	visible = true
	set_process(true)
	AudioManager.play_loop("shower")   # silencio mientras no haya archivo en Audio/SFX
	modulate.a = 0.0
	if not _locked:
		_locked = true
		GameManager.modal_count += 1
	_fade(1.0)
	if wait_for_dialog:
		if not Dialogic.timeline_ended.is_connected(close):
			Dialogic.timeline_ended.connect(close, CONNECT_ONE_SHOT)
	else:
		await get_tree().create_timer(fade_seconds + scene_seconds).timeout
		close()

func close() -> void:
	if not visible or _closing: return
	_closing = true
	AudioManager.stop_loop("shower")
	_fade(0.0)
	await _tween.finished
	visible = false
	set_process(false)
	_closing = false
	_unlock()
	closed.emit()

func _unlock() -> void:
	if not _locked: return
	_locked = false
	GameManager.modal_count -= 1

func _fade(alpha: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", alpha, fade_seconds)

func _on_dialogic_signal(argument: Variant) -> void:
	if str(argument) == OUT_SIGNAL:
		close()
	elif str(argument) == SNEEZE_SIGNAL and visible:
		_sneeze()

## El respingo del estornudo: la silueta baja de golpe, rebota y vuelve a su sitio.
func _sneeze() -> void:
	var silhouette : Control = $Canvas/Silhouette
	var home : Vector2 = silhouette.position
	var jolt := create_tween()
	jolt.tween_interval(0.15)
	jolt.tween_property(silhouette, "position", home + Vector2(0, 34), 0.07)
	jolt.tween_property(silhouette, "position", home + Vector2(0, -14), 0.09)
	jolt.tween_property(silhouette, "position", home, 0.14)

func _process(delta: float) -> void:
	for i in _drops.size():
		var drop : Vector3 = _drops[i]
		drop.y += drop.z * delta
		if drop.y > STALL.end.y - 40.0:
			drop.y = STALL.position.y + 40.0
		_drops[i] = drop
	curtain.queue_redraw()

## Pared de azulejos y piso.
func _draw_wall() -> void:
	wall.draw_rect(STALL.grow(40.0), Color(0.34, 0.43, 0.5))
	var x : float = STALL.position.x
	while x <= STALL.end.x:
		wall.draw_line(Vector2(x, STALL.position.y - 40.0), Vector2(x, STALL.end.y + 40.0), Color(0.27, 0.35, 0.42), 4.0)
		x += 100.0
	var y : float = STALL.position.y + 50.0
	while y <= STALL.end.y:
		wall.draw_line(Vector2(STALL.position.x - 40.0, y), Vector2(STALL.end.x + 40.0, y), Color(0.27, 0.35, 0.42), 4.0)
		y += 100.0
	wall.draw_rect(Rect2(STALL.position.x - 40.0, STALL.end.y, STALL.size.x + 80.0, 40.0), Color(0.2, 0.24, 0.3))

## Agua, cortina entreabierta a la luz y su barra.
func _draw_curtain() -> void:
	for drop in _drops:
		curtain.draw_line(Vector2(drop.x, drop.y - 34.0), Vector2(drop.x, drop.y), Color(0.85, 0.93, 1.0, 0.55), 3.0)
	var width : float = STALL.size.x / FOLDS
	for i in FOLDS:
		var left : float = STALL.position.x + i * width
		var shade : float = 0.30 if i % 2 == 0 else 0.44
		var hem : float = STALL.end.y - 24.0 + (14.0 if i % 2 == 0 else 0.0)
		curtain.draw_rect(Rect2(left, STALL.position.y + 18.0, width, hem - STALL.position.y - 18.0), Color(0.86, 0.9, 0.95, shade))
		curtain.draw_line(Vector2(left, STALL.position.y + 18.0), Vector2(left, hem), Color(0.95, 0.98, 1.0, 0.5), 3.0)
		curtain.draw_arc(Vector2(left + width * 0.5, STALL.position.y + 8.0), 12.0, 0.0, TAU, 20, Color(0.75, 0.77, 0.8), 5.0)
	curtain.draw_line(Vector2(STALL.position.x - 30.0, STALL.position.y), Vector2(STALL.end.x + 30.0, STALL.position.y), Color(0.6, 0.62, 0.66), 14.0)
