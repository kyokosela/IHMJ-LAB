extends ContainerUI
class_name WardrobeUI

var interactable_container : Wardrobe
@export var entity : Entity

#TODO: cambiar el interactable container por inventory container, rellenar el armario segun los items cloth
#del inventory container y manejar el cambio de sprite por el use() del item quizas, 
func open(p_container):
	if !entity._has_sprite() or !p_container: return
	if not visible: visible = true
	interactable_container = p_container
	
	print("olasasa")
	entity.sprite.change_preset(PlayerManager.player.sprite.current_preset)
	
	
