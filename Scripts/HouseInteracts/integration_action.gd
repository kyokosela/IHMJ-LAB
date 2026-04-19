@tool
extends InteractableAction

const ARCADE_SCENE := preload("res://UI/Arcade/arcade.tscn")
const MARKET_SCENE := preload("res://UI/Market/market.tscn")

# Preload effect resources (EFFECT_STRESS inherited from InteractableAction)
const EFFECT_HUNGER := preload("res://Resources/Effects/Effects/hunger.tres")
const EFFECT_SLEEPY := preload("res://Resources/Effects/Effects/sleepy.tres")
const EFFECT_SMELLY := preload("res://Resources/Effects/Effects/smelly.tres")
const EFFECT_CALM := preload("res://Resources/Effects/Effects/calm.tres")
const EFFECT_INSOMNIA := preload("res://Resources/Effects/Effects/insomnia.tres")
const EFFECT_HYPERACTIVE := preload("res://Resources/Effects/Effects/hyperactive.tres")
const EFFECT_TIRED := preload("res://Resources/Effects/Effects/tired.tres")
const EFFECT_WEAK := preload("res://Resources/Effects/Effects/weak.tres")
const EFFECT_INAPETENCIA := preload("res://Resources/Effects/Effects/inapetencia.tres")
const EFFECT_HYPERSOMNIA := preload("res://Resources/Effects/Effects/hipersomnia.tres")
const EFFECT_ATENTA := preload("res://Resources/Effects/Effects/atenta.tres")

const STREET_RISK_BASE_CHANCE : float = 0.10
const STREET_RISK_SANITY_LOSS : float = 5.0
const STREET_RISK_TIME_PENALTY : String = "00:10"

enum ActionType {
	# Workspace & Apps
	OPEN_WORKSPACE,
	OPEN_PORTAL,
	OPEN_EVALUATION,
	# Attendance
	CLOCK_IN,
	CLOCK_OUT,
	RECORD_ABSENCE,
	# Economy
	PAY_RENT,
	CHECK_RENT,
	# NPCs
	TALK_CASERO,
	TALK_MADINA,
	TALK_VEDA,
	TALK_SATIVA,
	# Events & Flags
	EXECUTE_EVENT,
	SET_FLAG,
	# Zone Travel
	ZONE_APARTMENT,
	ZONE_LOBBY,
	ZONE_OFFICE,
	ZONE_COMMERCIAL,
	# Apartment Actions
	SLEEP_BED,
	BATHE,
	CHANGE_CLOTHES,
	# Effects - Apply
	APPLY_HUNGER,
	APPLY_SLEEPY,
	APPLY_SMELLY,
	APPLY_STRESS,
	APPLY_INSOMNIA,
	APPLY_HYPERACTIVE,
	APPLY_TIRED,
	APPLY_WEAK,
	# Effects - Remove
	REMOVE_EFFECT_HUNGER,
	REMOVE_EFFECT_SLEEPY,
	REMOVE_EFFECT_SMELLY,
	REMOVE_EFFECT_STRESS,
	CLEAR_ALL_EFFECTS,
	# Sanity manipulation
	DECREASE_SANITY_10,
	INCREASE_SANITY_10,
	# Items & Economy
	SPAWN_MONEY_100,
	ADD_TIME_1HR,
	# Primary effects pair
	APPLY_CALM,
	REMOVE_EFFECT_CALM,
	# Dev tools
	ADVANCE_DAY,
	# Secondary effects
	APPLY_INAPETENCIA,
	APPLY_HYPERSOMNIA,
	APPLY_ATENTA,
	REMOVE_EFFECT_INAPETENCIA,
	REMOVE_EFFECT_HYPERSOMNIA,
	REMOVE_EFFECT_ATENTA,
	# Food
	EAT_FOOD,
	# Weekend activities
	OPEN_ARCADE,
	OPEN_MARKET,
}

