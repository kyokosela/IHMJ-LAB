extends Resource
class_name Crafts

@export var check_order : bool
@export var needed_time : String  ="00:00"
var time_left : String

@export_group("Recipe")
@export var needed_items : Array[CraftSlot]
@export var needed_util : String = ""

@export_group("Result")
@export var result_item : ItemData
