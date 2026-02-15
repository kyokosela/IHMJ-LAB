extends Node

enum BRACELET {
	NONE = 0,
	GREEN = 1,
	YELLOW = 2,
	RED = 3,
	PURPLE = 4
}

var current_bracelet: BRACELET = BRACELET.GREEN

func get_bracelet_name() -> String:
	match current_bracelet:
		BRACELET.NONE:
			return "Ninguno"
		BRACELET.GREEN:
			return "Verde"
		BRACELET.YELLOW:
			return "Amarillo"
		BRACELET.RED:
			return "Rojo"
		BRACELET.PURPLE:
			return "Morado"
	return "Desconocido"

func get_bracelet_floor() -> int:
	match current_bracelet:
		BRACELET.GREEN:
			return 1
		BRACELET.YELLOW:
			return 2
		BRACELET.RED:
			return 3
		BRACELET.PURPLE:
			return 4
	return 0

func can_access_floor(floor_num: int) -> bool:
	return get_bracelet_floor() >= floor_num

func attempt_ascension() -> void:
	push_warning("BraceletManager: Ascension minigame not implemented (post-demo)")
