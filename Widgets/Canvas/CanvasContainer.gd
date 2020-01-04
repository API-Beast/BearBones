extends Control

export var zoom = 0
export var min_zoom = 0.1
export var max_zoom = 8.0
export var discrete_zoom_in = true
export var discrete_zoom_out = false
export var downsample = true
export var upsample = false
export var pixel_perfect = false
export var allowed_overscroll = 0.20
export var context_disabled = false

export var scroll_offset = Vector2(0, 0)

export var reference_zoom = 1.0
export var reference_position = Vector2(0, 0)
export var reference_top_left = Vector2(-300, -300)
export var reference_bottom_right = Vector2(300, 300)

export var actual_size = Vector2(600, 600)

export(StyleBox) var panel

var viewport_scale = Vector2(1.0, 1.0)

signal user_scroll_and_zoom()

func _ready():
	connect("resized", self, "canvas_adjust")
	canvas_adjust()

var cur_mouse_global_position = Vector2(0, 0)
var cur_mouse_position = Vector2(0, 0)
var last_mouse_pos = null

func _gui_input(e):
	if e is InputEventMouse:
		cur_mouse_global_position = e.global_position
		cur_mouse_position = e.position

	var action = Actions.find_triggered_action(e)
	match action:
		"OpenContext":
			if not context_disabled and false:
				open_context()
				accept_event()
		"ZoomInFine":
			partial_zoom(0.75, cur_mouse_position)
			accept_event()
		"ZoomOutFine":
			partial_zoom(-0.75, cur_mouse_position)
			accept_event()
		"ZoomIn":
			partial_zoom(2.00, cur_mouse_position)
			accept_event()
		"ZoomOut":
			partial_zoom(-2.00, cur_mouse_position)
			accept_event()

	if e is InputEventMouse:
		if Actions.is_held("MoveCanvas"):
			var ret = false
			if last_mouse_pos:
				scroll_by(cur_mouse_global_position - last_mouse_pos)
				accept_event()
				ret = true
			last_mouse_pos = cur_mouse_global_position
			if ret:
				return
		else:
			last_mouse_pos = null
			
	$Viewport.input(e)

func calc_limits():
	var limits = Rect2(reference_top_left, reference_bottom_right - reference_top_left)
	var ref_size = (rect_size / calc_effective_zoom(zoom)) * (1.00 + allowed_overscroll)
	var growth = ref_size - limits.size
	if growth.x > 0:
		limits = limits.grow_individual(growth.x, 0, growth.x, 0)
	if growth.y > 0:
		limits = limits.grow_individual(0, growth.y, 0, growth.y)
	return limits

func limit_scroll():
	var screen_size = $Viewport.size / calc_effective_zoom(zoom)
	var camera_pos = reference_position - (screen_size * 0.5) + scroll_offset
	var screen_rect = Rect2(camera_pos, screen_size)
	var limits = calc_limits()

	if screen_rect.position.x < limits.position.x:
		scroll_offset.x += (limits.position.x - screen_rect.position.x)
	if screen_rect.position.y < limits.position.y:
		scroll_offset.y += (limits.position.y - screen_rect.position.y)
	if screen_rect.end.x > limits.end.x:
		scroll_offset.x += (limits.end.x - screen_rect.size.x)  - screen_rect.position.x
	if screen_rect.end.y > limits.end.y:
		scroll_offset.y += (limits.end.y - screen_rect.size.y)  - screen_rect.position.y

func get_camera_transform(scale):
	var screen_size = $Viewport.size * scale
	var camera_pos = reference_position - (screen_size * 0.5) + scroll_offset
	var transform = Transform2D(Vector2(scale.x, 0), Vector2(0, scale.y), camera_pos.round())
	transform = transform.affine_inverse()
	return transform

func _draw():
	update_camera_transform()

	if material:
		material.set_shader_param("rectSize", rect_size)
		material.set_shader_param("virtualSize", $Viewport.size)
		material.set_shader_param("anchor", $Viewport.canvas_transform.xform(Vector2(0, 0)))
	elif panel:
		draw_style_box(panel, Rect2(Vector2(0, 0), rect_size))

	var position = rect_global_position.ceil() - rect_global_position
	draw_texture_rect($Viewport.get_texture(), Rect2(position, rect_size), false)

	var screen_size = $Viewport.size / calc_effective_zoom(zoom)
	var limits = Rect2(reference_top_left, reference_bottom_right - reference_top_left)
	var camera_pos = reference_position - (screen_size * 0.5) + scroll_offset
	var screen_rect = Rect2(camera_pos, screen_size)

	$HScrollBar.min_value = limits.position.x
	$HScrollBar.max_value = limits.end.x
	$HScrollBar.page = screen_rect.size.x
	$HScrollBar.value = screen_rect.position.x
	$HScrollBar.visible = $HScrollBar.page < limits.size.x

	$VScrollBar.min_value = limits.position.y
	$VScrollBar.max_value = limits.end.y
	$VScrollBar.page = screen_rect.size.y
	$VScrollBar.value = screen_rect.position.y
	$VScrollBar.visible = $VScrollBar.page < limits.size.y

