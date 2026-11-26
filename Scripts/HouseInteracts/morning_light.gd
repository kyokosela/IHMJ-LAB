extends Node2D
## El cuarto a oscuras en la manana del tutorial, con la luz que entra por la puerta del balcon (Flow de juego). Deja de
## estar a oscuras la primera vez que Mayui sale de casa: al volver, ya no. Mientras el cuarto sigue en pantalla no se apaga
## (antes cambiaba de golpe al salir, antes del fundido). Cuanto se oscurece: el color del nodo "Oscuridad".

const ExitDoor := preload("res://Scripts/HouseInteracts/exit_door.gd")

func _ready() -> void:
	_update()

func _process(_delta: float) -> void:
	_update()

## Solo enciende: la manana del tutorial puede empezar despues de cargar el cuarto.
func _update() -> void:
	if not visible:
		visible = ExitDoor.in_tutorial_morning()
