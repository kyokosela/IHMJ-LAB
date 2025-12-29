extends Resource
class_name ItemData

enum TYPE{
	UNDEFINED,
	CONSUMABLE,
	CLOTH,
	OBJECT
}

@export_group("General Info")
@export var texture : Texture2D
@export var item_name : String = ""
@export var item_unique_name : String = ""
@export var max_stack : int = 1
@export var is_stackable : bool = true
@export_custom(PROPERTY_HINT_MULTILINE_TEXT,"") var item_description : String = ""
@export_group("Behaviors")
@export var item_type : TYPE = TYPE.UNDEFINED
@export var behaviours : Array[ItemBehavior]
@export var base_decay : float = 1.0 ## Determina el valor base de deterioro en cualquier condicion. No confundir con el multiplier del condition modifier, este base decay siempre estara activo
@export var modifiers : Array[ConditionModifier] ## Modificadores por ambientes que aplicara este item
@export var unique_item : bool = false
