extends Node

# Drop .ogg files into res://Audio/SFX/ to activate sounds.
# All methods are safe — silent if file is missing.

const SFX_PATH := "res://Audio/SFX/"

const SFX := {
	"click":      "click.ogg",
	"coin":       "coin.ogg",
	"coin_spend": "coin_spend.ogg",
	"sleep":      "sleep_start.ogg",
	"alarm":      "alarm.ogg",
	"correct":    "correct.ogg",
	"wrong":      "wrong.ogg",
}

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)

func play(sfx_key: String) -> void:
	if not SFX.has(sfx_key):
		return
	var path: String = SFX_PATH + String(SFX[sfx_key])
	if not ResourceLoader.exists(path):
		return
	_player.stream = load(path)
	_player.play()

func play_click() -> void:   play("click")
func play_coin_gain() -> void:  play("coin")
func play_coin_spend() -> void: play("coin_spend")
func play_sleep() -> void:   play("sleep")
func play_alarm() -> void:   play("alarm")
func play_correct() -> void: play("correct")
func play_wrong() -> void:   play("wrong")
