extends Panel

signal received_input_event(e)

func _gui_input(e):
	if e is InputEventMouseButton and e.is_pressed():
		emit_signal("received_input_event", e)
		accept_event()

func _input(e):
	if e is InputEventKey and e.is_pressed():
		if not [KEY_CONTROL, KEY_SHIFT, KEY_ALT, KEY_META].has(e.scancode):
			emit_signal("received_input_event", e)
			accept_event()