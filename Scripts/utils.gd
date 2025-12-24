extends Node
class_name Utils

static func valid_single_dir_vector(vector : Vector2) -> bool: ## Verifica si el vector es de una sola direccion, util para manejar el movimiento por tiles sin diagonales
	if vector == Vector2.UP or vector == Vector2.DOWN or vector == Vector2.LEFT or vector == Vector2.RIGHT:
		return true
	return false
