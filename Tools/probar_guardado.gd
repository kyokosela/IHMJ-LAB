extends SceneTree
## Pruebas del guardado (Docs/Design/GUARDADO.md): se guarda solo al despertar de dormir y al cargar vuelve TODO lo de ese
## momento, como al abrir el juego (despues de new_game()). Usa la cama, el reloj, la cocina y los managers REALES.
## Uso (desde la carpeta del proyecto; ~40 s):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_guardado.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla. Usa su propia ranura: no toca la partida guardada del jugador.

const RANURA := 98            ## GameManager.save_file(98) -> user://saves/save_99.res
const NOMBRE := "save_99"
const INNER := "Center/Panel/VBox/Margin/Inner"

var pm
var tm
var gm
var evm
var zm
var cm
var eco
var att
var tkm
var nf
var Sm          ## SaveManager (se carga en marcha: nombrar clases del juego aqui las compila antes que los autoloads)
var ItemCls
var passed := 0
var failed := 0

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	create_timer(240.0, true, false, true).timeout.connect(func(): print("  FALLA: la prueba se colgo (240 s)"); quit(2))
	pm = root.get_node("PlayerManager")
	tm = root.get_node("TimeManager")
	gm = root.get_node("GameManager")
	evm = root.get_node("EventManager")
	zm = root.get_node("ZoneManager")
	cm = root.get_node("ContainerManager")
	eco = root.get_node("EconomyManager")
	att = root.get_node("AttendanceManager")
	tkm = root.get_node("TaskManager")
	nf = root.get_node("NarrativeFlags")
	await create_timer(0.3).timeout
	Sm = load("res://Scripts/save_manager.gd")
	ItemCls = load("res://Resources/Items/item.gd")
	Engine.time_scale = 30.0   # los fundidos de dormir duran 3 + 3 s
	if "reinicio" in OS.get_cmdline_user_args():
		await _reinicio_hijo()
		return
	gm.new_game()
	if "save_slot" in gm:
		gm.save_slot = RANURA
	Sm.delete_save(NOMBRE)

	var antes : Dictionary = await _t_dormir_guarda()
	await _t_cargar(antes)
	await _t_cocina()
	var guardado : Dictionary = await _t_paso_por_la_oficina()
	_t_reiniciar(guardado)

	Sm.delete_save(NOMBRE)
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
func _item(ruta: String):
	return ItemCls.new(load(ruta))

func _buscar_alarma() -> Node:
	for capa in root.get_children():
		var ui : Node = capa.get_node_or_null("AlarmUI")
		if ui != null and not ui.is_queued_for_deletion():
			return ui
	return null

func _esperar(cond: Callable, segundos: float = 5.0) -> void:
	var limite : int = Time.get_ticks_msec() + int(segundos * 1000)
	while not cond.call() and Time.get_ticks_msec() < limite:
		await process_frame

