extends Node

@export var events : Array[Event] ## lista de eventos, no usar para saber cuales estan activos
var stack_active_events : Array[Event]  ## lista de eventos activos

#region Logic

func _ready() -> void:
	TimeManager.time_changed.connect(check_events)
	TimeManager.day_changed.connect(check_daily_events)

func check_events(_new_time : int) -> void : ## revisa con el cambio del tiempo que eventos disparar o terminar
	for event in events :
		if event.is_enabled == false: 
			continue
		
		if event is not EventScheduled : continue
		if TimeManager.day != event.day and TimeManager.month != event.month: continue
		if TimeManager.is_time_between(event.get_formated_start(), event.get_formated_end()):
			event.execute()
			if event.end_hour != -1 or event.end_minute != -1:
				TimeManager.connect_to_time(event.get_formated_end(), event.finished)

func check_daily_events(_new_day : int) -> void :
	for event in events :
		if event is not EventDaily: return
		event.checked = false

#endregion

#region API

## Carga un evento, usa trigger para disparar sus acciones
func load_event(event : Event, trigger : bool = false) -> void :
	events.append(event)
	if event.destroy_at_end: 
		event.event_finished.connect(remove_event.bind(event))
	if trigger: event.execute()
	if event is EventScheduled:
		TimeManager.connect_to_time(event.get_formated_end(), event.finished)
	
## remueve un evento, usa end_trigger para disparar su acciones inversas/finales
func remove_event(event : Event, trigger_end : bool = false) -> void :
	if !events.has(event) : 
		printerr(" No exite el evento para eliminar")
		return
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

#endregion
