extends SceneTree
## Prueba de PRINCIPIO A FIN del tutorial de la manana (la meta del proyecto): usa el Apartamento real y las mismas piezas que el
## jugador (puerta con las frases del guion, ducha, armario, cocina con "Esperar", comer, espejo) y sale al lobby, donde espera
## el casero.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_tutorial.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

## Una baldosa del cuarto sin nada alrededor (ver Tools/probar_cuarto.gd).
const NEUTRO := Vector2(104, 72)

var pm
var gm
var tm
var zm
var tk
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
	var guardia := create_timer(240.0)
	guardia.timeout.connect(func(): print("  FALLA: la prueba se colgo (240 s)"); quit(2))
	pm = root.get_node("PlayerManager")
	gm = root.get_node("GameManager")
	tm = root.get_node("TimeManager")
	zm = root.get_node("ZoneManager")
	tk = root.get_node("TaskManager")
	dlg = root.get_node("Dialogic")
	await create_timer(0.3).timeout
	dlg.Text.text_started.connect(func(info) -> void: dichos.append(str(info.get("text", ""))))
	await _t_manana()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
## Espera a que no haya ningun dialogo en curso: lo pasa con Z como el jugador. Solo si no avanza (el del casero tiene
## opciones) lo cierra a la fuerza; cerrar a la fuerza a media frase deja a Dialogic sin pasar el dialogo siguiente.
func _calma() -> void:
	var tranquilo := 0
	var pulsaciones := 0
	for i in 40:
		await create_timer(0.15).timeout
		if dlg.current_timeline != null:
			tranquilo = 0
			if pulsaciones < 10:
				pulsaciones += 1
				await _pulsar_z()
			else:
				dlg.end_timeline()
		else:
			tranquilo += 1
			if tranquilo >= 3:
				return

## Hace algo y devuelve lo que Mayui dice (hasta 2 s). El dialogo queda abierto.
func _decir(accion: Callable) -> String:
	await _calma()
	dichos.clear()
	accion.call()
	for i in 20:
		await create_timer(0.1).timeout
		if not dichos.is_empty():
			break
	return " ".join(dichos)

## Pulsa la tecla Z como el jugador (la misma que interactua y que pasa los dialogos).
func _pulsar_z() -> void:
	for presionada in [true, false]:
		var tecla := InputEventKey.new()
		tecla.keycode = KEY_Z
		tecla.physical_keycode = KEY_Z
		tecla.pressed = presionada
		Input.parse_input_event(tecla)
		await process_frame

## Como el jugador: pulsa Z y sigue pulsando hasta que se cierre el dialogo. Devuelve las lineas oidas.
func _hablar_con_z() -> Array:
	return await _hablar(_pulsar_z)

## Hace algo (pulsar Z, clic en el armario...), pasa con Z todo lo que se diga y devuelve las lineas oidas.
func _hablar(accion: Callable) -> Array:
	dichos.clear()
	await accion.call()
	await create_timer(0.8).timeout
	for i in 14:
		if dlg.current_timeline == null:
			break
		await _pulsar_z()
		await create_timer(0.8).timeout
	await create_timer(0.5).timeout
	return dichos.map(func(linea: String) -> String: return linea.strip_edges())

func _poner(pos: Vector2) -> void:
	pm.player.movement.tile_destination = pos
	pm.player.global_position = pos

## Pone a Mayui en una baldosa mirando hacia un lado: como queda al llegar junto a un mueble.
func _junto(pos: Vector2, mirando: Vector2) -> void:
	_poner(pos)
	pm.player.set_facing_direction(mirando)

func _clic() -> InputEventMouseButton:
	var c := InputEventMouseButton.new()
	c.button_index = MOUSE_BUTTON_LEFT
	c.pressed = true
	return c

func _vestir(casa: Node, prenda: String) -> void:
	var armario = casa.get_node("UILayer/WardrobeUI")
	armario.changing_seconds = 0.05
	armario.fade_seconds = 0.0
	armario.open()
	armario._on_garment_input(_clic(), prenda)
	await create_timer(0.4).timeout
	armario.close()

## Pone a Mayui al lado de una puerta y camina contra ella con la tecla de verdad (lado: hacia donde esta la puerta).
func _empujar_puerta(puerta: Node, lado: Vector2) -> void:
	_junto(puerta.global_position - lado * 16, lado)
	await create_timer(0.2).timeout
	var tecla : String = {Vector2.UP: "move_up", Vector2.DOWN: "move_down", Vector2.LEFT: "move_left", Vector2.RIGHT: "move_right"}[lado]
	Input.action_press(tecla)
	await create_timer(0.2).timeout
	Input.action_release(tecla)

