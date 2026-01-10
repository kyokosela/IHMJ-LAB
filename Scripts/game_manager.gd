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
		log_file_name = str("res://log/" + "%s-%s-%s-%s (%sh%sm%ss)" % array) + ".txt"
		setup_log()

func _process(_delta: float) -> void:
	fps = Engine.get_frames_per_second()

#region FILE SYSTEM

# FILE  CONTROL
const SAVE_PATHS : Array[String] = [
	"user://saves/save1.sv",
	"user://saves/save2.sv",
	"user://saves/save3.sv"
]

var file_count = 0
var current_file_path : String
var game_data : Dictionary

func new_game() -> void :
	#TODO creacion de archivos
	is_on_tutorial = true
	TaskManager.load_task_list(load("res://Resources/Task/Tutorial/TutorialDoor.tres"))
	EventManager.load_event(load("res://Resources/Events/TutorialEvents/tutorial.tres"), true)
	
	EventManager.create_lapse_event("16:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/smelly.tres")), "AUTO_SMELLY_LAPSE", "SMELLY_TIMER", true)
	EventManager.create_lapse_event("06:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/hunger.tres")), "AUTO_HUNGER_LAPSE", "HUNGER_TIMER",true)
	EventManager.create_lapse_event("03:00", print.bind("hola"), "SEX", "SEX", true, false, false)
	
func load_file(save_id : int) -> void : ## MAX 2 en el parametro
	var file = FileAccess.open(SAVE_PATHS[save_id], FileAccess.READ)
	var data : Dictionary = file.get_var(true)
	if data.is_empty() :
		game_data = {
		}
	file.close()

func save_file(save_id : int) -> void :
	if game_data.is_empty() : return
	var file = FileAccess.open(SAVE_PATHS[save_id], FileAccess.WRITE)
	file.store_var(game_data, true)
	file.close()

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST :
		if create_log and current_sesion != null:
			write_line_log("END CORRECTLY")
			current_sesion.close()
			current_sesion = null
