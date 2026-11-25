extends Resource
class_name Task

signal task_finished
signal task_cooldown

@export var task_unique_name : String ## NOMBRE UNICO DE LA TAREA
@export var display_name : String ## Nombre corto en la lista de pantalla (clave de Textfiles/ o texto)
@export var task_message : Array[String] ## Mensajes de "error" o advertencias de las tareas pendientes
@export var task_done : bool ## Bool para saber si la tarea esta realizada, usar set_done si se quiere habilitar, por las señales
@export var cooldown : int = 3 : ## numero de ciclos en antes del cooldown
	set(_value) :
		cooldown = clamp(_value, 0, INF)
@export var spend_time : String = "00:02" ## Tiempo de penalizacion por cada interacción repetida
@export var cooldown_spend_time : String = "00:05" ## Tiempo de penalización al aplicar cooldown
@export var event_dependencies : Array[String] ## Usar nombre unico del evento

var is_cooldown : bool

var message_index : int :
	set(_value) :
		message_index = clamp(_value, 0, task_message.size() - 1)
		if message_index == task_message.size() - 1 :
			if cooldown == 0 and !is_cooldown :
				task_cooldown.emit()
				TimeManager.add_to_current_time(cooldown_spend_time)
				is_cooldown = true
			else :
				TimeManager.add_to_current_time(spend_time)
			cooldown -= 1

func check_events() -> bool :
	if event_dependencies.is_empty() : return true
	for event : String in event_dependencies :
		if !EventManager.is_event_active(event) : return false
	return true

func get_message() -> String :
	if task_message.is_empty() or is_cooldown: return ""
	var message = task_message[message_index]
	message_index += 1
	return message

func set_done() -> void :
	task_done = true
	task_finished.emit()
