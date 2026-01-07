extends Resource
class_name ContainerEnvironment

@export var temperature : float = 20.0
@export var humidity : float = 40.0
@export var is_refrigerated : bool = false
@export var is_dark : bool = false

func get_conditions() -> Array[String]:
	var total_conditions : Array[String] = []
	total_conditions.append(get_temperature_condition())
	total_conditions.append(get_humidity_condition())
	
	total_conditions.append_array(get_custom_conditions())
	
	return total_conditions
	
func get_temperature_condition():
	if temperature <= 0: return "cold"
	elif temperature <= 30.0: return "warm"
	else: return "hot"

func get_humidity_condition():
	if humidity < 30.0: return "dry"
	elif humidity < 60.0: return "normal"
	elif humidity < 80.0: return "humid"
	else: return "wet"

func get_custom_conditions() -> Array[String]:
	var customs : Array[String]
	
	if is_refrigerated: customs.append("refrigerated")
	if is_dark: customs.append("dark")
	
	return customs

func get_properties()-> Array[String]:
	var properties : Array[String]
	
	properties.append("temperature")
	properties.append("humidity")
	if is_refrigerated: properties.append("refrigerated")
	if is_dark: properties.append("dark")
	
	return properties