@export var action_type: ActionType = ActionType.OPEN_WORKSPACE
@export var event_name: String = ""
@export var flag_name: String = ""
@export var bed_type: int = PlayerManager.BED_TYPE.TYPE_C

func custom_execute() -> void:
	super()

	if Engine.is_editor_hint():
		return

	match action_type:
		# Workspace & Apps
		ActionType.OPEN_WORKSPACE:
			_call_scene_method("interaction_open_workspace")
		ActionType.OPEN_PORTAL:
			_call_scene_method("interaction_open_portal")
		ActionType.OPEN_EVALUATION:
			_call_scene_method("interaction_open_evaluation")
		# Attendance
		ActionType.CLOCK_IN:
			AttendanceManager.clock_in()
			_show_feedback("Marcaste entrada")
		ActionType.CLOCK_OUT:
			AttendanceManager.clock_out()
			_show_feedback("Marcaste salida")
		ActionType.RECORD_ABSENCE:
			AttendanceManager.record_absence()
			_show_feedback("Falta registrada")
		# Economy
		ActionType.PAY_RENT:
			var paid := EconomyManager.pay_rent()
			_show_feedback("Renta pagada" if paid else "No tienes para la renta")
		ActionType.CHECK_RENT:
			EconomyManager.check_rent_due()
			_show_feedback("Renta pendiente: %s" % ("No" if EconomyManager.is_rent_paid() else "Si"))
		# NPCs
		ActionType.TALK_CASERO:
			if NarrativeFlags.has_flag("casero_intro_done"):
				Dialogic.start("casero_rent_reminder")
			else:
				Dialogic.start("casero_intro")
		ActionType.TALK_MADINA:
			_talk_madina()
		ActionType.TALK_VEDA:
			if TimeManager.day == 1 and not NarrativeFlags.has_flag("met_veda_day1"):
				Dialogic.start("veda_day1")
			else:
				_show_feedback("Veda te ignora")
		ActionType.TALK_SATIVA:
			_show_feedback("Sativa no esta disponible")
		# Events & Flags
		ActionType.EXECUTE_EVENT:
			if not event_name.is_empty():
				EventManager.execute_event(event_name)
		ActionType.SET_FLAG:
			if not flag_name.is_empty():
				NarrativeFlags.set_flag(flag_name)
		# Zone Travel
		ActionType.ZONE_APARTMENT:
			_simulate_zone_change(ZoneManager.ZONES.APARTMENT)
		ActionType.ZONE_LOBBY:
			_simulate_zone_change(ZoneManager.ZONES.LOBBY)
		ActionType.ZONE_OFFICE:
			_simulate_zone_change(ZoneManager.ZONES.OFFICE)
		ActionType.ZONE_COMMERCIAL:
			_simulate_zone_change(ZoneManager.ZONES.COMMERCIAL)
		# Apartment Actions
		ActionType.SLEEP_BED:
			_do_sleep()
		ActionType.BATHE:
			_do_bathe()
		ActionType.CHANGE_CLOTHES:
			TimeManager.add_to_current_time("00:05")
			_show_feedback("Cambiaste de ropa")
		# Effects - Apply
		ActionType.APPLY_HUNGER:
			_apply_effect(EFFECT_HUNGER, "Hambre aplicada")
		ActionType.APPLY_SLEEPY:
			_apply_effect(EFFECT_SLEEPY, "Somnolencia aplicada")
		ActionType.APPLY_SMELLY:
			_apply_effect(EFFECT_SMELLY, "Mal olor aplicado")
		ActionType.APPLY_STRESS:
			_apply_primary_effect(EFFECT_STRESS, "CALM", "Estres aplicado", "Calma reducida")
		ActionType.APPLY_CALM:
			_apply_primary_effect(EFFECT_CALM, "STRESS", "Calma aplicada", "Estres reducido")
		ActionType.APPLY_INSOMNIA:
			_apply_effect(EFFECT_INSOMNIA, "Insomnio aplicado")
		ActionType.APPLY_HYPERACTIVE:
			_apply_effect(EFFECT_HYPERACTIVE, "Hiperactividad aplicada")
		ActionType.APPLY_TIRED:
			_apply_effect(EFFECT_TIRED, "Cansancio aplicado")
		ActionType.APPLY_WEAK:
			_apply_effect(EFFECT_WEAK, "Debilitamiento aplicado")
		ActionType.APPLY_INAPETENCIA:
			_apply_effect(EFFECT_INAPETENCIA, "Inapetencia aplicada")
		ActionType.APPLY_HYPERSOMNIA:
			_apply_effect(EFFECT_HYPERSOMNIA, "Hipersomnia aplicada")
		ActionType.APPLY_ATENTA:
			_apply_effect(EFFECT_ATENTA, "Atenta aplicada")
		# Effects - Remove
		ActionType.REMOVE_EFFECT_HUNGER:
			_remove_effect("HUNGER", "Hambre eliminada")
		ActionType.REMOVE_EFFECT_SLEEPY:
			_remove_effect("SLEEPY", "Somnolencia eliminada")
		ActionType.REMOVE_EFFECT_SMELLY:
			_remove_effect("SMELLY", "Mal olor eliminado")
		ActionType.REMOVE_EFFECT_STRESS:
			_remove_effect("STRESS", "Estres eliminado")
		ActionType.REMOVE_EFFECT_CALM:
			_remove_effect("CALM", "Calma eliminada")
		ActionType.REMOVE_EFFECT_INAPETENCIA:
			_remove_effect("INAPETENCIA", "Inapetencia eliminada")
		ActionType.REMOVE_EFFECT_HYPERSOMNIA:
			_remove_effect("HIPERSOMNIA", "Hipersomnia eliminada")
		ActionType.REMOVE_EFFECT_ATENTA:
			_remove_effect("ATENTA", "Atenta eliminada")
		ActionType.CLEAR_ALL_EFFECTS:
			_clear_all_effects()
		# Sanity
		ActionType.DECREASE_SANITY_10:
			PlayerManager.sanity_value -= 10
			_show_feedback("Cordura -10 (ahora: %.0f)" % PlayerManager.sanity_value)
		ActionType.INCREASE_SANITY_10:
			PlayerManager.sanity_value += 10
			_show_feedback("Cordura +10 (ahora: %.0f)" % PlayerManager.sanity_value)
		# Items & Economy
		ActionType.SPAWN_MONEY_100:
			EconomyManager.add_money(100, "DEV_SPAWN")
			_show_feedback("Agregaste S/100")
		ActionType.ADD_TIME_1HR:
			TimeManager.add_to_current_time("01:00")
			_show_feedback("Avanzaste 1 hora")
		ActionType.ADVANCE_DAY:
			TimeManager.day += 1
			_show_feedback("Avanzaste al dia %d" % TimeManager.day)
		ActionType.EAT_FOOD:
			PlayerManager.remove_effect("HUNGER")
			PlayerManager.increase_stat("ENERGY", 10.0)
			TimeManager.add_to_current_time("00:10")
			_show_feedback("Comiste algo (+10 energía, 10 min)")
		ActionType.OPEN_ARCADE:
			if NarrativeFlags.has_flag("arcade_open"):
				_open_overlay(ARCADE_SCENE, "arcade_closed")
			else:
				_show_feedback("El arcade no está disponible hoy")
		ActionType.OPEN_MARKET:
			if NarrativeFlags.has_flag("market_open"):
				_open_overlay(MARKET_SCENE, "market_closed")
			else:
				_show_feedback("El mercado no está disponible hoy")

