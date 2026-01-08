extends FoldableContainer
class_name ItemContainerDebug
@onready var texture_rect: TextureRect = $HBoxContainer/TextureRect
@onready var rich_text_label: RichTextLabel = $HBoxContainer/VBoxContainer/RichTextLabel
@onready var foldable_container: FoldableContainer = $HBoxContainer/VBoxContainer/FoldableContainer
@onready var v_box_container: VBoxContainer = $HBoxContainer/VBoxContainer/FoldableContainer/VBoxContainer

const CUSTOM_CONDITION_CONTAINER = preload("uid://b0f7lqvnstjs2")
var item : Item

func _ready() -> void:
	title = tr(item.data.item_name)
	item.item_changed.connect(update)
	for x in item.data.custom_conditions:
		var condition_container : ConditionContainerDebug = CUSTOM_CONDITION_CONTAINER.instantiate()
		condition_container.condition = x
		v_box_container.add_child(condition_container)

func update():
	if item == null: queue_free()
	var data : ItemData = item.data
	texture_rect.texture = data.texture if data.texture else PlaceholderTexture2D.new()
	rich_text_label.text = """
	Item Display Name: {display}
	Item Unique Name: {unique}
	Item Condition: {condition}
	Item States: {states}
	Item Type: {type}
	Item Quality: {type}
	Item Behavior: {behavior}
	Item Modifier: {modifiers}
	Base Decay: {decay}
	""".format({
		"display": data.item_name,
		"unique": data.item_unique_name,
		"condition": item.condition,
		"states": item.states.keys(),
		"type": data.item_type,
		"behavior" : data.behavior,
		"modifiers" : data.get_modifiers_applies(),
		"decay": data.base_decay_time
	})
	
	for x : ConditionContainerDebug in v_box_container.get_children():
		if x is not ConditionContainerDebug: continue
		x.update()
