class_name InputTrigger
extends Reference

export var mouse_button = 0
export var scancode = 0
export var doubleclick = false
export var shift = false
export var alt = false
export var control = false
export var command = false
export var meta = false

func is_held():
	var conditions_fulfilled = 0
	if mouse_button and Input.is_mouse_button_pressed(mouse_button): conditions_fulfilled += 1
	# Can't check if a double click is held
	if shift and Input.is_key_pressed(KEY_SHIFT): conditions_fulfilled += 1
	if alt and Input.is_key_pressed(KEY_ALT): conditions_fulfilled += 1
	if OS.get_name() == "OSX":
		if control and Input.is_key_pressed(KEY_CONTROL): conditions_fulfilled += 1
		if command and Input.is_key_pressed(KEY_META): conditions_fulfilled += 1
	else:
		if control and Input.is_key_pressed(KEY_CONTROL): conditions_fulfilled += 1
		if meta and Input.is_key_pressed(KEY_META): conditions_fulfilled += 1
	if scancode and Input.is_key_pressed(scancode): conditions_fulfilled += 1
	
	var conditions_required = int(mouse_button > 0) + int(scancode > 0) + int(doubleclick) + int(shift) + int(alt) + int(control) + int(meta or command)
	if conditions_required == 0:
		return false

	return conditions_fulfilled == conditions_required

func is_pressed(e):
	var conditions_fulfilled = 0
	if e is InputEventMouseButton:
		if e.is_pressed() and mouse_button and e.button_index == mouse_button: conditions_fulfilled += 1
		if e.is_pressed() and doubleclick and e.doubleclick: conditions_fulfilled += 1
	if e is InputEventWithModifiers:
		if shift and e.shift: conditions_fulfilled += 1
		if alt and e.alt: conditions_fulfilled += 1
		if control and e.control: conditions_fulfilled += 1
		if command and e.command: conditions_fulfilled += 1
		if meta and e.meta: conditions_fulfilled += 1
	if e is InputEventKey:
		if e.is_pressed() and scancode and scancode == e.scancode: conditions_fulfilled += 1
	
	var conditions_required = int(mouse_button > 0) + int(scancode > 0) + int(doubleclick) + int(shift) + int(alt) + int(command) + int(control) + int(meta)
	if conditions_required == 0:
		return false

	return conditions_fulfilled == conditions_required

func get_text():
	var text = ""
	if alt:
		text += "Alt+"
	if control:
		text += "Ctrl+"
	if command:
		text += "Cmd+"
	if shift:
		text += "Shift+"
	if meta:
		text += "Win+"
	if scancode:
		text += OS.get_scancode_string(scancode)
	if mouse_button:
		if mouse_button == BUTTON_LEFT and doubleclick:
			text += "Doubleclick"
		else:
			if doubleclick:
				text += "Double "
			match mouse_button:
				BUTTON_LEFT:
					text += "Left-Click"
				BUTTON_RIGHT:
					text += "Right-Click"
				BUTTON_MIDDLE:
					text += "Middle-Click"
				BUTTON_WHEEL_DOWN:
					text += "Wheel Down"
				BUTTON_WHEEL_UP:
					text += "Wheel Up"
				BUTTON_WHEEL_LEFT:
					text += "Wheel Left"
				BUTTON_WHEEL_RIGHT:
					text += "Wheel Right"
	return text