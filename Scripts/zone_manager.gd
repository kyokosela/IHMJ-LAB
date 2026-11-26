extends Node

signal street_risk_triggered(chance: float, roll: float)
signal zone_ready(zone_id: int) ## la escena de una zona ya cargo y Mayui esta en ella

enum ZONES {
	APARTMENT,
	LOBBY,
	OFFICE,
	COMMERCIAL,
	BATHROOM,
	BALCONY,
	HALLWAY
}

const zone_paths: Array[String] = [
	"res://Scenes/World/Apartment.tscn",
	"res://Scenes/World/Lobby.tscn",
	"res://Scenes/World/Office.tscn",
	"res://Scenes/World/Commercial.tscn",
	"res://Scenes/World/Bathroom.tscn",
	"res://Scenes/World/Balcony.tscn",
	"res://Scenes/World/Hallway.tscn"
]

const ZONES_REQUIRING_TRANSPORT: Array[ZONES] = [
	ZONES.OFFICE,
	ZONES.COMMERCIAL
]

## Cuartos del apartamento (la casa de Mayui, ademas del propio apartamento).
const HOME_ROOMS : Array[ZONES] = [
	ZONES.BATHROOM,
	ZONES.BALCONY
]
## El edificio de Mayui. Dentro de un establecimiento pasar de una zona a otra no es viajar (no gasta energia ni tiempo, no
## hay calle ni bus): solo la calle, de un establecimiento a otro, cuesta (tu regla del 2026-11-25).
const HOME_BUILDING : Array[ZONES] = [
	ZONES.APARTMENT,
	ZONES.BATHROOM,
	ZONES.BALCONY,
	ZONES.HALLWAY,
	ZONES.LOBBY
]

const STREET_RISK_BASE_CHANCE : float = 0.10
const STREET_RISK_TIME_PENALTY : String = "00:10"
## La cordura y el Estres de un imprevisto en la calle los resuelve PlayerManager.register_street_event().

## Segundos para oscurecer y otros tantos para aclarar: un cambio de zona dura 2 s en total.
const ZONE_FADE_TIME : float = 1.0

var current_zone: int = ZONES.APARTMENT
var previous_zone: int = -1 ## de donde viene Mayui (elige el punto de aparicion)
var _travel_origin: int = -1 ## donde empezo el ultimo viaje: volver ahi no acumula cansancio
var _changing_zone : bool = false ## true desde que se toca la puerta hasta que la nueva zona termina de aclarar
var _change_id : int = 0
var zone_node: World:
	set(_value):
		zone_node = _value
		TransitionManager.fadeOut(ZONE_FADE_TIME)
		if _value != null:
			# diferido: que la escena termine de armarse antes de entregar eventos pendientes
			call_deferred("emit_signal", "zone_ready", _value.zone_id)
		if _changing_zone:
			_unlock_after_fade()

var energy_cost_base: float = 2
var energy_cost_incremental: float = 0

var time_cost_base: String = "00:05"
var time_cost_incremental: String = "00:05"

## La zona es parte de la casa de Mayui (el apartamento o uno de sus cuartos).
func is_home(zone_id: int) -> bool:
	return zone_id == ZONES.APARTMENT or zone_id in HOME_ROOMS

## Pasos que no son viajar: los de dentro del edificio de Mayui (casa, pasillo y recepcion).
func _is_free_step(from_zone: int, to_zone: int) -> bool:
	return from_zone in HOME_BUILDING and to_zone in HOME_BUILDING

func change_zone(new_zone_id: ZONES) -> void:
	if _changing_zone:
		return # ya se esta viajando: una puerta pisada otra vez no debe repetir el cambio
	var indoors : bool = _is_free_step(current_zone, new_zone_id)
	var by_bus : bool = not indoors and _requires_transport(new_zone_id)
	if by_bus:
		if not EconomyManager.can_afford_bus():
			push_warning("Cannot afford bus fare")
			return
		EconomyManager.pay_bus()

	# Mayui queda quieta (y sin interactuar) hasta que la nueva zona termine de aclarar
	_changing_zone = true
	_change_id += 1
	GameManager.modal_count += 1

	if indoors:
		previous_zone = current_zone
		current_zone = new_zone_id
	else:
		_travel(new_zone_id, by_bus)

	TransitionManager.fadeIn(ZONE_FADE_TIME)
	await TransitionManager.transition_finished
	var tree := zone_node.get_tree()
	zone_node.release_player() # antes de cerrar la escena, no durante (evita crash)
	tree.call_deferred("change_scene_to_file", zone_paths[new_zone_id])
	_guard_stuck_lock(_change_id)

## Moverse por la calle (de un establecimiento a otro): cuesta tiempo, energia (a pie) y puede pasar algo.
func _travel(new_zone_id: ZONES, by_bus: bool) -> void:
	if new_zone_id == _travel_origin:
		time_cost_incremental = time_cost_base
	else:
		time_cost_incremental = TimeUtils.increase_time(time_cost_incremental, time_cost_base)
	# En bus se paga con dinero, no con energia, y el viaje no cuenta como cansancio de caminar
	if not by_bus:
		if new_zone_id == _travel_origin:
			energy_cost_incremental = energy_cost_base
		else:
			energy_cost_incremental += energy_cost_base

	_travel_origin = current_zone
	previous_zone = current_zone
	current_zone = new_zone_id

	if not by_bus:
		PlayerManager.decrease_stat("ENERGY", energy_cost_incremental)
	TimeManager.add_to_current_time(PlayerManager.get_time_cost_with_effects(time_cost_incremental))
	_process_street_risk()

## La nueva zona ya cargo y empezo a aclarar: cuando termine, Mayui vuelve a moverse.
func _unlock_after_fade() -> void:
	var id := _change_id
	await TransitionManager.transition_finished
	_release_lock(id)

func _release_lock(id: int) -> void:
	if _changing_zone and id == _change_id:
		_changing_zone = false
		GameManager.modal_count -= 1

## Seguro: si la nueva zona nunca llega a cargar, no dejar a Mayui bloqueada para siempre.
func _guard_stuck_lock(id: int) -> void:
	await get_tree().create_timer(6.0).timeout
	if _changing_zone and id == _change_id:
		push_warning("ZoneManager: el cambio de zona no termino; se libera a Mayui")
		_release_lock(id)

func _requires_transport(zone_id: ZONES) -> bool:
	if current_zone in [ZONES.APARTMENT, ZONES.LOBBY]:
		if zone_id in ZONES_REQUIRING_TRANSPORT:
			return true
	return false

func get_zone_name(zone_id: ZONES) -> String:
	match zone_id:
		ZONES.APARTMENT:
			return "Apartamento"
		ZONES.LOBBY:
			return "Lobby"
		ZONES.OFFICE:
			return "Oficina"
		ZONES.COMMERCIAL:
			return "Zona Comercial"
		ZONES.BATHROOM:
			return "Baño"
		ZONES.BALCONY:
			return "Balcón"
		ZONES.HALLWAY:
			return "Pasillo"
	return "Desconocido"

func _process_street_risk() -> void:
	var chance : float = PlayerManager.get_street_risk_chance(STREET_RISK_BASE_CHANCE)
	var roll : float = PlayerManager.rng.randf()

	if roll > chance:
		return

	TimeManager.add_to_current_time(STREET_RISK_TIME_PENALTY)
	PlayerManager.register_street_event()
	street_risk_triggered.emit(chance, roll)
