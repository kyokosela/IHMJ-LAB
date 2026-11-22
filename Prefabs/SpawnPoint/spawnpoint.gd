extends Marker2D
class_name SpawnPoint

@export var entity : String
## Zona de la que viene Mayui para usar este punto (ZoneManager.ZONES: 0 apartamento, 1 lobby, 2 oficina,
## 3 comercial). -1 = punto general: se usa al empezar o si no hay uno especifico para la zona de origen.
@export var from_zone : int = -1

func _ready() -> void:
	add_to_group("spawn_point")
