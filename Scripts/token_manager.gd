extends Node

signal token_earned
signal token_used

var tokens: int = 0

func check_token_eligibility() -> void:
	if NarrativeFlags.has_flag("token_earned"):
		tokens += 1
		token_earned.emit()

func use_token() -> bool:
	if tokens <= 0:
		return false
	tokens -= 1
	token_used.emit()
	return true

func get_token_count() -> int:
	return tokens

func attempt_ascension() -> void:
	push_warning("TokenManager: Ascension minigame not implemented (post-demo content)")
