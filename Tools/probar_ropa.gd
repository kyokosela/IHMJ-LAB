extends SceneTree
## Pruebas automaticas de la ROPA: lo que lleva puesto Mayui, el armario (PlayerManager.outfit / wardrobe), los estados de
## cada prenda (limpia, sucia, mojada), sus efectos en el jugador, su sprite en el mundo (hojas de Assets/Mayui) y la UI del
## armario (mouse, cuadro de cambio, 2 min).
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_ropa.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

var pm
var gm
var tm
var evm
var zm
var passed := 0
var failed := 0

func _check(nombre: String, ok: bool, detalle: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("  FALLA: ", nombre, " ", detalle)

func _initialize() -> void:
	var guardia := create_timer(120.0)
	guardia.timeout.connect(func(): print("  FALLA: la prueba se colgo (120 s)"); quit(2))
	pm = root.get_node("PlayerManager")
	gm = root.get_node("GameManager")
	tm = root.get_node("TimeManager")
	evm = root.get_node("EventManager")
	zm = root.get_node("ZoneManager")
	await create_timer(0.3).timeout
	gm.game_started = true
	_t_modelo()
	_t_estados()
	_t_sprites()
	await _t_ui()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

# ------------------------------------------------------------------ utilidades
func _preset() -> String:
	return pm.player.sprite.current_preset.preset_name

func _prendas() -> Array:
	var todas := []
	if pm.outfit != null and pm.get_outfit_id() != "towel":
		todas.append(pm.get_outfit_id())
	for it in pm.wardrobe:
		todas.append(pm.outfit_id_of(it))
	return todas

func _sin_efectos() -> void:
	for id in ["WEAK", "STRESS", "SMELLY"]:
		pm.remove_effect(id)
	pm.sanity_value = 50.0

# ------------------------------------------------------------------ A. ropa puesta y armario
func _t_modelo() -> void:
	print("A. Ropa puesta y armario")
	pm.reset_outfits()
	_check("Empieza con la ropa de casa puesta", pm.get_outfit_id() == "home" and _preset() == "mayui_home")
	_check("El uniforme cuelga en el armario (y es lo unico)", pm.wardrobe.size() == 1 and pm.outfit_id_of(pm.wardrobe[0]) == "work")
	pm.wear_clothes(pm.wardrobe[0])
	_check("Ponerse el uniforme: lo lleva puesto, cambia su sprite y la ropa de casa cuelga", pm.get_outfit_id() == "work" and _preset() == "mayui_work" and pm.wardrobe.size() == 1 and pm.outfit_id_of(pm.wardrobe[0]) == "home")
	pm.wear_towel()
	_check("Al banarse queda con la toalla y las dos prendas cuelgan", pm.get_outfit_id() == "towel" and _preset() == "mayui_towel" and pm.wardrobe.size() == 2)
	var uniforme = null
	for it in pm.wardrobe:
		if pm.outfit_id_of(it) == "work":
			uniforme = it
	pm.wear_clothes(uniforme)
	_check("Al vestirse la toalla no se guarda en el armario", pm.get_outfit_id() == "work" and pm.wardrobe.size() == 1 and pm.outfit_id_of(pm.wardrobe[0]) == "home")
	# secuencia larga de cambios: siempre las mismas 2 prendas, sin duplicar ni perder
	pm.rng.seed = 7
	var bien := true
	for k in range(60):
		if pm.rng.randf() < 0.3:
			pm.wear_towel()
		elif not pm.wardrobe.is_empty():
			pm.wear_clothes(pm.wardrobe[pm.rng.randi() % pm.wardrobe.size()])
		var ids := _prendas()
		ids.sort()
		if pm.get_outfit_id() == "towel":
			bien = bien and ids == ["home", "work"]
		else:
			bien = bien and ids == ["home", "work"]
	_check("Tras 60 cambios al azar siguen existiendo exactamente la ropa de casa y el uniforme", bien, str(_prendas()))
	pm.reset_outfits()

# ------------------------------------------------------------------ B. estados de la prenda y efectos
func _t_estados() -> void:
	print("B. Estados de la ropa y efectos")
	gm.new_game()
	pm.reset_engine_state(true)
	var casa = pm.outfit
	_check("La ropa nueva esta limpia y seca", casa.has_state("clean") and casa.has_state("dry"))
	for h in range(26):
		tm.minutes_delta.emit(60)
	_check("Tras unas 25 h de uso la ropa puesta se ensucia", pm.outfit.has_state("dirty"))
	_check("La ropa colgada no se ensucia", pm.wardrobe[0].has_state("clean"))
	# arte de cada estado
	for id in ["home", "work"]:
		var c = load("res://Resources/Clothing/%s_clothes.tres" % id)
		var t_limpia = c.get_hanger_texture(false, false)
		var t_sucia = c.get_hanger_texture(true, false)
		var t_mojada = c.get_hanger_texture(false, true)
		var t_ambas = c.get_hanger_texture(true, true)
		_check("'%s': cada estado (limpia, sucia, mojada, mojada y sucia) tiene su propia imagen" % id, t_limpia != null and t_sucia != null and t_mojada != null and t_ambas != null and t_limpia != t_sucia and t_sucia != t_mojada and t_mojada != t_ambas and t_limpia != t_ambas)
		_check("'%s': tiene render, cuadro de cambio y resaltado" % id, c.render != null and c.render_changing != null and c.selection != null)
	# ropa mojada
	pm.reset_outfits()
	pm.wet_clothes()
	_check("Mojar la ropa puesta la deja 'wet'", pm.outfit.has_state("wet"))
	for h in range(8):
		tm.minutes_delta.emit(60)
	_check("Con las horas la ropa se seca", pm.outfit.has_state("dry"))
	# ropa mojada mas de 6 h = Suciedad
	_sin_efectos()
	pm.reset_outfits()
	pm.wet_clothes()
	for h in range(5):
		tm.minutes_delta.emit(60)
	_check("Ropa mojada 5 h: todavia no hay Suciedad", not pm.has_effect("SMELLY"))
	tm.minutes_delta.emit(60)
	_check("Ropa mojada 6 h seguidas: Suciedad (Maloliente)", pm.has_effect("SMELLY"))
	# ropa sucia = el cuerpo se ensucia mas rapido
	_sin_efectos()
	var ev = evm.get_event("AUTO_SMELLY_LAPSE")
	_check("(prueba) existe el temporizador de Suciedad del cuerpo (24 h)", ev != null and ev.time_lapse_value == "24:00")
	pm.reset_outfits()
	evm.reset_lapse_event("AUTO_SMELLY_LAPSE")
	tm.minutes_delta.emit(60)
	var con_limpia : String = ev.timer_count
	pm.reset_outfits()
	pm.soil_clothes(60.0)
	_check("(prueba) soil_clothes deja la ropa sucia", pm.outfit.has_state("dirty"))
	evm.reset_lapse_event("AUTO_SMELLY_LAPSE")
	tm.minutes_delta.emit(60)
	var con_sucia : String = ev.timer_count
	_check("Con ropa limpia pasa 1 h del temporizador de Suciedad y con ropa sucia pasan 2 h", con_limpia == "23:00" and con_sucia == "22:00", "limpia %s, sucia %s" % [con_limpia, con_sucia])
	# ponerse ropa mojada: probabilidad de Debilitamiento y de Estres (con semilla fija)
	pm.rng.seed = 12345
	var debil := 0
	var estres := 0
	for i in range(200):
		_sin_efectos()
		pm.reset_outfits()
		var prenda = pm.wardrobe[0]
		prenda.get_custom_condition("wetness").value = 100.0
		prenda.update_states()
		pm.wear_clothes(prenda)
		if pm.has_effect("WEAK"):
			debil += 1
		if pm.has_effect("STRESS"):
			estres += 1
	_check("Ropa mojada puesta: Debilitamiento algunas veces (~25 %), no siempre ni nunca", debil > 20 and debil < 90, "%d de 200" % debil)
	_check("Ropa mojada puesta: Estres algunas veces", estres > 20, "%d de 200" % estres)
	var seco := 0
	for i in range(100):
		_sin_efectos()
		pm.reset_outfits()
		pm.wear_clothes(pm.wardrobe[0])
		if pm.has_effect("WEAK") or pm.has_effect("STRESS"):
			seco += 1
	_check("Ropa seca puesta: ni Debilitamiento ni Estres", seco == 0, "%d de 100" % seco)
	_sin_efectos()
	pm.reset_outfits()

# ------------------------------------------------------------------ C. sprites de Mayui por ropa
## Cada ropa tiene su sprite en el mundo (Resources/SpriteStacks/Mayui/mayui_<ropa>.tres): hojas de 20 cuadros de 26x32 en
## Assets/Mayui. Cuerpo y piernas son propios de cada ropa; cara, ojos y accesorios son los de siempre y el pelo de la toalla de
## espaldas es mas oscuro (mojado). Las hojas nuevas las arma Tools/armar_hojas_mayui.ps1 desde los .aseprite de tu artista.
func _t_sprites() -> void:
	print("C. Sprites de Mayui por ropa")
	var base := "res://Resources/SpriteStacks/Mayui/"
	var capas := ["accesories", "body", "eyes", "hair", "head", "legs"]
	var presets := {}
	for id in ["work", "home", "towel", "outfit1"]:
		presets[id] = load(base + "mayui_%s.tres" % id)
	var completos := true
	var detalle := ""
	for id in presets.keys():
		var p = presets[id]
		if p.preset_name != "mayui_%s" % id:
			completos = false
			detalle += " nombre(%s)" % id
		for capa in capas:
			var tex : Texture2D = p.layers.get(capa)
			if tex == null or tex.get_width() != 520 or tex.get_height() != 32:
				completos = false
				detalle += " %s/%s" % [id, capa]
	_check("Las 4 ropas (trabajo, casa, toalla y Outfit 1) tienen las 6 capas del sprite, cada una de 20 cuadros de 26x32", completos, detalle)
	var propias := true
	for id in ["home", "towel", "outfit1"]:
		for capa in ["body", "legs"]:
			if presets[id].layers[capa] == presets["work"].layers[capa]:
				propias = false
	_check("La ropa de casa, la toalla y el Outfit 1 ya no usan el cuerpo ni las piernas del uniforme", propias)
	var cuerpos_distintos : bool = presets["home"].layers["body"] != presets["towel"].layers["body"] and presets["home"].layers["body"] != presets["outfit1"].layers["body"] and presets["towel"].layers["body"] != presets["outfit1"].layers["body"]
	_check("Cada ropa tiene su propio cuerpo", cuerpos_distintos)
	var compartidas := true
	for id in ["home", "towel", "outfit1"]:
		for capa in ["accesories", "eyes", "head"]:
			if presets[id].layers[capa] != presets["work"].layers[capa]:
				compartidas = false
	_check("La cara, los ojos y los accesorios son los mismos en todas las ropas", compartidas)
	_check("El pelo es el mismo en todas las ropas, salvo el de la toalla", presets["home"].layers["hair"] == presets["work"].layers["hair"] and presets["outfit1"].layers["hair"] == presets["work"].layers["hair"] and presets["towel"].layers["hair"] != presets["work"].layers["hair"])
	var pelo_normal : Image = (presets["work"].layers["hair"] as Texture2D).get_image()
	var pelo_toalla : Image = (presets["towel"].layers["hair"] as Texture2D).get_image()
	var solo_espalda := true
	for slot in range(20):
		var igual := true
		for y in range(32):
			for x in range(26):
				if pelo_normal.get_pixel(slot * 26 + x, y) != pelo_toalla.get_pixel(slot * 26 + x, y):
					igual = false
		var de_espaldas : bool = slot == 3 or slot >= 16
		if igual == de_espaldas:
			solo_espalda = false
	_check("El pelo mojado de la toalla solo cambia en los cuadros de espaldas (3 y 16 a 19)", solo_espalda)
	var sin_vacios := true
	var vacios := ""
	for id in ["home", "towel", "outfit1"]:
		for capa in ["body", "legs"]:
			var img : Image = (presets[id].layers[capa] as Texture2D).get_image()
			for slot in range(20):
				var n := 0
				for y in range(32):
					for x in range(26):
						if img.get_pixel(slot * 26 + x, y).a > 0.03:
							n += 1
				if n == 0:
					sin_vacios = false
					vacios += " %s/%s/%d" % [id, capa, slot]
	_check("Ningun cuadro del cuerpo ni de las piernas de las hojas nuevas esta vacio", sin_vacios, vacios)
	# en el juego: al ponerse cada ropa, las capas del jugador usan las hojas de esa ropa
	var comp = pm.player.sprite
	var registrados := true
	for id in ["work", "home", "towel", "outfit1"]:
		registrados = registrados and comp.has_preset("mayui_%s" % id)
	_check("El sprite del jugador conoce los 4 presets (trabajo, casa, toalla y Outfit 1)", registrados)
	var nodos_ok := true
	var nodos_detalle := ""
	pm.reset_outfits()
	for id in ["home", "work", "towel", "outfit1"]:
		match id:
			"home":
				pm.reset_outfits()
			"work":
				pm.wear_clothes(pm.wardrobe[0])   # tras reset_outfits lo unico colgado es el uniforme
			"towel":
				pm.wear_towel()
			"outfit1":
				comp.change_preset_by_name("mayui_outfit1")
		for capa in capas:
			if comp.get_node(capa).texture != presets[id].layers[capa]:
				nodos_ok = false
				nodos_detalle += " %s/%s" % [id, capa]
	_check("Al ponerse cada ropa las 6 capas del jugador muestran las hojas de esa ropa", nodos_ok, nodos_detalle)
	pm.reset_outfits()

# ------------------------------------------------------------------ D. UI del armario
func _t_ui() -> void:
	print("D. UI del armario")
	gm.new_game()
	pm.reset_engine_state(true)
	# Aqui se prueba el armario libre: la manana del tutorial (con sus frases y bloqueos) la juega probar_tutorial.gd
	root.get_node("NarrativeFlags").set_flag("tutorial_door_done")
	var tarea = root.get_node("TaskManager").get_task_list_res("TUTORIAL_DOOR").get_task_res("CLOTHES")
	tarea.task_done = false
	zm.previous_zone = -1
	var escena : Node = (load("res://Scenes/World/Apartment.tscn") as PackedScene).instantiate()
	root.add_child(escena)
	await create_timer(1.2).timeout
	var ui = escena.get_node("UILayer/WardrobeUI")
	var casa = load("res://Resources/Clothing/home_clothes.tres")
	var trabajo = load("res://Resources/Clothing/work_clothes.tres")
	_check("El cuadro de cambio de ropa dura 1 s, con transicion al entrar y salir y pausa tras cambiarse", ui.changing_seconds == 1.0 and ui.fade_seconds > 0.0 and ui.settle_seconds >= 0.8)
	ui.changing_seconds = 0.05
	ui.fade_seconds = 0.0
	ui.settle_seconds = 0.0
	_check("El armario empieza cerrado", not ui.visible)
	await _sin_dialogos()   # "Tengo que ducharme.": mientras Mayui habla el armario no atiende clics
	var armario = escena.get_node("Wardrobe")
	armario.can_interact = true
	armario.execute()
	_check("Usar el armario abre la UI y Mayui queda quieta", ui.visible and gm.modal_count == 1)
	_check("Mayui se ve con la ropa de casa y solo cuelga el uniforme", ui.render_rect.texture == casa.render and ui.garment_slots["work"].visible and not ui.garment_slots["home"].visible)
	ui._on_garment_hover("work", true)
	_check("Pasar el mouse sobre el uniforme lo resalta", ui.garment_slots["work"].get_node("Highlight").visible)
	ui._on_garment_hover("work", false)
	_check("Al quitar el mouse se quita el resaltado", not ui.garment_slots["work"].get_node("Highlight").visible)
	var antes : int = tm.get_minutes()
	var clic := InputEventMouseButton.new()
	clic.button_index = MOUSE_BUTTON_LEFT
	clic.pressed = true
	ui._on_garment_input(clic, "work")
	_check("Al hacer clic Mayui muestra el cuadro 'cambiandose' del uniforme", ui._busy and ui.render_rect.texture == trabajo.render_changing)
	ui.close()
	_check("Mientras se cambia no se puede cerrar", ui.visible)
	ui._on_garment_input(clic, "work")
	await create_timer(0.4).timeout
	_check("Despues se ve el render con el uniforme y Mayui lo lleva puesto", not ui._busy and ui.render_rect.texture == trabajo.render and pm.get_outfit_id() == "work" and _preset() == "mayui_work")
	_check("Vestirse tarda 2 minutos", (tm.get_minutes() - antes + 1440) % 1440 == 2, "paso %d" % ((tm.get_minutes() - antes + 1440) % 1440))
	_check("Ponerse el uniforme marca la tarea CLOTHES del tutorial", tarea.task_done)
	_check("Ahora cuelga la ropa de casa y el uniforme ya no", ui.garment_slots["home"].visible and not ui.garment_slots["work"].visible)
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	ui._unhandled_input(esc)
	_check("Esc cierra el armario y Mayui vuelve a moverse", not ui.visible and gm.modal_count == 0)
	# la transicion y la pausa tras cambiarse
	ui.fade_seconds = 0.25
	ui.settle_seconds = 1.0
	armario.can_interact = true
	armario.execute()
	_check("Al entrar oscurece antes de mostrar el armario", not ui.visible and gm.modal_count == 1)
	await create_timer(0.7).timeout
	_check("...y luego se ve, ya aclarado", ui.visible and root.get_node("TransitionManager").color_rect.color.a < 0.05)
	ui._on_garment_input(clic, "home")
	await create_timer(0.2).timeout
	ui._unhandled_input(esc)
	await create_timer(0.1).timeout
	_check("Justo despues de cambiarse Esc espera: se ve la ropa nueva", ui.visible and pm.get_outfit_id() == "home" and ui.render_rect.texture == casa.render)
	await create_timer(1.0).timeout
	ui._unhandled_input(esc)
	await create_timer(0.7).timeout
	_check("Pasada la pausa, Esc sale con la transicion y Mayui queda libre", not ui.visible and gm.modal_count == 0 and root.get_node("TransitionManager").color_rect.color.a < 0.05)
	ui.fade_seconds = 0.0
	ui.settle_seconds = 0.0
	# banarse -> toalla -> armario (la ducha esta en el bano: se trae solo ese nodo, sin cambiar de zona)
	var bano : Node = (load("res://Scenes/World/Bathroom.tscn") as PackedScene).instantiate()
	var ducha : Node = bano.get_node("Shower")
	bano.remove_child(ducha)
	bano.free()
	escena.add_child(ducha)
	ducha.custom_execute()
	_check("Al banarse Mayui queda con la toalla", pm.get_outfit_id() == "towel")
	armario.can_interact = true
	armario.execute()
	_check("Con la toalla puesta se ve su render y cuelgan las dos prendas", ui.render_rect.texture == load("res://Resources/Clothing/towel.tres").render and ui.garment_slots["home"].visible and ui.garment_slots["work"].visible)
	pm.wet_clothes()   # no hace nada con la toalla, pero no debe romper
	for it in pm.wardrobe:
		if pm.outfit_id_of(it) == "home":
			it.get_custom_condition("cleanliness").value = 10.0
			it.get_custom_condition("wetness").value = 100.0
			it.update_states()
	ui.refresh()
	_check("Una prenda mojada y sucia muestra su imagen de mojada y sucia", ui.garment_slots["home"].get_node("Layer").texture == casa.wet_dirty)
	_check("Con ropa sucia colgada la cesta se ve llena", ui.basket_rect.texture == load("res://Resources/Clothing/basket.tres").full)
	await _sin_dialogos()   # las lineas de la ducha
	var dlg = root.get_node("Dialogic")
	var dicho : Array = []
	var escuchar := func(info) -> void: dicho.append(str(info.get("text", "")))
	dlg.Text.text_started.connect(escuchar)
	ui._on_basket_input(clic)
	for i in 30:
		await create_timer(0.1).timeout
		if not dicho.is_empty():
			break
	_check("Tocar la cesta con ropa sucia: 'Luego lavaré esto.'", dicho.size() > 0 and dicho[0].strip_edges() == "Luego lavaré esto.", str(dicho))
	dlg.Text.text_started.disconnect(escuchar)
	dlg.end_timeline()
	await create_timer(0.3).timeout
	ui._unhandled_input(esc)
	await _soltar(escena)

## Cierra lo que Mayui este diciendo (espera a que siga callada un momento: Dialogic tarda en arrancar). Antes de cerrar
## deja que la frase aparezca: cerrarla a media animacion hace que Dialogic la vuelva a escribir en el dialogo siguiente.
func _sin_dialogos() -> void:
	var dlg = root.get_node("Dialogic")
	var calma := 0
	for i in 30:
		await create_timer(0.2).timeout
		if dlg.current_timeline != null:
			await create_timer(1.2).timeout
			dlg.end_timeline()
			calma = 0
		else:
			calma += 1
			if calma >= 3:
				return

func _soltar(escena: Node) -> void:
	escena.release_player()
	root.remove_child(escena)
	escena.free()
	zm.zone_node = null
	await process_frame
