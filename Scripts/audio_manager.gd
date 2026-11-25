extends Node

# Drop .ogg (or .wav) files into res://Audio/SFX/ to activate sounds.
# All methods are safe — silent if file is missing.
# Sonidos de la manana del tutorial (Flow de juego.txt): shower (bucle), stomach y morning_ambience (bucle suave).

const SFX_PATH := "res://Audio/SFX/"

const SFX := {
	"click":      "click.ogg",
	"coin":       "coin.ogg",
	"coin_spend": "coin_spend.ogg",
	"sleep":      "sleep_start.ogg",
	"alarm":      "alarm.ogg",
	"correct":    "correct.ogg",
	"wrong":      "wrong.ogg",
	"shower":     "shower.ogg",
	"stomach":    "stomach.ogg",
	"morning":    "morning_ambience.ogg",
}

var _player: AudioStreamPlayer
var _loops: Dictionary = {}   ## clave -> AudioStreamPlayer de los sonidos en bucle que suenan

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

## El archivo del sonido (.ogg o, si no, .wav); null si no esta.
func _stream(sfx_key: String) -> AudioStream:
	if not SFX.has(sfx_key):
		return null
	var path: String = SFX_PATH + String(SFX[sfx_key])
	for candidate in [path, path.get_basename() + ".wav"]:
		if ResourceLoader.exists(candidate):
			return load(candidate)
	return null

func play(sfx_key: String) -> void:
	var stream := _stream(sfx_key)
	if stream == null:
		return
	_player.stream = stream
	_player.play()

## Suena una y otra vez hasta stop_loop(clave). Pedirlo de nuevo mientras suena no lo reinicia.
func play_loop(sfx_key: String) -> void:
	if _loops.has(sfx_key):
		return
	var stream := _stream(sfx_key)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.finished.connect(player.play)
	player.play()
	_loops[sfx_key] = player

func stop_loop(sfx_key: String) -> void:
	if not _loops.has(sfx_key):
		return
	var player: AudioStreamPlayer = _loops[sfx_key]
	_loops.erase(sfx_key)
	player.stop()
	player.queue_free()

func play_click() -> void:   play("click")
func play_coin_gain() -> void:  play("coin")
func play_coin_spend() -> void: play("coin_spend")
func play_sleep() -> void:   play("sleep")
func play_alarm() -> void:   play("alarm")
func play_correct() -> void: play("correct")
func play_wrong() -> void:   play("wrong")