## Todo lo que el guardado debe recuperar, como texto para comparar.
func _foto() -> Dictionary:
	var f := {}
	f["reloj"] = "dia juliano %d, dia %d, semana %d, %s" % [tm.julian_day, tm.day, tm.week, tm.get_current_time()]
	f["dinero"] = eco.money
	f["asistencia"] = "tardanzas %d, faltas %d, dias %d, descuentos %d" % [att.late_count, att.absence_count, att.days_worked_this_week, att.total_deductions_this_week]
	var stats := []
	for s in pm.stats:
		stats.append("%s=%.2f" % [s.stat_unique_name, s.value])
	stats.sort()
	f["estadisticas"] = ", ".join(stats)
	f["cordura"] = "%.2f (piso %.0f)" % [pm.sanity_value, pm.sanity_floor]
	var efectos := []
	for e in pm.effects:
		var t : String = e.effect_unique_name
		if "days_active" in e:
			t += " nivel %d dias %d" % [e.level, e.days_active]
		if "time" in e and not "days_active" in e:
			t += " " + e.time
		if pm.internal_levels.has(e.effect_unique_name):
			t += " interno %d" % pm.internal_levels[e.effect_unique_name]
		efectos.append(t)
	efectos.sort()
	f["efectos"] = ", ".join(efectos)
	f["habitos de hoy"] = JSON.stringify(pm.daily, "", true)
	f["sueno"] = "durmio %s, deuda %s, noche buena %s, noches buenas %d, insomnio %d/%d/%d" % [pm.slept_today, pm.hour_debt, pm.last_night_proper, pm.proper_nights_in_row, pm.insomnia_days_active, pm.insomnia_bad_sleep_days, pm.insomnia_proper_sleep_streak]
	var ropa := []
	for it in pm.wardrobe:
		ropa.append(pm.outfit_id_of(it))
	f["ropa"] = "lleva %s (limpieza %.1f), colgado %s" % [pm.get_outfit_id(), pm.outfit.get_custom_condition("cleanliness").value, str(ropa)]
	var manos := []
	for it in pm.player.inventory.get_all_player_items():
		manos.append(it.data.item_unique_name + ("(" + it.held_item.data.item_unique_name + ")" if it.held_item != null else ""))
	f["manos"] = str(manos)
	var contadores := []
	var activos := []
	for e in evm.events:
		if "time_lapse_value" in e:
			contadores.append("%s %s" % [e.event_unique_name, e.timer_count if not e.timer_count.is_empty() else e.time_lapse_value])
	for e in evm.stack_active_events:
		activos.append(e.event_unique_name)
	contadores.sort()
	activos.sort()
	f["contadores"] = ", ".join(contadores)
	f["eventos en curso"] = ", ".join(activos)
	var tareas := []
	for tl in tkm.active_tasks:
		for t in tl.task_list:
			tareas.append("%s %s" % [t.task_unique_name, "hecha" if t.task_done else "pendiente"])
	f["tareas"] = ", ".join(tareas)
	var banderas : Array = nf.get_save_data().keys()
	banderas.sort()
	f["banderas"] = str(banderas)
	f["zona"] = zm.current_zone
	return f

func _comparar(antes: Dictionary, despues: Dictionary) -> void:
	for k in antes:
		_check("Vuelve igual: %s" % k, str(antes[k]) == str(despues.get(k)), "\n      antes:   %s\n      despues: %s" % [antes[k], despues.get(k)])

## Carga como Shift+L: los datos y la zona guardada.
func _cargar() -> void:
	if gm.has_method("load_game"):
		gm.load_game(RANURA)
	else:
		gm.load_file(RANURA)
	await create_timer(1.5).timeout

# ------------------------------------------------------------------ A. al dormir se guarda
func _t_dormir_guarda() -> Dictionary:
	print("A. Al despertar de dormir se guarda solo")
	nf.set_flag("tutorial_door_done")
	for t in tkm.get_task_list_res("TUTORIAL_DOOR").task_list:
		t.task_done = true
	tm.add_to_current_time("15:00")   # lunes 21:00 (hambre a las 12:00 y a las 18:00)
	eco.add_money(123, "PRUEBA")
	att.late_count = 1
	pm.sanity_value = 37.0
	pm.get_stat_res("HEALTH").value = 80.0
	pm.get_stat_res("ENERGY").value = 40.0          # minimo de sueno: 8 h
	var estres = pm.EFFECT_STRESS.duplicate()
	pm.add_effect(estres)
	estres.change_level_value(1)
	estres.days_active = 1
	pm.add_effect(load("res://Resources/Effects/Effects/weak.tres"))   # dura 72 h: su contador debe seguir
	pm.wear_clothes(pm.wardrobe[0])                                     # el uniforme
	pm.soil_clothes(30.0)
	var olla = _item("res://Resources/Items/Data/KitchenUtils/cooking_pot.tres")
	olla.held_item = _item("res://Resources/Items/Data/Liquids/water.tres")
	pm.player.inventory.add_to_hands(olla)
	pm.player.inventory.add_to_hands(_item("res://Resources/Items/Data/KitchenUtils/mug.tres"))
	_check("(prueba) no hay partida guardada todavia", not Sm.has_save(NOMBRE))

	pm.request_sleep(0)
	await process_frame
	var ui : Node = _buscar_alarma()
	_check("(prueba) la cama abre la alarma", ui != null)
	if ui != null:
		ui.get_node(INNER + "/Buttons/NoAlarmButton").pressed.emit()
	await _esperar(func() -> bool: return not pm._sleep_in_progress, 30.0)
	_check("(prueba) durmio 8 h: martes 05:00", tm.get_current_time() == "05:00" and int(tm.week_day) == 1, tm.get_current_time())
	_check("Al despertar la partida queda guardada", Sm.has_save(NOMBRE))
	return _foto()

