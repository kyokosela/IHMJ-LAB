extends Resource
class_name ItemData

enum TYPE{
	UNDEFINED,
	CONSUMABLE,
	CLOTH,
	OBJECT
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
@export var uses : int = 1
@export var unique_item : bool = false
@export var custom_conditions : Array[CustomCondition]

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
