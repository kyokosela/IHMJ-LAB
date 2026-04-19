@tool
extends InteractableAction

@export var bed_type: int = PlayerManager.BED_TYPE.TYPE_C

func custom_execute():
	super()
	
	PlayerManager.request_sleep(bed_type)
