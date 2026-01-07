extends FoldableContainer
class_name StatContainerDebug

@export var stat_info: RichTextLabel
@onready var increase_button : Button = %Increment
@onready var decrease_button : Button = %Decrease
@onready var spin_box : SpinBox = %SpinBox

var stat : Stat

func _ready() -> void:
	increase_button.pressed.connect(func () : PlayerManager.increase_stat(stat.stat_unique_name, spin_box.value))
	decrease_button.pressed.connect(func () : PlayerManager.decrease_stat(stat.stat_unique_name, spin_box.value))

func info_update():
	title = stat.stat_unique_name
	stat_info.text = \
	"""
	Signals: {signals} \n
	Callables: {callables} \n
	Flags: {flags}
	""".format({
		"signals": PlayerManager.get_stat_connections(\
				stat.stat_unique_name,\
				PlayerManager.CONNECTION_PARAM.SIGNAL),
		"callables": PlayerManager.get_stat_connections(\
				stat.stat_unique_name,\
				PlayerManager.CONNECTION_PARAM.CALLABLE),
		"flags": PlayerManager.get_stat_connections(\
				stat.stat_unique_name,\
				PlayerManager.CONNECTION_PARAM.FLAGS),
	})