func _process(delta):
	var level = calc_effective_zoom(zoom)
	# Snap to full increments when zoom is discrete
	if (level < 1.0 and discrete_zoom_out) or (level > 1.0 and discrete_zoom_in):
		zoom = lerp(round(zoom), zoom, pow(0.10, delta*10))

func calc_effective_zoom(z):
	var level = clamp(get_zoom_level(z), min_zoom, max_zoom)
	if (level < 1.0 and discrete_zoom_out) or (level > 1.0 and discrete_zoom_in):
		level = clamp(get_zoom_level(round(z)), min_zoom, max_zoom)
	if pixel_perfect and (level >= 1.0):
		level = round(level)
	return level

func get_effective_zoom():
	return calc_effective_zoom(zoom)

func set_effective_zoom(z):
	if z < reference_zoom:
		zoom = log(0.8) / log(z)
	else:
		zoom = log(1.5) / log(z)
	scroll_offset = Vector2(0, 0)

	emit_signal("user_scroll_and_zoom")

	update_camera_transform()
	update()

func calc_relative_boundaries():
	var transform = $Viewport.canvas_transform
	var position = reference_top_left
	var size = reference_bottom_right - reference_top_left
	return Rect2(transform.xform(position), transform.basis_xform(size))

func _unhandled_input(e):
	$Viewport.unhandled_input(e)

func canvas_adjust():
	$Viewport.set_size_override(false)
	$Viewport.set_size_override_stretch(false)
	$Viewport.set_attach_to_screen_rect(Rect2(rect_position.ceil(), rect_size))
	$Viewport.propagate_call("canvas_adjust", [self])
	update()

func get_zoom_level(zoom):
	if zoom < 0:
		return pow(0.80, abs(zoom)) * reference_zoom
	else:
		return pow(1.50, zoom) * reference_zoom

func scroll_by(position):
	scroll_offset -= position / calc_effective_zoom(zoom)
	limit_scroll()
	emit_signal("user_scroll_and_zoom")
	update()

func mouse_to_viewport_world_coordinates(position):
	return $Viewport.canvas_transform.affine_inverse().xform(position * viewport_scale)

func update_camera_transform():
	var level = calc_effective_zoom(zoom)
	var scale = Vector2(1.0/level, 1.0/level)
	var scale_viewport = (scale.x>1.0 and upsample) or (scale.x<1.0 and downsample)

	var camera_scale = Vector2(1.0, 1.0)
	viewport_scale = Vector2(1.0, 1.0)

	if scale_viewport:
		viewport_scale = scale
	else:
		camera_scale = scale

	$Viewport.size = rect_size * viewport_scale
	$Viewport.canvas_transform = get_camera_transform(camera_scale)

func partial_zoom(change, position):
	var level = get_zoom_level(zoom)
	if change > 0 and level >= max_zoom:
		return
	if change < 0 and level <= min_zoom:
		return
		
	update_camera_transform()
	var pos1 = mouse_to_viewport_world_coordinates(position)
	zoom += change

	update_camera_transform()
	var pos2 = mouse_to_viewport_world_coordinates(position)
	scroll_offset += (pos1 - pos2)
	limit_scroll()

	emit_signal("user_scroll_and_zoom")

	update_camera_transform()
	update()

func reset():
	zoom = 0
	scroll_offset = Vector2(0, 0)
	update_camera_transform()
	update()

## Context Menu

func _init():
	if not GlobalMenu.has_menu("CanvasContext"):
		GlobalMenu.begin_menu("CanvasContext", "Context: Canvas", true)
		GlobalMenu.add_context_entry("Fit Into Window", "canvas_container", "context_canvas_zoom_fit")
		GlobalMenu.add_context_entry("Fill Window", "canvas_container", "context_canvas_zoom_cover")
		GlobalMenu.add_context_entry("Actual Size", "canvas_container", "context_canvas_zoom_actual_size")
		GlobalMenu.add_context_entry("200% Zoom", "canvas_container", "context_canvas_zoom_2x")
		GlobalMenu.add_context_entry("400% Zoom", "canvas_container", "context_canvas_zoom_4x")

func open_context():
	GlobalMenu.clear_context()
	GlobalMenu.set_context("canvas_container", self)
	App.open_context_menu("CanvasContext")

func context_canvas_zoom_actual_size():
	set_effective_zoom(1.0)

func context_canvas_zoom_2x():
	set_effective_zoom(2.0)

func context_canvas_zoom_4x():
	set_effective_zoom(4.0)

func context_canvas_zoom_fit():
	var level = min(rect_size.x / actual_size.x, rect_size.y / actual_size.y)
	set_effective_zoom(level)

func context_canvas_zoom_cover():
	var level = max(rect_size.x / actual_size.x, rect_size.y / actual_size.y)
	set_effective_zoom(level)