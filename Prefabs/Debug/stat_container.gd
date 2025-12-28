extends FoldableContainer
class_name StatContainerDebug

@export var stat_info: RichTextLabel

var stat : Stat
	
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
