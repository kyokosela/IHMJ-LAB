extends Node

enum ZONES {
	APARTAMENT_ONE
}

const zone_paths : Array[String] = [
	"res://Scenes/World/Apartament_one.tscn"
]

var current_zone : int = ZONES.APARTAMENT_ONE
var previous_zone : int = -1
var zone_node : World :
	set(_value) :
		zone_node = _value
		TransitionManager.fadeOut()

var energy_cost_base : float = 2
var energy_cost_incremental : float = 0

var time_cost_base : String = "00:05"
var time_cost_incremental : String = "00:05"

func change_zone(new_zone_id : ZONES) -> void :
	
	if new_zone_id == previous_zone : 
		energy_cost_incremental = energy_cost_base
		time_cost_incremental = time_cost_base
	else : 
		energy_cost_incremental += energy_cost_base
		time_cost_incremental = TimeUtils.increase_time(time_cost_incremental, time_cost_base)
	
	previous_zone = current_zone
	current_zone = new_zone_id
	
	PlayerManager.decrease_stat("ENERGY", energy_cost_incremental)
	TimeManager.add_to_current_time(time_cost_incremental)
	
	TransitionManager.fadeIn()
	await TransitionManager.transition_finished
	zone_node.get_tree().call_deferred("change_scene_to_file", zone_paths[new_zone_id])