# ------------------------------------------------------------------ B. cargar como al abrir el juego
func _t_cargar(antes: Dictionary) -> void:
	print("B. Cargar como al abrir el juego")
	# "abrir el juego otra vez": partida nueva y todo distinto
	gm.new_game()
	eco.load_save_data({})
	att.load_save_data({})
	nf.load_save_data({})
	pm.reset_engine_state(true)
	pm.player.inventory.inventory.clear()
	for t in tkm.get_task_list_res("TUTORIAL_DOOR").task_list:
		t.task_done = false
	tm.add_to_current_time("30:00")
	_check("(prueba) el estado cambio antes de cargar", str(_foto()) != str(antes))
	await _cargar()
	_comparar(antes, _foto())
	var escena : Node = current_scene
	_check("Despierta en su cuarto, junto a la cama", escena != null and escena.name == "Apartment" and pm.player.global_position.is_equal_approx(Vector2(88, 120)), "%s %s" % [escena.name if escena else "sin escena", pm.player.global_position])
	var olla = pm.player.inventory.get_hand_item(0)
	_check("La olla de las manos conserva el agua (y sus condiciones)", olla != null and olla.held_item != null and olla.held_item.custom_conditions.size() == load("res://Resources/Items/Data/Liquids/water.tres").custom_conditions.size())
	# lo que esta en marcha sigue funcionando despues de cargar
	var dinero : int = eco.money
	var faltas : int = att.absence_count
	var cordura : float = pm.sanity_value
	await process_frame
	_check("Cargar no paga, no anota faltas ni cierra el dia", eco.money == dinero and att.absence_count == faltas and is_equal_approx(pm.sanity_value, cordura))
	# (la Hiperactividad puede haber salido ya al dormir, al azar, por el Estres: lo que no puede es aparecer al cargar)
	var guardados : String = antes.get("efectos", "")
	_check("...ni dispara la Hiperactividad o el Cansancio por la energia", ["HYPERACTIVE", "TIRED"].all(func(n: String) -> bool: return pm.has_effect(n) == (n in guardados)), "\n      al guardar: %s\n      ahora: %s" % [guardados, _foto().get("efectos")])
	pm.remove_effect("HUNGER")
	tm.add_to_current_time("12:00")   # martes 17:00: 12 h despues de despertar
	_check("12 h despues puede volver a dormir (su contador sigue vivo)", not pm.slept_today)
	_check("El hambre llega a su hora (contador de 6 h)", pm.has_effect("HUNGER"))

# ------------------------------------------------------------------ C. la cocina en marcha
func _t_cocina() -> void:
	print("C. La cocina y lo que se esta cocinando")
	var escena : Node = current_scene
	var kc = escena.get_node("Kitchen").container if escena != null and escena.has_node("Kitchen") else null
	_check("(prueba) la cocina del cuarto existe", kc != null)
	if kc == null:
		return
	var inv = kc.inventory
	for i in inv.slots.size():
		inv.slots[i].clear()
	var olla = _item("res://Resources/Items/Data/KitchenUtils/cooking_pot.tres")
	olla.held_item = _item("res://Resources/Items/Data/ingredients_unpack.tres")
	inv.slots[kc.get_station_slot_index("stove")].item = olla
	inv.slots[kc.get_storage_indices()[0]].item = _item("res://Resources/Items/Data/instant_box.tres")
	inv.inventory_changed.emit()
	_check("(prueba) la estufa empieza a cocinar (45 min)", kc.start_manual_station_craft("stove") and kc.is_station_locked("stove"))
	tm.add_to_current_time("00:10")
	gm.save_file(RANURA)   # lo mismo que guarda al dormir (Shift+S)
	# se cambia todo antes de cargar
	evm.remove_event(kc.get_station("stove").active_craft_event)
	kc.get_station("stove").unlock()
	for i in inv.slots.size():
		inv.slots[i].clear()
	await _cargar()
	escena = current_scene
	kc = escena.get_node("Kitchen").container
	inv = kc.inventory
	_check("La estufa sigue cocinando con su olla", kc.is_station_locked("stove") and kc.get_station_item("stove") != null and kc.get_station_item("stove").held_item != null)
	_check("Le quedan 35 min", kc.get_station_time_left("stove") == "00:35", kc.get_station_time_left("stove"))
	var caja = inv.slots[kc.get_storage_indices()[0]].item
	_check("La alacena conserva la comida instantanea", caja != null and caja.data.item_unique_name == "instant_box")
	tm.add_to_current_time("00:35")
	var en_estufa = kc.get_station_item("stove")
	_check("A su hora sale la comida casera", not kc.is_station_locked("stove") and en_estufa != null and en_estufa.held_item != null and en_estufa.held_item.data.item_unique_name == "home_meal")

