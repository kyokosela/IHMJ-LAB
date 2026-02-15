extends MailEvent
class_name TypingEvent

@export_multiline var target_text: String ## esto es obvio
@export var allow_errors := false ## cuando es falso ignora las teclas mal escritas

## Track stress-induced typos for visual feedback
var _stress_typo_count: int = 0

func execute(container: Control, data: MailEntry) -> void:
	var l = RichTextLabel.new()
	l.bbcode_enabled = true
	l.fit_content = true
	l.scroll_active = false
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	l.focus_mode = Control.FOCUS_ALL
	l.mouse_filter = Control.MOUSE_FILTER_STOP
	container.add_child(l)
	
	var instruction = Label.new()
	instruction.text = "(Escribe el coso)"
	instruction.modulate = Color(1,1,1,0.5)
	container.add_child(instruction)
	
	l.set_meta("curr_idx", 0)
		
	_update(l, 0)
	
	l.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			l.grab_focus()
			return
		
		if event is InputEventKey and event.pressed and !event.echo:
			var key_unicode = event.unicode
			if key_unicode == 0: return # ignore shift, ctrl...
			
			var curr_idx = l.get_meta("curr_idx")
			
			if curr_idx >= target_text.length(): return
				
			var typed = char(key_unicode)
			var target = target_text[curr_idx]
			
			if typed == target:
				# Check for STRESS-induced typo before accepting correct keystroke
				if check_stress_failure():
					# STRESS caused a typo - flash feedback but don't advance
					_stress_typo_count += 1
					l.modulate = Color(1.0, 0.7, 0.5)  # Orange flash
					await l.get_tree().create_timer(0.15).timeout
					l.modulate = Color(1, 1, 1, 1)
					return
				
				curr_idx += 1
				l.set_meta("curr_idx", curr_idx)
				_update(l, curr_idx)
				
			if curr_idx >= target_text.length(): data.solve()
			
		else:
			if !allow_errors:
				pass
	)
	
	l.grab_focus()
	
func _update(label: RichTextLabel, idx: int) -> void:
	var typed = target_text.substr(0, idx).replace("[", "[lb]")
	var remaining = target_text.substr(idx).replace("[", "[lb]")
	
	label.text = "[color=green]%s[/color][color=#555555]%s[/color]" % [typed, remaining]
