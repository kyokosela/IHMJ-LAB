extends Resource
class_name ItemData

enum TYPE{
	UNDEFINED,
	CONSUMABLE,
	CLOTH,
	OBJECT,
	TOOL,       ## Items que proveen utils (pot, pan, knife)
	CONTAINER   ## Items que pueden contener otros (mug, plate)
}
enum QUALITY {
	A,
	B,
	C
}

@export_group("General Info")
@export var texture : Texture2D
@export var item_name : String = ""
@export var item_unique_name : String = ""
@export var item_quality : QUALITY
@export_custom(PROPERTY_HINT_MULTILINE_TEXT,"") var item_description : String = ""

@export_group("Behaviors")
@export var item_type : TYPE = TYPE.UNDEFINED
@export var behavior : ItemBehavior
@export var base_decay_time : int = 1 ## Determina el tiempo base en el que un objeto se deteriorara en condiciones bases (minutos).
@export var modifiers : Array[ConditionModifier] ## Modificadores por ambientes que aplicara este item
@export var consume_after_use : bool = false
@export var can_use : bool = true
@export var uses : int = 1
@export var unique_item : bool = false
@export var custom_conditions : Array[CustomCondition]

@export_group("Utils")
## Utils que este item provee (ej: pot = ["cookware", "container"])
## Usado para validar si puede entrar en ciertas estaciones
@export var provided_utils : Array[String] = []

@export_group("Holder")
## Si este item puede contener otros items (ej: mug, plate)
@export var is_holder : bool = false
## Tipos de items que puede contener (vacío = cualquiera)
@export var holdable_types : Array[TYPE] = []

@export_group("Durability")
## Si este item puede romperse cuando el player tiene estrés
@export var can_break : bool = false
## Probabilidad base de rotura (0.0 - 1.0) cuando el player tiene estrés
@export_range(0.0, 1.0) var break_chance : float = 0.1

func get_quality_percentage() -> float:
	match item_quality:
		QUALITY.A: return 0.75
		QUALITY.B: return 0.40
		QUALITY.C: return 0
		_: return 0

func get_modifiers_applies() -> Array[String]: ##Debug
	var value :Array[String] = []
	for x in modifiers:
		value.append(x.applies_to)
	return value

## Verifica si este item provee un util específico
func has_util(util_name: String) -> bool:
	return util_name in provided_utils

## Verifica si este item provee alguno de los utils requeridos
func has_any_util(required_utils: Array[String]) -> bool:
	for util in required_utils:
		if util in provided_utils:
			return true
	return false
