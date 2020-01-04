extends HBoxContainer

export(StyleBox) var box_active
export(StyleBox) var box_active_hover
export(StyleBox) var box_inactive
export(StyleBox) var box_inactive_hover

export(StyleBox) var box_cut_active
export(StyleBox) var box_cut_active_hover
export(StyleBox) var box_cut_inactive
export(StyleBox) var box_cut_inactive_hover

export(Font) var font

var cut_buttons = []
var active_button = null

signal value_changed(new_value)

func style_inactive(btn):
	if cut_buttons.has(btn):
		btn.add_stylebox_override("hover", box_cut_inactive_hover)
		btn.add_stylebox_override("focus", box_cut_inactive)
	else:
		btn.add_stylebox_override("hover", box_inactive_hover)
		btn.add_stylebox_override("focus", box_inactive)

func style_active(btn):
	if cut_buttons.has(btn):
		btn.add_stylebox_override("hover", box_cut_active_hover)
		btn.add_stylebox_override("focus", box_cut_active)
	else:
		btn.add_stylebox_override("hover", box_active_hover)
		btn.add_stylebox_override("focus", box_active)

func add_button(id, label, cut = false):
	var btn = Button.new()
	btn.name = id
	btn.text = label
	btn.toggle_mode = true
	btn.action_mode = 0

	if cut:
		cut_buttons.push_back(btn)
		btn.add_stylebox_override("normal", box_cut_inactive)
		btn.add_stylebox_override("pressed", box_cut_active)
	else:
		btn.add_stylebox_override("normal", box_inactive)
		btn.add_stylebox_override("pressed", box_active)
	btn.add_font_override("font", font)

	self.add_child(btn)
	style_inactive(btn)
	btn.connect("button_down", self, "on_button_pressed", [btn])
	btn.connect("button_up", self, "on_button_up", [btn])
	if active_button == null:
		activate_button(btn)
	return btn

func on_button_pressed(btn):
	if active_button != btn:
		activate_button(btn)
		emit_signal("value_changed", btn.name)

func on_button_up(btn):
	btn.pressed = true

func activate_button(btn):
	active_button = btn
	for button in get_children():
		if button is Button:
			button.pressed = false
			style_inactive(button)
	active_button.pressed = true
	style_active(active_button)

func set_value(val):
	if val != get_value():
		activate_button(get_node(val))

func get_value():
	if active_button:
		return active_button.name
	return null