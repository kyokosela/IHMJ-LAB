extends Node

#this bool can be used in dialogue for manage Mayui movement
var is_dialogue_active: bool = false
var tile_size : Vector2 = Vector2(16,16) # No se si se cambiara o algo por ahora lo dejare aca, si lo cambian, cambien el movement component

#fps, si quieren activar el label de fps
#referenciar a estas variables donde lo vean necesario
var fps: float = 0.0
var show_fps: bool = false

#booleana de seguridad para perminir o no la indexación de código externo
var index_code: bool = false

var create_log : bool = false ## activar si quieren generar logs
var print_mode : bool = true
var log_file_name : String
var is_on_tutorial : bool

func _ready() -> void:
	if create_log :
		var array = Time.get_date_dict_from_system().values() + Time.get_time_dict_from_system().values()
		log_file_name = str("user://log/" + "%s-%s-%s-%s (%sh%sm%ss)" % array) + ".txt"
		setup_log()

func _process(_delta: float) -> void:
	fps = Engine.get_frames_per_second()

#region FILE SYSTEM
func new_game() -> void:
	is_on_tutorial = true
	
	SaveManager.clear()
	
	TaskManager.load_task_list(load("res://Resources/Task/Tutorial/TutorialDoor.tres"))
	EventManager.load_event(load("res://Resources/Events/TutorialEvents/tutorial.tres"), true)
	
	EventManager.create_lapse_event("16:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/smelly.tres")), "AUTO_SMELLY_LAPSE", "SMELLY_TIMER", true)
	EventManager.create_lapse_event("06:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/hunger.tres")), "AUTO_HUNGER_LAPSE", "HUNGER_TIMER", true)
	EventManager.create_lapse_event("16:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/sleepy.tres")), "AUTO_SLEEPY_LAPSE", "SLEEPY_TIMER", true)
	
## Inicia a partir de 1 2
func save_file(slot_id : int) -> void:
	var slot_name = "save_%d" % (slot_id + 1)
	SaveManager.save_to_disk(slot_name)

func load_file(slot_id : int) -> void :
	var slot_name = "save_%d" % (slot_id + 1)
	SaveManager.load_from_disk(slot_name)
#endregion

#region DEBUG SYSTEM
var current_sesion : FileAccess

func setup_log() -> void :
	if !create_log : return
	current_sesion = FileAccess.open(log_file_name, FileAccess.WRITE)
	
	if current_sesion == null:
		printerr("Error crítico: No se pudo crear el archivo de log en ", log_file_name)
		create_log = false #se desactiva el log para evitar errores posteriores
		return
	current_sesion.store_line("LOG " + log_file_name + " Iniciado ")
	current_sesion.seek_end()
	PlayerManager.effect_added.connect(_on_effect_added)
	PlayerManager.effect_removed.connect(_on_effect_removed)
	
func _on_effect_added(_effect: Effect):
	write_line_log("[PlayerManager] -> effect %s was added" % _effect)
	
func _on_effect_removed(_effect: Effect):
	write_line_log("[PlayerManager] -> effect %s was removed" % _effect)

func write_line_log(line : String) -> void : ## escribe una linea a registrar en el log
	if !create_log : return
	var time = Time.get_ticks_msec()
	current_sesion.seek_end()
	current_sesion.store_line(str("[%s]" % time, " | " ,line))
	if print_mode : print(line)
	
#endregion

#region UTILS
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST :
		if create_log and current_sesion != null:
			write_line_log("END CORRECTLY")
			current_sesion.close()
			current_sesion = null

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build(): return
	
	if event.is_action_pressed("debug_save"):
		print("saving...")
		save_file(0)
		
	if event.is_action_pressed("debug_load"):
		print("loading...")
		load_file(0)
		get_tree().reload_current_scene()
		
	if event.is_action_pressed("debug_print_save_runtime"):
		print("printing...")
		SaveManager.debug_print()
#endregion
