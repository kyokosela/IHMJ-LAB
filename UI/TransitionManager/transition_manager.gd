extends CanvasLayer

signal transition_finished

@onready var color_rect : ColorRect = %ColorRect

@export var transition_speed : float = 1

func fadeIn(_custom_time : float = transition_speed) -> void :
	var tw = create_tween()
	tw.tween_property(color_rect, "color:a", 1, _custom_time)
	tw.finished.connect(transition_finished.emit)

func fadeOut(_custom_time : float = transition_speed) -> void :
	var tw = create_tween()
	tw.tween_property(color_rect, "color:a", 0, _custom_time)
	tw.finished.connect(transition_finished.emit)
