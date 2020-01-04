extends Panel

export(float) var zoom = 1.0 setget set_zoom

func _ready():
	set_zoom(zoom)
	get_tree().get_root().connect("size_changed", self, "resize")

func resize():
	$Camera2D.zoom = Vector2(1.0 / zoom, 1.0 / zoom)
	self.rect_size = get_viewport().size / zoom
	update()

func set_zoom(_zoom):
	zoom = _zoom
	if is_inside_tree() and not Engine.editor_hint:
		resize()

func zoom_out():
	if zoom <= 1.0:
		zoom = max(zoom - 0.1, 0.5)
	else:
		zoom = max(zoom - 0.2, 1.0)
	resize()

func zoom_in():
	if zoom <= 1.0:
		zoom = min(zoom + 0.1, 1.0)
	else:
		zoom = min(zoom + 0.2, 3.0)
	resize()

func _unhandled_input(e):
	var action = Actions.find_triggered_action(e)
	match action:
		"ZoomInUI":
			zoom_in()
			accept_event()
		"ZoomOutUI":
			zoom_out()
			accept_event()