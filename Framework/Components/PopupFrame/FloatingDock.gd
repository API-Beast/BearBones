extends Control

export var resizable = true

func _ready():
	set_as_toplevel(true)

const IDLE = 0
const MOVING = 1
const RESIZE = 2

var state = IDLE
var state_mouse_pos = Vector2(0, 0)
var state_targets = []

signal on_state_changed()

func get_cursor_shape(position=Vector2(0, 0)):
	var w = rect_size.x
	var h = rect_size.y
	var r = w - 5
	var b = h - 5
	if Rect2(0, h-10, 10, 10).has_point(position) or Rect2(w-10, 0, 10, 10).has_point(position):
		return CURSOR_BDIAGSIZE
	if Rect2(0, 0, 10, 10).has_point(position) or Rect2(w-10, h-10, 10, 10).has_point(position):
		return CURSOR_FDIAGSIZE
	if Rect2(0, 0, 5, h).has_point(position) or Rect2(w-5, 0, 5, h).has_point(position):
		return CURSOR_HSIZE
	if Rect2(0, 0, w, 5).has_point(position) or Rect2(0, h-5, w, 5).has_point(position):
		return CURSOR_VSIZE
	if Rect2(0, 0, w, 20).has_point(position):
		return CURSOR_MOVE
	return CURSOR_ARROW

func _process(delta):
	if state != IDLE:
		if not Input.is_mouse_button_pressed(BUTTON_LEFT) and not Input.is_mouse_button_pressed(BUTTON_RIGHT):
			change_state(IDLE)
	
	match state:
		RESIZE:
			var new_pos = get_viewport().get_mouse_position()
			var delta_pos = new_pos - state_mouse_pos

			var rect = Rect2(rect_position, rect_size)
			var min_size = get_combined_minimum_size()
			for target in state_targets:
				match target[0]:
					"position":
						var old_end = rect.end
						if target[1] == "x":
							rect.position.x += delta_pos.x
						else:
							rect.position.y += delta_pos.y
						rect.end = old_end
					"end":
						if target[1] == "x":
							rect.end.x += delta_pos.x
						else:
							rect.end.y += delta_pos.y

			if rect.size.x >= min_size.x:
				rect_position.x = rect.position.x
				rect_size.x = rect.size.x
				state_mouse_pos.x = new_pos.x

			if rect.size.y >= min_size.y:
				rect_position.y = rect.position.y
				rect_size.y = rect.size.y
				state_mouse_pos.y = new_pos.y
		MOVING:
			var new_pos = get_viewport().get_mouse_position()
			var delta_pos = new_pos - state_mouse_pos
			state_mouse_pos = new_pos
			rect_position += delta_pos


func change_state(new_state):
	if is_inside_tree():
		if new_state != state:
			emit_signal("on_state_changed")
		state = new_state
		state_mouse_pos = get_viewport().get_mouse_position()
		self.raise()

func _gui_input(e):
	if state == IDLE:
		if e is InputEventMouseMotion:
			mouse_default_cursor_shape = get_cursor_shape(e.position)
		if e is InputEventMouse:
			if e.button_mask & BUTTON_MASK_RIGHT:
				change_state(MOVING)
			elif e.button_mask & BUTTON_MASK_LEFT:
				match(get_cursor_shape(e.position)):
					CURSOR_VSIZE:
						var is_top = e.position.y < (rect_size.y / 2.0)
						if is_top:
							state_targets = [["position", "y"]]
						else:
							state_targets = [["end", "y"]]
						change_state(RESIZE)
					CURSOR_HSIZE:
						var is_left = e.position.x < (rect_size.x / 2.0)
						if is_left:
							state_targets = [["position", "x"]]
						else:
							state_targets = [["end", "x"]]
						change_state(RESIZE)
					CURSOR_BDIAGSIZE, CURSOR_FDIAGSIZE:
						var quadrant = Vector2(e.position.x > (rect_size.x / 2.0), e.position.y > (rect_size.y / 2.0))
						state_targets = [null, null]
						if quadrant.x == 0:
							state_targets[0] = ["position", "x"]
						else:
							state_targets[0] = ["end", "x"]
						if quadrant.y == 0:
							state_targets[1] = ["position", "y"]
						else:
							state_targets[1] = ["end", "y"]
						change_state(RESIZE)
					CURSOR_MOVE:
						change_state(MOVING)
					_:
						pass