func _call_scene_method(method_name: String) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method(method_name):
		scene.call(method_name)

func _show_feedback(text: String) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("_set_action"):
		scene.call("_set_action", text)

func _simulate_zone_change(zone_id: int) -> void:
	var zone_name := ZoneManager.get_zone_name(zone_id)
	var requires_bus := zone_id in [ZoneManager.ZONES.OFFICE, ZoneManager.ZONES.COMMERCIAL]
	
	if requires_bus:
		if not EconomyManager.can_afford_bus():
			_show_feedback("No tienes para el bus (S/10)")
			return
		EconomyManager.pay_bus()
		_show_feedback("Viajando a %s (pagaste S/10)" % zone_name)
	else:
		_show_feedback("Caminando a %s" % zone_name)
	
	ZoneManager.current_zone = zone_id
	TimeManager.add_to_current_time("00:15")
	_process_street_risk_simulation()

func _do_sleep() -> void:
	PlayerManager.request_sleep(bed_type)

func _do_bathe() -> void:
	TimeManager.add_to_current_time("00:30")
	if PlayerManager.has_effect("SMELLY"):
		PlayerManager.remove_effect("SMELLY")
		_show_feedback("Te banaste y eliminaste mal olor (30 min)")
	else:
		_show_feedback("Te banaste (30 min)")

