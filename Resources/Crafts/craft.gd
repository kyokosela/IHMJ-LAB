extends Resource
class_name Crafts

@export var check_order : int

@export_group("Recipe")
@export var needed_items = Array[CraftSlot]

@export_group("Result")
@export var result_item : Item
@export var result_quantity : int
@export var result_state : String = ""
