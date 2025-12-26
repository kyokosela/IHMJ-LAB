@tool
extends Resource
class_name Item

@export var item_name : String = ""
@export var item_unique_name : String = "": # En caso de que items diferentes puedan tener el mismo nombre para algo secreto no se
	get: 
		if item_unique_name == "": return item_name
		else: return item_unique_name
	set(value):
		if  value == "": item_unique_name = item_name
		else: item_unique_name = value
@export var texture : Texture2D
@export var is_stackable : bool = false
@export var max_stack : int = 1
@export var item_description : String = ""
@export var unique_item : bool = false
