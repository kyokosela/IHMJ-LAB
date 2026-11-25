extends SceneTree
## Prueba de la "presion temporal" del tutorial: en el Apartamento real el reloj pasa de las 7:30 y Mayui lo va diciendo.
## (Va en su propio archivo porque los eventos con hora solo ocurren una vez por partida.)
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_voy_tarde.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

var gm
var tm
var zm
var dlg
var passed := 0
var failed := 0
var dichos : Array = []

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	var guardia := create_timer(90.0)
	guardia.timeout.connect(func(): print("  FALLA: la prueba se colgo (90 s)"); quit(2))
	gm = root.get_node("GameManager")
	tm = root.get_node("TimeManager")
	zm = root.get_node("ZoneManager")
	dlg = root.get_node("Dialogic")
	await create_timer(0.3).timeout
	dlg.Text.text_started.connect(func(info) -> void: dichos.append(str(info.get("text", "")).strip_edges()))
	await _t_voy_tarde()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

## Pulsa Z como el jugador.
func _pulsar_z() -> void:
	for presionada in [true, false]:
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_Z
		tecla.physical_keycode = KEY_Z
		tecla.pressed = presionada
		Input.parse_input_event(tecla)
		await process_frame

## Pasa con Z lo que se este diciendo.
func _calma() -> void:
	var tranquilo := 0
	for i in 40:
		await create_timer(0.2).timeout
		if dlg.current_timeline != null:
			tranquilo = 0
			await _pulsar_z()
		else:
			tranquilo += 1
			if tranquilo >= 3:
				return

## Mueve el reloj y devuelve lo que Mayui diga en los 2.5 s siguientes.
func _pasar_tiempo(cuanto: String) -> Array:
	dichos.clear()
	tm.add_to_current_time(cuanto)
	await create_timer(2.5).timeout
	return dichos.duplicate()

func _t_voy_tarde() -> void:
	gm.game_started = false
	zm.previous_zone = -1
	var casa : Node = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(casa)
	current_scene = casa
	await create_timer(1.5).timeout
	await _calma()
	var oido : Array = await _pasar_tiempo("01:20")
	_check("A las 07:20 todavia no dice nada", oido.is_empty() and tm.get_current_time() == "07:20", "%s %s" % [tm.get_current_time(), oido])
	oido = await _pasar_tiempo("00:11")
	_check("Pasadas las 07:30: 'Voy tarde.'", oido == ["Voy tarde."], str(oido))
	await _calma()
	oido = await _pasar_tiempo("00:10")
	_check("Pasadas las 07:40: 'Debería apresurarme.'", oido == ["Debería apresurarme."], str(oido))
	await _calma()
	var armario = casa.get_node("UILayer/WardrobeUI")
	armario.open()
	oido = await _pasar_tiempo("00:10")
	_check("Con una pantalla abierta (armario) no interrumpe", oido.is_empty() and armario.visible, str(oido))
	dichos.clear()
	armario.close()
	await create_timer(2.5).timeout
	_check("Al cerrarla: 'No tengo todo el día.'", dichos == ["No tengo todo el día."], str(dichos))
	await _calma()
	oido = await _pasar_tiempo("00:30")
	_check("Despues de la tercera frase no insiste", oido.is_empty(), str(oido))
