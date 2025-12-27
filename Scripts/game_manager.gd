extends Node

#this bool can be used in dialogue for manage Mayui movement
var is_dialogue_active: bool = false
var tile_size : Vector2 = Vector2(16,16) # No se si se cambiara o algo por ahora lo dejare aca, si lo cambian, cambien el movement component

var fps: float = 0.0

var create_log : bool = false ## activar si quieren generar logs
var print_mode : bool = true
var log_file_name : String

func _ready() -> void:
	if create_log :
		var array = Time.get_date_dict_from_system().values() + Time.get_time_dict_from_system().values()
		log_file_name = str("res://log/" + "%s-%s-%s-%s (%sh%sm%ss)" % array) + ".txt"
		setup_log()

func _process(_delta: float) -> void:
	fps = Engine.get_frames_per_second()

#region FILE SYSTEM

func new_game() -> void :
	#TODO creacion de archivos
	TimeManager.minutes = 360
	PlayerManager.add_effect(load("res://Resources/Effects/Effects/hunger_level_1.tres"))
	PlayerManager.add_effect(load("res://Resources/Effects/Effects/dirt_level_1.tres"))

#endregion

#region DEBUG SYSTEM

var current_sesion : FileAccess

func setup_log() -> void :
	if !create_log : return
	current_sesion = FileAccess.open(log_file_name, FileAccess.WRITE)
	current_sesion.store_line("LOG " + log_file_name + " Iniciado ")
	current_sesion.close()
	
	PlayerManager.effect_added.connect(func (_effect : Effect) : write_line_log("[PlayerManager] -> effect %s was added" % _effect))
	PlayerManager.effect_removed.connect(func (_effect : Effect) : write_line_log("[PlayerManager] -> effect %s was removed" % _effect))

func write_line_log(line : String) -> void : ## escribe una linea a registrar en el log
	if !create_log : return
	current_sesion = FileAccess.open(log_file_name, FileAccess.WRITE)
	var time = Time.get_ticks_msec()
	current_sesion.store_line(str("[%s]" % time, " | " ,line))
	if print_mode : print(line)
	current_sesion.close()
	
#endregion

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST :
		write_line_log("END CORRECTLY")
