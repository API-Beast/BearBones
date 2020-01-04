tool
extends Control
class_name SliderBox

export var text = ""
export var min_value = 0.0
export var max_value = 100.0
export var soft_min = -99999.9
export var soft_max = 99999.9
export var step = 1.0
export var value = 50.0 setget set_value
export(float, 0.0, 1.0, 0.01) var ratio = 0.5 setget set_ratio, get_ratio

export(float, -10.0, 10.0, 0.001) var curve_shape = 1

export(StyleBox) var box
export(StyleBox) var fill
export(StyleBox) var soft_limits

export(bool) var show_sign = false

export(bool) var force_step = true
export(bool) var integer_input = false
export(bool) var reverse_direction = false

enum{ STATE_IDLE, STATE_FOCUS, STATE_DRAGGING }

var state = STATE_IDLE

signal ratio_changed(ratio)
signal value_changed(value)
signal changed()

func _ready():
	$LineEdit.connect("focus_exited", self, "reset_line_edit")

func _draw():
	var f = ease(self.ratio, curve_shape)

	$Label.text = text
	$Label.visible = !text.empty()

	draw_style_box(box, Rect2(Vector2(0, 0), rect_size))
	
	var left := 0.0
	var right := 1.0
	if soft_min > min_value:
		left = ease((soft_min - min_value) / (max_value - min_value), curve_shape)
		draw_style_box(soft_limits, Rect2(Vector2(0, 0), rect_size*Vector2(left, 1.0)))
	if soft_max < max_value:
		right = ease((soft_max - min_value) / (max_value - min_value), curve_shape)
		draw_style_box(soft_limits, Rect2(rect_size*Vector2(right, 0.0), rect_size*Vector2(1.0 - right, 1.0)))
		
	if reverse_direction:
		draw_style_box(fill, Rect2(rect_size*Vector2(1.0 - f, 0.0), rect_size*Vector2(f-left, 1.0)))
	else:
		draw_style_box(fill, Rect2(rect_size*Vector2(left, 0.0), rect_size*Vector2(f-left, 1.0)))
	
func set_ratio(new_ratio):
	if is_inf(new_ratio) or is_nan(new_ratio):
		new_ratio = 1.0
	ratio = clamp(new_ratio, 0.0, 1.0)
	self.value = stepify(min_value + (max_value-min_value)*ratio, step)
	
func get_ratio():
	return (value - min_value) / (max_value-min_value)

func set_value(new_val):
	if force_step:
		new_val = stepify(new_val, step)
	value = clamp(clamp(new_val, min_value, max_value), soft_min, soft_max)
	if integer_input:
		value = round(value)

	if has_node("LineEdit") and $LineEdit.text != str(value):
		if show_sign:
			$LineEdit.text = "%*+.*f" % [str(max_value).length(), step_decimals(step), value]
		else:
			$LineEdit.text = "%*.*f" % [str(max_value).length(), step_decimals(step), value]
	update()

func text_edited(new_text):
	self.value = float(new_text)
	emit_signal("ratio_changed", self.ratio)
	emit_signal("value_changed", self.value)
	emit_signal("changed")
	update()

func reset_line_edit():
	text_edited($LineEdit.text)
	$LineEdit.deselect()
	$LineEdit.release_focus()
	$LineEdit.focus_mode = FOCUS_NONE
	$LineEdit.mouse_filter = MOUSE_FILTER_IGNORE

func enable_line_edit():
	$LineEdit.focus_mode = FOCUS_CLICK
	$LineEdit.mouse_filter = MOUSE_FILTER_STOP
	$LineEdit.grab_focus()
	$LineEdit.select_all()

func mouse_drag_event(event):
	var f = event.position.x / rect_size.x
	if curve_shape < 1.0:
		f = 1.0 - pow(1.0 - f, curve_shape)
	elif curve_shape > 1.0:
		f = pow(f, 1.0/curve_shape)
	if reverse_direction:
		f = 1.0 - f
	self.ratio = f
	emit_signal("ratio_changed", self.ratio)
	emit_signal("value_changed", self.value)
	emit_signal("changed")
	update()

var focus_time = 0.0
func _process(delta_time):
	if state == STATE_FOCUS:
		focus_time += delta_time
		if focus_time > 0.10:
			if Input.get_mouse_button_mask() & BUTTON_MASK_LEFT:
				state = STATE_DRAGGING
			else:
				state = STATE_IDLE
				enable_line_edit()
			focus_time = 0.00
	if state == STATE_DRAGGING:
		if not (Input.get_mouse_button_mask() & BUTTON_MASK_LEFT):
			state = STATE_IDLE

func _gui_input(event):
	match state:
		STATE_IDLE:
			if event is InputEventMouse:
				if event.button_mask & BUTTON_MASK_LEFT:
					state = STATE_FOCUS
					focus_time = 0.00
					accept_event()
		STATE_FOCUS:
			if event is InputEventMouseMotion:
				if event.button_mask & BUTTON_MASK_LEFT:
					state = STATE_DRAGGING
					mouse_drag_event(event)
					accept_event()
			elif event is InputEventMouseButton:
				if not event.is_pressed():
					state = STATE_IDLE
					enable_line_edit()
					return
		STATE_DRAGGING:
			if event is InputEventMouse:
				if event.button_mask & BUTTON_MASK_LEFT:
					mouse_drag_event(event)
					accept_event()




