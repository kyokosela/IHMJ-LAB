extends InventoryContainer

@export var available_crafts : Array[Crafts]

var result : Item

func _ready():
	if inventory == null:
		inventory = InventoryComponent.new(3)
		add_child(inventory)

func update_craft() -> void:
	pass
		
