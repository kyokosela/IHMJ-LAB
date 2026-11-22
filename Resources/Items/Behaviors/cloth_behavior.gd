extends ItemBehavior
class_name ClothBehavior

@export var preset : SpritePreset
## Completado: arte de esta prenda para las UI (armario, espejo) y su id de outfit ("home", "work"...).
@export var clothing : ClothingData

func can_use(_item: Item) -> bool:
	var player : Player = PlayerManager.player
	return player != null

func use(_item: Item):
	if !can_use(_item): return
	super(_item)
	PlayerManager.player.change_preset(preset)
	# Tutorial: ponerse el uniforme es la tarea CLOTHES de la puerta (igual que COOK al comer, en ingredients.gd).
	if clothing != null and clothing.outfit_id == "work" and TaskManager.is_task_list_active("TUTORIAL_DOOR"):
		TaskManager.done_task("TUTORIAL_DOOR", "CLOTHES")

##### TODO crear un sistema de cambio de sprites del personaje, manejar esto aca
##### Mi idea es que el entity tenga una funcion de swap_sprite o algo y se llame desde aca
##### Se le pasa de referencia el item y el entity se encarga de agarrar la ropa que tiene puesta
##### y cambiarla por esta

#### Otra cosa, al parecer la ropa tendra un sistema de estadisticas o atributos, es decir si mucho
#### frio, una ropa caliente puede hacer que se te quite el frio, tocara hacer sistema de equipamiento
#### gggg roguelike 500 billones