## Camina contra una puerta y espera a llegar a la zona.
func _cruzar(puerta: Node, lado: Vector2, zona: int) -> bool:
	await _empujar_puerta(puerta, lado)
	return await _llegar(zona)

## Espera a que Mayui este en la zona pedida y ya pueda moverse.
func _llegar(zona: int) -> bool:
	for i in 80:
		await create_timer(0.1).timeout
		if zm.zone_node != null and is_instance_valid(zm.zone_node) and zm.zone_node.zone_id == zona and not zm._changing_zone:
			return true
	return false

## La pantalla de la alarma de dormir, si esta abierta.
func _buscar_alarma() -> Node:
	for capa in root.get_children():
		var ui : Node = capa.get_node_or_null("AlarmUI")
		if ui != null and not ui.is_queued_for_deletion():
			return ui
	return null

## Las filas de la lista de tareas en pantalla; la resaltada como siguiente lleva un * al final.
func _filas(ayudas: Node) -> Array:
	var filas : Array = []
	for fila : Label in ayudas.task_rows.get_children():
		if fila.visible:
			var siguiente : bool = fila.get_theme_color("font_color") == ayudas.NEXT_COLOR
			filas.append(fila.text + ("*" if siguiente else ""))
	return filas

func _tarea(id: String) -> bool:
	return tk.get_task_list_res("TUTORIAL_DOOR").get_task_res(id).task_done

