extends SceneTree
## Pruebas automaticas del ESPEJO del lavamanos (pantalla con Mayui, cepillo, llave y salida) y de cepillarse en el tutorial.
##
## Uso (desde la carpeta del proyecto):
##   Godot_v4.6-stable_win64_console.exe --headless --path . -s res://Tools/probar_espejo.gd
## Termina con codigo 0 si todo pasa y 1 si algo falla.

var pm
var gm
var tm
var zm
var tk
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
	zm = root.get_node("ZoneManager")
	tk = root.get_node("TaskManager")
	await create_timer(0.3).timeout
	gm.game_started = true
	await _t_espejo()
	await _t_tutorial()
	print("=== %d comprobaciones OK, %d con FALLA ===" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _clic() -> InputEventMouseButton:
	var c := InputEventMouseButton.new()
	c.button_index = MOUSE_BUTTON_LEFT
	c.pressed = true
	return c

## El espejo esta en el bano.
func _entrar() -> Node:
	zm.previous_zone = -1
	var escena : Node = (load("res://Scenes/World/Bathroom.tscn") as PackedScene).instantiate()
	root.add_child(escena)
	await create_timer(1.2).timeout
	return escena

func _salir(escena: Node) -> void:
	escena.release_player()
	root.remove_child(escena)
	escena.free()
	zm.zone_node = null
	await process_frame

func _prenda(nombre: String):
	var item = load("res://Resources/Items/Data/%s.tres" % nombre)
	return load("res://Resources/Items/item.gd").new(item)

# ------------------------------------------------------------------ A. la pantalla del espejo
func _t_espejo() -> void:
	print("A. Pantalla del espejo")
	gm.new_game()
	pm.reset_engine_state(true)
	var tarea = tk.get_task_list_res("TUTORIAL_DOOR").get_task_res("TEETH")
	tarea.task_done = false
	var escena : Node = await _entrar()
	var ui = escena.get_node("UILayer/MirrorUI")
	var casa = load("res://Resources/Clothing/home_clothes.tres")
	var trabajo = load("res://Resources/Clothing/work_clothes.tres")
	ui.brush_seconds = 0.3
	ui.feedback_seconds = 0.4
	ui.exit_hint_seconds = 0.2
	_check("El espejo empieza cerrado", not ui.visible)
	# el espejo esta pegado a la pared: el vaso, el tubo, su sombra y el cepillo van DELANTE del marco (que viene dentro de la capa de Mayui)
	var capa_mayui = ui.get_node("Canvas/Mayui")
	var vaso = ui.get_node("Canvas/CupFront")
	_check("El vaso con el tubo y su sombra (CupFront) se dibuja DELANTE de la capa de Mayui (que trae el marco del espejo)", vaso.texture != null and vaso.get_index() > capa_mayui.get_index())
	_check("El cepillo y su resaltado se dibujan delante del marco, sobre el vaso", ui.brush_rect.get_index() > vaso.get_index() and ui.highlights["brush"].get_index() > ui.brush_rect.get_index())
	_check("El fondo y la toalla quedan detras de Mayui", ui.get_node("Canvas/Bg").get_index() < capa_mayui.get_index() and ui.towel_rect.get_index() < capa_mayui.get_index())
	_check("Ya no queda el parche viejo que escondia el tubo detras del marco", ui.get_node_or_null("Canvas/TubePatch") == null)
	# el recorte del vaso no debe tapar a Mayui: en esa zona todas las capas de Mayui (cada ropa, de pie y cepillandose) son solo marco
	var zona := Rect2i(int(vaso.offset_left), int(vaso.offset_top), int(vaso.offset_right - vaso.offset_left), int(vaso.offset_bottom - vaso.offset_top))
	var referencia : Image = (load("res://Resources/Clothing/home_clothes.tres").mirror as Texture2D).get_image()
	var capas_zona_ok := true
	var capas_zona_detalle := ""
	for ropa_res in ["home_clothes", "work_clothes", "outfit1"]:
		var datos = load("res://Resources/Clothing/%s.tres" % ropa_res)
		for tex in [datos.mirror, datos.mirror_alt]:
			var img : Image = (tex as Texture2D).get_image()
			var distintos := 0
			for yy in range(zona.position.y, zona.end.y):
				for xx in range(zona.position.x, zona.end.x):
					var pa : Color = referencia.get_pixel(xx, yy)
					var pb : Color = img.get_pixel(xx, yy)
					if absf(pa.a - pb.a) > 0.1 or (pa.a > 0.05 and pb.a > 0.05 and (absf(pa.r - pb.r) + absf(pa.g - pb.g) + absf(pa.b - pb.b)) > 0.25):
						distintos += 1
			if distintos > 0:
				capas_zona_ok = false
				capas_zona_detalle += " %s:%d" % [ropa_res, distintos]
	_check("Donde va el recorte del vaso todas las capas de Mayui son iguales (solo marco), asi que el recorte no tapa a Mayui", capas_zona_ok, capas_zona_detalle)
	var nueva = load("res://UI/Mirror/mirror_ui.tscn").instantiate()
	_check("Cepillarse dura 1.5 s (con el brazo en la boca)", nueva.brush_seconds == 1.5)
	nueva.free()
	ui.open()
	_check("Abrir el espejo: se ve y Mayui queda quieta", ui.visible and gm.modal_count == 1)
	_check("Se ve a Mayui con la ropa que lleva (casa) y la toalla colgada", ui.mayui_rect.texture == casa.mirror and ui.towel_rect.visible and ui.brush_rect.visible)
	ui.close()
	_check("Cerrar el espejo: Mayui vuelve a moverse", not ui.visible and gm.modal_count == 0)
	# cada ropa tiene su imagen en el espejo
	pm.wear_clothes(pm.wardrobe[0])
	ui.open()
	_check("Con el uniforme se ve el espejo del uniforme", ui.mayui_rect.texture == trabajo.mirror and trabajo.mirror != casa.mirror and trabajo.mirror_alt != null)
	_check("Cada ropa tiene dos cuadros: de pie y cepillandose", casa.mirror != null and casa.mirror_alt != null and casa.mirror != casa.mirror_alt)
	# resaltado del cepillo; la llave solo se resalta si se puede lavar
	ui._on_hover("brush", true)
	_check("El cepillo se resalta al pasar el mouse", ui.highlights["brush"].visible)
	ui._on_hover("brush", false)
	_check("...y deja de resaltarse al quitarlo", not ui.highlights["brush"].visible)
	ui._on_hover("faucet", true)
	_check("La llave NO se resalta si no hay ropa sucia en las manos (opcion bloqueada)", not ui.highlights["faucet"].visible)
	# verse la cara
	pm.remove_effect("SMELLY")
	pm.remove_effect("WEAK")
	pm.remove_effect("STRESS")
	ui._on_hit_input(_clic(), "mirror")
	_check("Verse la cara en buen estado: 'No me veo tan mal.'", ui.feedback_label.visible and ui.feedback_label.text == "No me veo tan mal.", ui.feedback_label.text)
	pm.add_effect(load("res://Resources/Effects/Effects/smelly.tres").duplicate())
	ui._on_hit_input(_clic(), "mirror")
	_check("Verse la cara con mal estado: 'He estado peor.'", ui.feedback_label.text == "He estado peor.", ui.feedback_label.text)
	pm.remove_effect("SMELLY")
	await create_timer(0.6).timeout
	_check("El comentario desaparece solo", not ui.feedback_label.visible)
	# cepillarse: una vez al dia, con el brazo en la boca (sin subir y bajar)
	var antes : int = tm.get_minutes()
	pm.daily.brushed = false
	var cepillado := [0]
	ui.brushed.connect(func(): cepillado[0] += 1)
	ui._on_hit_input(_clic(), "brush")
	_check("Cepillarse: Mayui dice 'Te cepillas los dientes', se esconde el cepillo y se ve con el brazo en la boca", ui._busy and ui.feedback_label.text == "Te cepillas los dientes" and not ui.brush_rect.visible and ui.mayui_rect.texture == trabajo.mirror_alt)
	ui.close()
	_check("Mientras se cepilla no se puede salir", ui.visible)
	await create_timer(0.15).timeout
	_check("Durante el cepillado se queda con el brazo en la boca (no sube y baja)", ui.mayui_rect.texture == trabajo.mirror_alt)
	await create_timer(0.5).timeout
	_check("Al terminar vuelve a estar de pie, el cepillo vuelve al vaso y se anota el cepillado", cepillado[0] == 1 and not ui._busy and ui.mayui_rect.texture == trabajo.mirror and ui.brush_rect.visible and pm.daily.brushed)
	_check("Cepillarse tarda 5 minutos", (tm.get_minutes() - antes + 1440) % 1440 == 5, "paso %d" % ((tm.get_minutes() - antes + 1440) % 1440))
	var despues : int = tm.get_minutes()
	ui._on_hover("brush", true)
	_check("Ya cepillada: el cepillo no se resalta", not ui.highlights["brush"].visible)
	ui._on_hit_input(_clic(), "brush")
	_check("Cepillarse otra vez el mismo dia no se puede y Mayui lo dice", not ui._busy and ui.feedback_label.text == "Ya me cepillé." and ui.brush_rect.visible, ui.feedback_label.text)
	await create_timer(0.5).timeout
	_check("...no pasa el tiempo ni se repite la animacion ni la tarea", cepillado[0] == 1 and tm.get_minutes() == despues and ui.mayui_rect.texture == trabajo.mirror)
	pm.reset_engine_state()
	_check("Al empezar otro dia se puede volver a cepillar", ui.can_brush())
	pm.daily.brushed = true
		# salir: Esc, o la flecha de abajo
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	ui._unhandled_input(esc)
	_check("Esc cierra el espejo", not ui.visible and gm.modal_count == 0)
	ui.open()
	await create_timer(0.1).timeout
	ui._set_exit_visible(false)
	ui._set_exit_visible(true)
	_check("La flecha de salir sube al llevar el mouse abajo", ui.exit_visible)
	ui._on_exit_input(_clic())
	_check("Clic en la flecha: sale del espejo", not ui.visible and gm.modal_count == 0)
	# la toalla puesta: no cuelga en el toallero y no hay imagen de Mayui con toalla
	pm.wear_towel()
	ui.open()
	_check("Con la toalla puesta el toallero queda vacio (y aun no hay imagen de Mayui con toalla)", not ui.towel_rect.visible and not ui.mayui_rect.visible)
	ui.close()
	# lavar ropa: solo con ropa sucia en las manos y fuera del tutorial
	var sucia = _prenda("home_cloth")
	sucia.get_custom_condition("cleanliness").value = 10.0
	sucia.update_states()
	pm.player.inventory.add_item(sucia)
	pm.wear_clothes(pm.wardrobe[0])
	ui.open()
	_check("Durante el tutorial lavar ropa esta bloqueado aunque haya ropa sucia en las manos", ui.tutorial_blocks_wash() and not ui.can_wash())
	var lista = tk.get_task_list_res("TUTORIAL_DOOR")
	var estados := {}
	for tarea_i in lista.task_list:
		estados[tarea_i.task_unique_name] = tarea_i.task_done
		tarea_i.task_done = true
	ui._on_hover("faucet", true)
	_check("Terminado el tutorial con ropa sucia en las manos la llave se resalta", ui.can_wash() and ui.highlights["faucet"].visible)
	ui._on_hit_input(_clic(), "faucet")
	_check("Lavar la ropa: queda limpia y mojada y Mayui lo dice", sucia.has_state("clean") and sucia.has_state("wet") and ui.feedback_label.text.begins_with("Lavaste"), ui.feedback_label.text)
	_check("Ya no hay ropa sucia en las manos", not ui.can_wash())
	for nombre in estados.keys():
		lista.get_task_res(nombre).task_done = estados[nombre]
	ui.close()
	pm.player.inventory.remove_from_hands(sucia)
	await _salir(escena)

# ------------------------------------------------------------------ B. cepillarse en el tutorial
func _t_tutorial() -> void:
	print("B. Cepillarse en el tutorial")
	gm.new_game()
	pm.reset_engine_state(true)
	var lista = tk.get_task_list_res("TUTORIAL_DOOR")
	_check("La puerta del tutorial pide ducha, ropa, comer y cepillarse (en el orden de tu guion)", lista.task_list.size() == 4 and [lista.task_list[0].task_unique_name, lista.task_list[1].task_unique_name, lista.task_list[2].task_unique_name, lista.task_list[3].task_unique_name] == ["BATHE", "CLOTHES", "COOK", "TEETH"])
	for t in lista.task_list:
		t.task_done = false
	var escena : Node = await _entrar()
	var ui = escena.get_node("UILayer/MirrorUI")
	ui.brush_seconds = 0.2
	ui.open()
	ui._on_hit_input(_clic(), "brush")
	await create_timer(0.5).timeout
	_check("Cepillarse marca la tarea TEETH del tutorial", lista.get_task_res("TEETH").task_done)
	ui.close()
	await _salir(escena)
