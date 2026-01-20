extends FoldableContainer
class_name ItemContainerDebug
@onready var texture_rect: TextureRect = $HBoxContainer/TextureRect
@onready var rich_text_label: RichTextLabel = $HBoxContainer/VBoxContainer/RichTextLabel
@onready var foldable_container: FoldableContainer = $HBoxContainer/VBoxContainer/FoldableContainer
@onready var v_box_container: VBoxContainer = $HBoxContainer/VBoxContainer/FoldableContainer/VBoxContainer

const CUSTOM_CONDITION_CONTAINER = preload("uid://b0f7lqvnstjs2")
var item : Item
var current_slot_index : int = -1

func set_slot_index(index: int):
	current_slot_index = index
	title = "[%d] %s" % [index, tr(item.data.item_name)]

func _ready() -> void:
	title = tr(item.data.item_name)
	item.item_changed.connect(update)
	# Usar condiciones de la instancia (item.custom_conditions) en lugar del data
	for x in item.custom_conditions:
		var condition_container : ConditionContainerDebug = CUSTOM_CONDITION_CONTAINER.instantiate()
		condition_container.condition = x
		v_box_container.add_child(condition_container)

func update():
	if item == null: queue_free()
	var data : ItemData = item.data
	texture_rect.texture = data.texture if data.texture else PlaceholderTexture2D.new()
	
	# Obtener información del held_item
	var held_info = "[color=gray]None[/color]"
	if item.held_item != null:
		var h = item.held_item
		var h_conds = ""
		for cc in h.custom_conditions:
			h_conds += "%s: %.1f | " % [cc.condition, cc.value]
			
		held_info = """
		[color=green]%s[/color] (%s)
		Cond: %.1f
		States: %s
		[color=orange]%s[/color]
		""" % [h.data.item_name, h.data.item_unique_name, h.condition, str(h.states.keys()), h_conds]
	
	rich_text_label.text = """
	Slot: {slot}
	Display: {display} ({unique})
	Condition: {condition}
	States: {states}
	Type: {type} | Quality: {quality}
	Decay: {decay} min
	
	[b]HELD ITEM:[/b] {held_info}
	""".format({
		"display": data.item_name,
		"unique": data.item_unique_name,
		"condition": "%.1f" % item.condition,
		"states": item.states.keys(),
		"type": ItemData.TYPE.keys()[data.item_type],
		"quality": ItemData.QUALITY.keys()[data.item_quality],
		"decay": data.base_decay_time,
		"held_info": held_info,
		"slot": current_slot_index
	})
	
	for x : ConditionContainerDebug in v_box_container.get_children():
		if x is not ConditionContainerDebug: continue
		x.update()
