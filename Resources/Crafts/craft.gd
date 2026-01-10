extends Resource
class_name Crafts

@export var check_order : bool
@export var needed_time : String

@export_group("Recipe")
@export var needed_items : Array[CraftSlot]

@export_group("Result")
@export var result_item : ItemData
@export var result_state : ItemState