func _process_street_risk_simulation() -> void:
	var chance : float = PlayerManager.get_street_risk_chance(STREET_RISK_BASE_CHANCE)
	var roll : float = randf()

	if roll > chance:
		return

	PlayerManager.sanity_value -= STREET_RISK_SANITY_LOSS
	TimeManager.add_to_current_time(STREET_RISK_TIME_PENALTY)
	PlayerManager.add_effect(EFFECT_STRESS.duplicate())
	_show_feedback("Susto callejero (roll %.2f <= %.2f)" % [roll, chance])

func _apply_effect(effect_resource: Effect, feedback: String) -> void:
	if effect_resource == null:
		_show_feedback("Error: Effect resource is null")
		return

	if PlayerManager.has_effect(effect_resource.effect_unique_name):
		if effect_resource is EffectLevel:
			PlayerManager.increase_level_effect(effect_resource.effect_unique_name, 1)
			var level := PlayerManager.get_effect_level_value(effect_resource.effect_unique_name)
			_show_feedback("%s (Nivel %d)" % [feedback, int(level)])
		else:
			_show_feedback("%s (ya activo)" % feedback)
		return

	PlayerManager.add_effect(effect_resource.duplicate())
	_show_feedback(feedback)

func _apply_primary_effect(effect_resource: Effect, opposite_effect_name: String, feedback: String, opposite_feedback: String) -> void:
	if PlayerManager.has_effect(opposite_effect_name):
		_reduce_or_remove_level_effect(opposite_effect_name)
		_show_feedback(opposite_feedback)
		return
	_apply_effect(effect_resource, feedback)

func _reduce_or_remove_level_effect(unique_effect_name: String) -> void:
	var effect := PlayerManager.get_effect_res(unique_effect_name)
	if not (effect is EffectLevel):
		PlayerManager.remove_effect(unique_effect_name)
		return
	if effect.level <= 0:
		PlayerManager.remove_effect(unique_effect_name)
		return
	PlayerManager.decrease_level_effect(unique_effect_name, 1)

func _remove_effect(effect_unique_name: String, feedback: String) -> void:
	if PlayerManager.has_effect(effect_unique_name):
		PlayerManager.remove_effect(effect_unique_name)
		_show_feedback(feedback)
	else:
		_show_feedback("%s (no estaba activo)" % feedback)

func _clear_all_effects() -> void:
	var effect_names: Array[String] = []
	for effect in PlayerManager.effects:
		effect_names.append(effect.effect_unique_name)

	for effect_name in effect_names:
		PlayerManager.remove_effect(effect_name)

	_show_feedback("Efectos eliminados: %d" % effect_names.size())

func _open_overlay(scene: PackedScene, closed_signal: String) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 20
	get_tree().root.add_child(canvas)
	var ui := scene.instantiate()
	canvas.add_child(ui)
	ui.connect(closed_signal, canvas.queue_free.bind())

func _talk_madina() -> void:
	match TimeManager.day:
		2:
			Dialogic.start("madina_cafe_day2")
		3:
			Dialogic.start("madina_tension")
		_:
			Dialogic.start("madina_warning")