# ------------------------------------------------------------------ la manana completa
func _t_manana() -> void:
	print("A. Despertar y la puerta antes de ducharse")
	gm.game_started = false
	zm.previous_zone = -1
	var casa : Node = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	dichos.clear()
	root.add_child(casa)
	current_scene = casa
	await create_timer(1.5).timeout
	_check("La partida empieza a las 06:00 con Mayui en ropa de casa", tm.get_current_time() == "06:00" and pm.get_outfit_id() == "home", tm.get_current_time())
	_check("Al levantarse Mayui dice 'Tengo que ducharme.'", " ".join(dichos).contains("Tengo que ducharme."), str(dichos))
	_check("Despierta Maloliente y con Hambre", pm.has_effect("SMELLY") and pm.has_effect("HUNGER"))
	await _calma()
	var ayudas = root.get_node("PlayerUI/TutorialHud")
	_check("La manana empieza a oscuras", casa.get_node("Madrugada").visible)
	await process_frame
	_check("Arriba a la derecha: la lista de tareas, con la ducha como siguiente", ayudas.tasks_panel.visible and _filas(ayudas) == ["[  ] Asearse*", "[  ] Ponerse el uniforme", "[  ] Preparar algo de comer", "[  ] Lavarse los dientes", "[  ] Salir a trabajar"], str(_filas(ayudas)))
	_check("Abajo: como moverse y a donde ir", ayudas.walk_panel.visible and ayudas.walk_label.text.begins_with("Muévete"), ayudas.walk_label.text)
	_junto(Vector2(104, 104), Vector2.DOWN)   # encima de la cama, mirandola
	await create_timer(0.5).timeout
	var cama = casa.get_node("Bed")
	_check("Al acercarse a algo sale un punto sobre ello (y la ayuda explica Z una vez)", cama.interact_mark.visible and ayudas.walk_label.text.contains("Z (o Enter)") and ayudas.walk_label.text.contains("punto"), ayudas.walk_label.text)
	var volver : Array = []
	for i in 5:
		volver.append_array(await _hablar_con_z())
	_check("No se puede volver a la cama: tus 3 frases y el aviso (se repite)", volver == ["Si vuelvo ahí, no salgo.", "Cinco minutos más nunca son cinco minutos.", "Después del trabajo… tal vez.", "Debo dejar de perder el tiempo. Voy a llegar tarde.", "Debo dejar de perder el tiempo. Voy a llegar tarde."], str(volver))
	_check("...sin abrir la alarma ni pasar el tiempo", _buscar_alarma() == null and gm.modal_count == 0 and tm.get_current_time() == "06:00" and not pm.slept_today, tm.get_current_time())
	_poner(NEUTRO)
	await create_timer(0.3).timeout
	var puerta = casa.get_node("MainDoor")
	# la puerta de la casa cargada en cada momento (al pasar por el bano el cuarto se vuelve a cargar)
	var abrir := func() -> void: zm.zone_node.get_node("MainDoor").execute()
	# primera vez: caminando de verdad contra la puerta
	var dicho : String = await _decir(func() -> void: await _empujar_puerta(puerta, Vector2.UP))
	_check("Caminar a la puerta: dice '...' y no sale", dicho.strip_edges() == "..." and zm.zone_node == casa, dicho)
	await _calma()
	_poner(NEUTRO)
	await create_timer(0.3).timeout
	var esperadas := ["No puedo salir así.", "Voy a llegar tarde. Debería apresurarme.", "Debo ir a bañarme.", "Debo ir a bañarme.", "Debo ir a bañarme."]
	var oidas := []
	for i in esperadas.size():
		oidas.append((await _decir(abrir)).strip_edges())
	_check("Insistiendo dice tus frases de la ducha en orden y luego el aviso", oidas == esperadas, str(oidas))
	var antes : String = tm.get_current_time()
	var siempre := []
	for i in 3:
		siempre.append((await _decir(abrir)).strip_edges())
	await _calma()
	_check("Si sigue insistiendo la puerta repite el aviso (no se queda muda), sin gastar mas tiempo", siempre == ["Debo ir a bañarme.", "Debo ir a bañarme.", "Debo ir a bañarme."] and tm.get_current_time() == antes and puerta.can_interact, "%s, %s -> %s" % [str(siempre), antes, tm.get_current_time()])

	print("B. Armario antes de ducharse, ducha y uniforme")
	await _calma()
	var mueble = casa.get_node("Wardrobe")
	var armario = casa.get_node("UILayer/WardrobeUI")
	armario.changing_seconds = 0.05
	armario.fade_seconds = 0.0
	var antes_de_ducha : Array = []
	for i in 4:
		antes_de_ducha.append_array(await _hablar(func() -> void: mueble.execute()))
	_check("Antes de ducharse el armario no se abre y dice tus frases (la ultima se repite)", not armario.visible and antes_de_ducha == ["Primero debería ducharme.", "No voy a ponerme ropa estando así.", "No perder el tiempo aquí.", "No perder el tiempo aquí."], str(antes_de_ducha))
	await _calma()
	_check("La puerta del bano lleva al bano", await _cruzar(casa.get_node("DoorToBathroom"), Vector2.LEFT, 4))
	casa = zm.zone_node
	await _calma()
	_junto(Vector2(40, 8), Vector2.LEFT)   # junto a la ducha
	await create_timer(0.5).timeout
	var escena : Control = casa.get_node("UILayer/ShowerScene")
	var vista : Array = []   # por cada linea de la ducha: [linea, ¿se esta viendo la escena sin irse?]
	var anotar := func(info) -> void: vista.append([str(info.get("text", "")).strip_edges(), escena.visible and not escena._closing])
	dlg.Text.text_started.connect(anotar)
	var oido : Array = await _hablar_con_z()
	dlg.Text.text_started.disconnect(anotar)
	_check("La escena de la ducha (silueta tras la cortina) se ve con 'Que frio.' y el estornudo, y se va despues", vista.size() >= 3 and vista[0] == ["Qué frío.", true] and vista[1] == ["¡Achuu!", true] and vista[2] == ["...", false] and not escena.visible and gm.modal_count == 0, "%s visible=%s modal=%d" % [str(vista), escena.visible, gm.modal_count])
	_check("Sale de la ducha mirando hacia abajo", pm.player.movement.last_facing_dir == Vector2.DOWN and not casa.get_node("Shower").is_inside, str(pm.player.movement.last_facing_dir))
	_check("La ducha queda hecha y Mayui sale en toalla", _tarea("BATHE") and pm.get_outfit_id() == "towel")
	_check("La ducha quita Maloliente; la lista tacha asearse y marca el uniforme", not pm.has_effect("SMELLY") and _filas(ayudas)[0] == "[x] Asearse" and _filas(ayudas)[1] == "[  ] Ponerse el uniforme*", str(_filas(ayudas)))
	_check("Primera ducha con Z: tus lineas en orden, una vez", oido == ["Qué frío.", "¡Achuu!", "...", "Debería ir a cambiarme si no quiero morir congelada.", "Espero que mi uniforme esté limpio, no recuerdo si lo lavé."], str(oido))
	_junto(Vector2(40, 8), Vector2.LEFT)   # se vuelve a girar hacia la ducha
	await create_timer(0.3).timeout
	var insistencia : Array = []
	for i in 4:
		insistencia.append_array(await _hablar_con_z())
	_check("Insistiendo en la ducha: tus 3 frases y el aviso", insistencia == ["Ya estoy limpia.", "El agua no es gratis.", "No necesito otra.", "Realmente debería salir de acá para poder cambiarme."], str(insistencia))
	oido = await _hablar_con_z()
	_check("Despues del aviso la ducha ya no contesta", oido.is_empty(), str(oido))
	_check("Del bano se vuelve al cuarto", await _cruzar(casa.get_node("DoorToApartment"), Vector2.RIGHT, 0))
	casa = zm.zone_node
	mueble = casa.get_node("Wardrobe")
	armario = casa.get_node("UILayer/WardrobeUI")
	armario.changing_seconds = 0.05
	armario.fade_seconds = 0.0
	puerta = casa.get_node("MainDoor")
	await _calma()
	_poner(NEUTRO)
	await create_timer(0.3).timeout
	dicho = await _decir(abrir)
	_check("En toalla la puerta dice 'Ni loca.'", dicho.strip_edges() == "Ni loca.", dicho)
	await _calma()
	mueble.can_interact = true
	mueble.execute()
	_check("Ya duchada, el armario se abre", armario.visible)
	var pijama : Array = []
	for i in 5:
		pijama.append_array(await _hablar(func() -> void: armario._on_garment_input(_clic(), "home")))
	_check("En el tutorial la pijama no se pone: tus 3 frases y el aviso", pm.get_outfit_id() == "towel" and pijama == ["Me encantaría volver a dormir, pero las facturas no se pagan solas.", "Resiste, Mayui, debes ser fuerte.", "Que no.", "Voy a llegar tarde.", "Voy a llegar tarde."], str(pijama))
	var uniforme : Array = await _hablar(func() -> void: armario._on_garment_input(_clic(), "work"))
	_check("Al ponerse el uniforme: tus frases y el estomago", pm.get_outfit_id() == "work" and uniforme == ["Huele bien, parece que no se me olvidó lavarlo.", "(Le ruge el estómago.)", "Es verdad, ayer no cené por estar organizando mis cosas...", "Nadie me advirtió que mudarse era tan complicado."], str(uniforme))
	await create_timer(0.1).timeout
	_check("En el armario no sale la lista ni otra ayuda (ya trae la suya)", not ayudas.tasks_panel.visible and not ayudas.mouse_panel.visible)
	armario.close()
	_check("El armario se cierra y Mayui queda libre", not armario.visible and gm.modal_count == 0)
	dicho = await _decir(abrir)
	_check("Vestida y sin comer: 'Debería comer algo.'", dicho.strip_edges() == "Debería comer algo.", dicho)

	print("C. Cocinar y comer")
	await _calma()
	var cocina = casa.get_node("Kitchen")
	var ui = casa.get_node("UILayer/KitchenMultiUI")
	cocina.can_interact = true
	cocina.execute()
	await create_timer(0.1).timeout
	_check("En la cocina: como usar el raton y como comer", ayudas.mouse_panel.visible and not ayudas.tasks_panel.visible and ayudas.mouse_label.text.contains("clic derecho"), ayudas.mouse_label.text)
	var kc = cocina.container
	var inv = kc.inventory
	var bolsa := -1
	var olla := -1
	for i in kc.get_storage_indices():
		if inv.slots[i].is_empty():
			continue
		if inv.slots[i].item.data.item_unique_name == "ingredients_bag" and bolsa == -1:
			bolsa = i
		if inv.slots[i].item.data.item_unique_name == "cooking_pot":
			olla = i
	var tabla : int = kc.get_station_slot_index("cutting")
	var estufa : int = kc.get_station_slot_index("stove")
	var entradas : Array = kc.get_simple_craft_input_indices()
	inv.interact_inventory(tabla, inv, bolsa)
	ui.station_craft_buttons["cutting"].pressed.emit()
	inv.interact_inventory(entradas[0], inv, olla)
	inv.interact_inventory(entradas[1], inv, tabla)
	ui.craft_button.pressed.emit()
	inv.interact_inventory(estufa, inv, kc.get_simple_craft_result_index())
	ui.station_craft_buttons["stove"].pressed.emit()
	ui.station_wait_buttons["stove"].pressed.emit()
	await create_timer(0.2).timeout
	ui.wait_dialog.get_ok_button().pressed.emit()
	await _calma()
	var manos = pm.player.inventory
	var mano : int = manos.get_hands_indices()[0]
	manos.inventory.interact_inventory(mano, inv, estufa)
	ui.close()
	manos.use_item_at(mano)
	await _calma()
	_check("Cocinar con 'Esperar' y comer completa la tarea de comer", _tarea("COOK") and pm.daily.home_meals == 1)
	_check("Comer quita el Hambre", not pm.has_effect("HUNGER"))
	dicho = await _decir(abrir)
	_check("Comida y sin cepillarse: 'Me lavaré la boca antes de salir.'", dicho.strip_edges() == "Me lavaré la boca antes de salir.", dicho)

	print("D. Cepillarse, salir y el casero")
	await _calma()
	_check("Vuelve al bano a cepillarse", await _cruzar(casa.get_node("DoorToBathroom"), Vector2.LEFT, 4))
	casa = zm.zone_node
	await _calma()
	var lavamanos = casa.get_node("Sink")
	lavamanos.can_interact = true
	lavamanos.execute()
	var espejo = casa.get_node("UILayer/MirrorUI")
	espejo.brush_seconds = 0.1
	espejo._on_hit_input(_clic(), "brush")
	await create_timer(0.4).timeout
	espejo.close()
	await _calma()
	_check("Cepillarse completa la ultima tarea", _tarea("TEETH") and tk.is_task_list_done("TUTORIAL_DOOR"))
	_check("Sale del bano", await _cruzar(casa.get_node("DoorToApartment"), Vector2.RIGHT, 0))
	casa = zm.zone_node
	puerta = casa.get_node("MainDoor")
	await _calma()
	await _vestir(casa, "home")
	_check("En la manana del tutorial no se puede volver a la pijama", pm.get_outfit_id() == "work")
	await _calma()
	dicho = await _decir(abrir)
	_check("Con la rutina completa: 'Aquí vamos.'", dicho.strip_edges() == "Aquí vamos.", dicho)
	_check("Mientras lo dice, el cuarto sigue a oscuras (la luz no cambia de golpe)", casa.get_node("Madrugada").visible)
	var hora_salida : String = tm.get_current_time()
	var despues : Array = []
	dlg.Text.text_started.connect(func(info) -> void: despues.append(str(info.get("text", "")).strip_edges()))
	dichos.clear()
	dlg.end_timeline()
	_check("...y sale al pasillo", await _llegar(6))
	await create_timer(0.1).timeout
	_check("Fuera de casa se apagan las ayudas del tutorial", not ayudas.tasks_panel.visible and not ayudas.walk_panel.visible and not ayudas.mouse_panel.visible)
	_check("Sale antes de la hora de entrada al trabajo (08:00)", tm.minutes < 8 * 60, "salio a las " + hora_salida)
	_check("Las escaleras bajan a la recepcion", await _cruzar(zm.zone_node.get_node("Stairs"), Vector2.LEFT, 1))
	var casero := false
	for i in 40:
		await create_timer(0.1).timeout
		if dlg.current_timeline != null and str(dlg.current_timeline.resource_path).contains("casero_intro"):
			casero = true
			break
	_check("En el lobby el casero la intercepta", casero)
	await _calma()
	print("   (hora de salida: %s)" % hora_salida)

	print("E. Volver a casa")
	zm.change_zone(0)
	_check("(prueba) vuelve al apartamento", await _llegar(0))
	casa = zm.zone_node
	await _calma()
	await create_timer(2.5).timeout
	_check("Al volver se queda en casa (la puerta no la saca sola)", zm.zone_node == casa and not zm._changing_zone)
	_check("Despues del tutorial el cuarto ya no esta a oscuras ni salen las ayudas", not casa.get_node("Madrugada").visible and not ayudas.tasks_panel.visible)
	casa.get_node("UILayer/WardrobeUI").fade_seconds = 0.0
	casa.get_node("Wardrobe").can_interact = true
	casa.get_node("Wardrobe").execute()
	await _vestir(casa, "home")
	_check("Despues del tutorial el armario es libre: se puede poner la pijama", pm.get_outfit_id() == "home")
	await _calma()
	var cama2 = casa.get_node("Bed")
	cama2.can_interact = true
	cama2.execute()
	await create_timer(0.4).timeout
	var alarma : Node = _buscar_alarma()
	_check("Despues del tutorial la cama deja dormir (abre la alarma)", alarma != null and gm.modal_count == 1)
	if alarma != null:
		alarma.get_node("Center/Panel/VBox/Margin/Inner/Buttons/CancelButton").pressed.emit()
	await _calma()
	dichos.clear()
	var sale : bool = await _cruzar(casa.get_node("MainDoor"), Vector2.UP, 6)
	_check("Despues del tutorial caminar a la puerta deja salir directo, sin frases", sale and not " ".join(dichos).contains("Aquí vamos."), str(dichos))
	await _calma()
	_check("Una vez fuera, Mayui ya no dice que va tarde", not (despues.has("Voy tarde.") or despues.has("Debería apresurarme.") or despues.has("No tengo todo el día.")), str(despues))
