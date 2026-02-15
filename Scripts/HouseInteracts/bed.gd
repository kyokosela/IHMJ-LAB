@tool
extends InteractableAction

@export var bed_type: int = PlayerManager.BED_TYPE.TYPE_C

func custom_execute():
	super()
	
	PlayerManager.sleep("00:00", bed_type)
