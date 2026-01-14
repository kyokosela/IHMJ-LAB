@tool
extends InteractableAction

func custom_execute():
	super()
	
	PlayerManager.sleep("01:00")
