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
var game_started : bool = false ## true una vez que new_game() ya corrió; evita reiniciar al recargar escenas
signal input_block_changed(blocked: bool) ## se emite al abrir o cerrar una UI modal (PC, alarma, arcade...)

## > 0 mientras haya una UI modal abierta (alarma de dormir, PC, arcade, mercado...). Quien abre una UI
## hace modal_count += 1 y al cerrarla modal_count -= 1: Mayui se queda quieta y no interactua con el mundo.
var modal_count : int = 0 :
	set(value):
		modal_count = maxi(value, 0)
		input_block_changed.emit(is_input_blocked())

## true si el jugador NO debe poder interactuar con el mundo ahora mismo
## (hay un dialogo en curso o una UI modal abierta).
func is_input_blocked() -> bool:
	return modal_count > 0 or Dialogic.current_timeline != null

func _ready() -> void:
	if create_log :
		var array = Time.get_date_dict_from_system().values() + Time.get_time_dict_from_system().values()
		log_file_name = str("user://log/" + "%s-%s-%s-%s (%sh%sm%ss)" % array) + ".txt"
		setup_log()

func _process(_delta: float) -> void:
	fps = Engine.get_frames_per_second()

#region FILE SYSTEM
func new_game() -> void:
	game_started = true
	is_on_tutorial = true

	SaveManager.clear()
	PlayerManager.reset_engine_state()
	NarrativeFlags.set_flag("has_alarm_clock")  # P13: todo jugador empieza con cama C y despertador
	TimeManager.minutes = 360  # 06:00 (tu guion: la manana en casa va de 6:00 a 8:00)
	PlayerManager.reset_outfits()   # ropa inicial: ropa de casa puesta y el uniforme colgado (despues del reloj: nace limpia)

	TaskManager.load_task_list(load("res://Resources/Task/Tutorial/TutorialDoor.tres"))
	EventManager.load_event(load("res://Resources/Events/TutorialEvents/tutorial.tres"), true)
	
	EventManager.create_lapse_event("24:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/smelly.tres")), "AUTO_SMELLY_LAPSE", "SMELLY_TIMER", true)
	EventManager.create_lapse_event("06:00", PlayerManager.add_effect.bind(load("res://Resources/Effects/Effects/hunger.tres")), "AUTO_HUNGER_LAPSE", "HUNGER_TIMER", true)
	EventManager.create_lapse_event("16:00", PlayerManager.apply_vigil_sleepy, "AUTO_SLEEPY_LAPSE", "SLEEPY_TIMER", true)

	_load_schedule_events()
	_skip_past_events()

## Los eventos del dia actual cuya hora ya paso al iniciar la partida se marcan como ya
## ocurridos. Si no, se disparan todos juntos en el primer cambio de reloj (ej. al ducharse).
## Los eventos que dependen de una zona (NarrativeEventHandler.event_zones, ej. el casero en
## el lobby, programado a las 06:00) NO se saltan: se disparan al primer cambio de reloj y
## quedan pendientes hasta que Mayui llegue a su zona.
func _skip_past_events() -> void:
	for event in EventManager.events:
		if not (event is EventScheduled) or event.start == null:
			continue
		if NarrativeEventHandler.event_zones.has(event.event_unique_name):
			continue
		var config : ScheduleConfig = event.start
		if config.day == TimeManager.day and TimeManager.get_minutes(config.time) <= TimeManager.minutes:
			config.triggered = true

func _load_schedule_events() -> void:
	var schedule_path : String = "res://Resources/Events/Schedule/"
	var dir : DirAccess = DirAccess.open(schedule_path)

	if dir == null:
		push_warning("GameManager: Could not open schedule events directory")
		return

	dir.list_dir_begin()
	var file_name : String = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var event : Resource = load(schedule_path + file_name)
			if event is Event:
				EventManager.load_event(event, false)
		file_name = dir.get_next()

	dir.list_dir_end()
	
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
var _debug_panel : Window

## Abre o cierra el panel de depuracion (UI/Debug/debug_panel.tscn). Se crea la primera vez que se pide,
## asi muestra lo que ya esta activo y sirve en cualquier escena (el Apartamento no lo trae).
func toggle_debug_panel() -> void:
	if _debug_panel == null or not is_instance_valid(_debug_panel):
		_debug_panel = (load("res://UI/Debug/debug_panel.tscn") as PackedScene).instantiate()
		get_tree().root.add_child(_debug_panel)
		return
	_debug_panel.visible = not _debug_panel.visible

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

	# F3: abre/cierra el panel de depuracion (efectos, cordura, reloj) en cualquier escena.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		toggle_debug_panel()
		get_viewport().set_input_as_handled()

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
