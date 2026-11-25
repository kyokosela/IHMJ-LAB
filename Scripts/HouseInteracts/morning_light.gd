extends Node2D
## El cuarto a oscuras en la manana del tutorial, con la luz que entra por la puerta del balcon (Flow de juego). Se apaga la
## primera vez que Mayui sale de casa. Cuanto se oscurece: el color del nodo "Oscuridad".

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")

func _ready() -> void:
	_update()

func _process(_delta: float) -> void:
	_update()

func _update() -> void:
	visible = ExitDoor.in_tutorial_morning()
