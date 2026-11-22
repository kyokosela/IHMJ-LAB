extends CanvasLayer

signal transition_finished

@onready var color_rect : ColorRect = %ColorRect

@export var transition_speed : float = 1

var _tween : Tween

func fadeIn(_custom_time : float = transition_speed) -> void :
	_fade(1.0, _custom_time)

func fadeOut(_custom_time : float = transition_speed) -> void :
	_fade(0.0, _custom_time)

## Un solo fundido a la vez: si empieza otro, el anterior se cancela (y NO emite transition_finished).
## Antes dos fundidos podian pelearse por el mismo valor y el aviso de uno cortaba la espera del otro,
## y se veia un cambio de escena a medio oscurecer (el "glitch" al seguir caminando).
func _fade(target_alpha : float, time : float) -> void :
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(color_rect, "color:a", target_alpha, time)
	_tween.finished.connect(transition_finished.emit)