# ------------------------------------------------------------------ D. el recorrido de Ramiro: oficina, volver y cargar
## Ramiro (2026-11-26): despues de pasar por la oficina, Shift+L se cortaba (un componente de guardado de la escena ya
## cerrada) y no volvia nada. Se recorre con el cambio de zona REAL (bus, fundidos, escenas que se cierran).
func _t_paso_por_la_oficina() -> Dictionary:
	print("D. Ir a la oficina, volver y cargar")
	gm.save_file(RANURA)
	var guardado : Dictionary = _foto()
	for destino in [zm.ZONES.OFFICE, zm.ZONES.APARTMENT, zm.ZONES.OFFICE, zm.ZONES.APARTMENT]:
		zm.change_zone(destino)
		var nombre : String = "Office" if destino == zm.ZONES.OFFICE else "Apartment"
		await _esperar(func() -> bool: return current_scene != null and current_scene.name == nombre and not zm._changing_zone, 20.0)
	_check("(prueba) fue dos veces a la oficina y volvio", current_scene != null and current_scene.name == "Apartment" and eco.money != int(guardado.dinero), "%s S/%d" % [current_scene.name if current_scene else "-", eco.money])
	await _cargar()
	_comparar(guardado, _foto())
	_check("Tras cargar sigue en su cuarto y se puede mover", current_scene != null and current_scene.name == "Apartment" and gm.modal_count == 0)
	# Shift+L estando en la oficina: vuelve a su cuarto con lo guardado
	zm.change_zone(zm.ZONES.OFFICE)
	await _esperar(func() -> bool: return current_scene != null and current_scene.name == "Office" and not zm._changing_zone, 20.0)
	await _cargar()
	_check("Cargar desde la oficina la lleva a su cuarto", current_scene != null and current_scene.name == "Apartment" and gm.modal_count == 0, current_scene.name if current_scene else "-")
	_check("...con lo guardado (dinero, hora y manos)", str(_foto().dinero) == str(guardado.dinero) and _foto().reloj == guardado.reloj and _foto().manos == guardado.manos)
	return guardado

# ------------------------------------------------------------------ E. cargar tras cerrar y abrir el juego (otro proceso)
func _t_reiniciar(guardado: Dictionary) -> void:
	print("E. Cerrar el juego, abrirlo y cargar")
	var salida : Array = []
	var args : PackedStringArray = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s", "res://Tools/probar_guardado.gd", "--", "reinicio"]
	var codigo : int = OS.execute(OS.get_executable_path(), args, salida, true)
	var texto : String = "\n".join(salida)
	var foto := {}
	for linea in texto.split("\n"):
		if linea.begins_with("FOTO "):
			foto = JSON.parse_string(linea.substr(5))
	_check("El juego abierto de nuevo carga sin errores", codigo == 0 and not texto.contains("SCRIPT ERROR") and not foto.is_empty(), "codigo %d\n%s" % [codigo, texto.right(1500)])
	if not foto.is_empty():
		for k in guardado:
			_check("Tras reiniciar vuelve igual: %s" % k, str(guardado[k]) == str(foto.get(k)), "\n      antes:   %s\n      despues: %s" % [guardado[k], foto.get(k)])

## (proceso hijo) Arranca como el juego: la escena principal hace la partida nueva; luego Shift+L.
func _reinicio_hijo() -> void:
	gm.autosave_enabled = false
	gm.save_slot = RANURA
	change_scene_to_file("res://Scenes/World/Apartment.tscn")
	await create_timer(1.5).timeout
	var ok : bool = gm.load_game(RANURA)
	await create_timer(1.5).timeout
	var foto := {}
	var f : Dictionary = _foto()
	for k in f:
		foto[k] = str(f[k])
	print("FOTO " + JSON.stringify(foto))
	quit(0 if ok else 1)
