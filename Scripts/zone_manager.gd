extends Node

signal street_risk_triggered(chance: float, roll: float)
signal zone_ready(zone_id: int) ## la escena de una zona ya cargo y Mayui esta en ella

enum ZONES {
	APARTMENT,
	LOBBY,
	OFFICE,
	COMMERCIAL
}

const zone_paths: Array[String] = [
	"res://Scenes/World/Apartment.tscn",
	"res://Scenes/World/Lobby.tscn",
	"res://Scenes/World/Office.tscn",
	"res://Scenes/World/Commercial.tscn"
]

const ZONES_REQUIRING_TRANSPORT: Array[ZONES] = [
	ZONES.OFFICE,
	ZONES.COMMERCIAL
]

const STREET_RISK_BASE_CHANCE : float = 0.10
const STREET_RISK_TIME_PENALTY : String = "00:10"
## La cordura y el Estres de un imprevisto en la calle los resuelve PlayerManager.register_street_event().

var current_zone: int = ZONES.APARTMENT
var previous_zone: int = -1
var zone_node: World:
	set(_value):
		zone_node = _value
		TransitionManager.fadeOut()
		if _value != null:
			# diferido: que la escena termine de armarse antes de entregar eventos pendientes
			call_deferred("emit_signal", "zone_ready", _value.zone_id)

var energy_cost_base: float = 2
var energy_cost_incremental: float = 0

var time_cost_base: String = "00:05"
var time_cost_incremental: String = "00:05"

func change_zone(new_zone_id: ZONES) -> void:
	if _requires_transport(new_zone_id):
		if not EconomyManager.can_afford_bus():
			push_warning("Cannot afford bus fare")
			return
		EconomyManager.pay_bus()

	if new_zone_id == previous_zone:
		energy_cost_incremental = energy_cost_base
		time_cost_incremental = time_cost_base
	else:
		energy_cost_incremental += energy_cost_base
		time_cost_incremental = TimeUtils.increase_time(time_cost_incremental, time_cost_base)

	previous_zone = current_zone
	current_zone = new_zone_id

	PlayerManager.decrease_stat("ENERGY", energy_cost_incremental)
	TimeManager.add_to_current_time(PlayerManager.get_time_cost_with_effects(time_cost_incremental))
	_process_street_risk()

	TransitionManager.fadeIn()
	await TransitionManager.transition_finished
	var tree := zone_node.get_tree()
	zone_node.release_player() # antes de cerrar la escena, no durante (evita crash)
	tree.call_deferred("change_scene_to_file", zone_paths[new_zone_id])

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
	return "Desconocido"

func _process_street_risk() -> void:
	var chance : float = PlayerManager.get_street_risk_chance(STREET_RISK_BASE_CHANCE)
	var roll : float = PlayerManager.rng.randf()

	if roll > chance:
		return

	TimeManager.add_to_current_time(STREET_RISK_TIME_PENALTY)
	PlayerManager.register_street_event()
	street_risk_triggered.emit(chance, roll)
