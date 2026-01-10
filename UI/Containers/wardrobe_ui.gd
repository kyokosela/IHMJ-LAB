extends ContainerUI
class_name WardrobeUI

var interactable_container : InteractableContainer
@export var entity : Entity

func open(p_interactable_container : InteractableContainer):
	if !entity._has_sprite() or !p_interactable_container: return
	if not visible: visible = true
	interactable_container = p_interactable_container
	var inventory_container = p_interactable_container.container
	
	entity.sprite.change_preset(PlayerManager.player.sprite.current_preset)
