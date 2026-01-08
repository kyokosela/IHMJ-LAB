extends Resource
class_name Event

signal event_executed
signal event_finished

@export var event_name : String ## Nombre del evento para mostrar en UI, no sirve como identificador, recomiendo usar tr()}
@export var event_unique_name : String ## Nombre unico para referenciar este evento, aqui si no usar tr xd

#region API
@export var is_enabled : bool = true
@export var is_active : bool
@export var can_multiple_active : bool
@export var checked : bool
@export var destroy_at_end : bool
@export var destroy_at_start : bool

func activate() -> void :
	is_enabled = true

func disable() -> void :
	is_enabled = false

func execute() -> void :
	if !is_enabled or (EventManager.is_event_active(event_unique_name) and !can_multiple_active): return
	is_active = true
	EventManager.stack_active_events.append(self)
	event_executed.emit()
	EventManager.event_activated.emit(event_unique_name)

func finished() -> void :
	if !is_enabled or (!EventManager.is_event_active(event_unique_name) and !can_multiple_active): return
	is_active = false
	EventManager.stack_active_events.erase(self)
	event_finished.emit()
	EventManager.event_deactivaded.emit(event_unique_name)

#endregion
