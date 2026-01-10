extends Node

const INIT_EVENTS_FOLDER_PATH : String = "res://Resources/Events/InitialEvents/"

@warning_ignore_start("unused_signal")
signal event_activated(event_name : String)
signal event_deactivaded(event_name : String)
signal event_create(event_name : String)

@export var events : Array[Event] ## lista de eventos, no usar para saber cuales estan activos
var stack_active_events : Array[Event]  ## lista de eventos activos

#region Logic
func _ready() -> void:
	load_default_events()

func load_default_events() -> void :
	for event_res in DirAccess.get_files_at(INIT_EVENTS_FOLDER_PATH):
		if not event_res.ends_with("tres") and not event_res.ends_with("res"):
			continue
		load_event(load(INIT_EVENTS_FOLDER_PATH + event_res), true)
#endregion

#region API
## Carga un evento, usa trigger para disparar sus acciones
func load_event(event : Event, trigger : bool = false) -> void :
	if is_event_exist(event.event_unique_name) : return
	
	events.append(event)
	
	if trigger: event.execute()
	
	if event is EventScheduled:
		
		if event.start != null : TimeManager.connect_with_res(event.start, event.execute)
		if event.end != null : TimeManager.connect_with_res(event.end, event.finished)
	
	if event is LapseEvent :
		TimeManager.minutes_delta.connect(event.check_timer)
	
	event_create.emit(event.event_unique_name)
	
	if event.destroy_at_start:
		event.event_executed.connect(remove_event.bind(event))
	if event.destroy_at_end: 
		event.event_finished.connect(remove_event.bind(event))
	
## remueve un evento, usa end_trigger para disparar su acciones inversas/finales
func remove_event(event : Event, trigger_end : bool = false) -> void :
	if !events.has(event) : 
		printerr(" No exite el evento para eliminar")
		return

	if event is LapseEvent :
		TimeManager.minutes_delta.disconnect(event.check_timer)
	
	event_deactivaded.emit(event.event_unique_name)
	stack_active_events.erase(event)
	events.erase(event)
	if trigger_end :
		event.finished()

## Ejecuta algo al dar inicio un evento
func connect_to_event(event_unique_name : String, callable_to_enter : Callable = func() : return, callable_to_exit : Callable = func () : return) -> void :
	var event = get_event(event_unique_name)
	if event == null: return
	event.event_executed.connect(callable_to_enter)
	event.event_finished.connect(callable_to_exit)

## Devuelve si un evento esta habilitado
func is_enable(_event_unique_name : String) -> bool :
	var event = get_event(_event_unique_name)
	if event == null: return false
	return event.is_enabled

## Obten el recurso "Event" de un evento
func get_event(_event_unique_name : String) -> Event :
	for event in events :
		if event.event_unique_name == _event_unique_name :
			return event
	return null

## Fuerza o instruye el inicio de un evento
func execute_event(_event_unique_name : String) -> void :
	var event = get_event(_event_unique_name)
	if event == null: return
	event.execute()
	if event is EventScheduled :
		TimeManager.connect_to_time(event.end_hour, event.finished)

## Fuerza o instruye el final de un evento
func finish_event(_event_unique_name : String) -> void :
	var event = get_event(_event_unique_name)
	if event == null: return
	event.finished()
 
## Obten si un evento esta en ejecucion
func is_event_active(_event_unique_name : String) -> bool :
	var event = get_event(_event_unique_name)
	if event == null: return false
	return stack_active_events.has(event)

## Obtiene el tiempo restante para iniciar un evento
func get_time_left_to_start(_event_unique_name : String) -> String :
	var event = get_event(_event_unique_name)
	if event == null or event is not EventScheduled: 
		return ""
	return TimeManager.time_left_to(event.hour)

## Establece como hecho un evento
func check_event(_event_unique_name : String) -> void :
	var event = get_event(_event_unique_name)
	if event == null: return
	event.checked = true

## Retorna si un evento esta marcado como hecho
func is_event_check(_event_unique_name : String) -> bool :
	var event = get_event(_event_unique_name)
	if event == null: return false
	return event.checked

func is_event_exist(_event_unique_name : String) -> bool :
	for event in events :
		if event.event_unique_name == _event_unique_name :
			return true
	return false

func create_lapse_event(_time_lapse : String, callable : Callable, event_unique_name : String, event_display_name : String, auto_restart : bool = false, _auto_destroy : bool = false, _auto_start_destroy : bool = false) -> void :
	if is_event_exist(event_unique_name) : return
	var new_lapse_event = LapseEvent.new()
	new_lapse_event.event_name = event_display_name
	new_lapse_event.event_unique_name = event_unique_name
	new_lapse_event.event_executed.connect(callable)
	new_lapse_event.time_lapse_value = _time_lapse
	new_lapse_event.auto_restart = auto_restart
	new_lapse_event.can_multiple_active = true
	new_lapse_event.destroy_at_end = _auto_destroy
	new_lapse_event.destroy_at_start = _auto_start_destroy
	load_event(new_lapse_event, false)

func reset_lapse_event(event_unique_name : String) -> void : ## Asegurate de que el evento sea de tipo LapseEvent
	var event = get_event(event_unique_name)
	if event is not LapseEvent : printerr(" el evento que se quiere resetear no es de tipo LapseEvent");return
	event.reset_lapse()

#endregion
