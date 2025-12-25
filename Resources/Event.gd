extends Resource
class_name Event

@warning_ignore_start("unused_signal")
signal event_executed
signal event_finished

@export var event_name : String ## Nombre del evento para mostrar en UI, no sirve como identificador, recomiendo usar tr()}
@export var event_unique_name : String ## Nombre unico para referenciar este evento, aqui si no usar tr xd

#region API

@export var is_enabled : bool
@export var is_active : bool
@export var checked : bool

func activate() -> void :
	is_enabled = true

func disable() -> void :
	is_enabled = false

func execute() -> void :
	EventManager.stack_active_events.append(self)
	if !is_enabled : return
	event_executed.emit()

func finished() -> void :
	if !is_enabled : return
	event_finished.emit()

#endregion
