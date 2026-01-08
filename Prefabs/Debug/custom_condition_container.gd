extends FoldableContainer
class_name ConditionContainerDebug

@onready var rich_text_label: RichTextLabel = $RichTextLabel

var condition : CustomCondition

func update():
	title = condition.condition
	if condition == null: queue_free() 
	rich_text_label.text = """
	Value: {value}
	Base Decay: {decay}
	Env Condition {env}
	Modifiers {modifiers}
	Condition Thresholds: WIP
	Can Decay {can_decay}
	""".format({
		"value": condition.value,
		"decay": condition.base_decay_time,
		"env" : condition.enviroment_condition,
		"modifiers": condition.modifiers,
		"can_decay": condition.can_decay
	})
