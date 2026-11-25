@tool
extends InteractableAction
## La ducha. En el campo "dialog" va lo que Mayui dice la primera vez que se ducha en el tutorial
## (en Apartment.tscn: ducha_tutorial.dtl). Las frases al insistir van en cooldown_timer_message.

func custom_execute() -> void :
	super()
	# Agua fria mientras el tutorial siga en curso (no hay agua caliente "en el momento"); despues, caliente.
	var cold_water : bool = TaskManager.is_task_list_active("TUTORIAL_DOOR") and not TaskManager.is_task_list_done("TUTORIAL_DOOR")
	var first_tutorial_bath : bool = cold_water and not _is_bath_task_done()
	TaskManager.done_task("TUTORIAL_DOOR", "BATHE")
	PlayerManager.remove_effect("SMELLY")
	EventManager.reset_lapse_event("AUTO_SMELLY_LAPSE")
	PlayerManager.register_bath(cold_water)
	# Al salir del bano Mayui queda con la toalla hasta que vaya al armario.
	PlayerManager.wear_towel()
	# La escena de la silueta tras la cortina, si la zona la tiene (UI/Shower en Bathroom.tscn). La primera vez se queda
	# mientras Mayui dice "Que frio."; despues, un par de segundos.
	var ducha = get_tree().get_first_node_in_group("shower_scene")
	if ducha != null:
		ducha.play(first_tutorial_bath and dialog != null)
	if first_tutorial_bath and dialog != null:
		Dialogic.start(dialog)

func _is_bath_task_done() -> bool :
	var tasks : TaskList = TaskManager.get_task_list_res("TUTORIAL_DOOR")
	if tasks == null: return false
	var bath : Task = tasks.get_task_res("BATHE")
	return bath != null and bath.task_done
