extends HBoxContainer

var label = "Text"
var accel = 0
var id = 0

export(StyleBox) var hover_box = null
var hover = false
var disabled = false

signal pressed()

func _ready():
	$Label.text = label
	if typeof(accel) == TYPE_STRING:
		$Hotkey.text = accel
	else:
		$Hotkey.text = Functions.get_hotkey_text(accel)

func set_label(new_label):
	label = new_label
	$Label.text = label

func set_icon_size(size):
	self.rect_min_size.y = size.y
	$Icon.rect_min_size.x = size.x

func set_icon(icon):
	icon.setup_texture_rect($Icon)

func disable():
	disabled = true
	modulate = Color(1,1,1,0.40)
	update()

func _gui_input(e):
	if not disabled and e is InputEventMouseButton:
		if not e.pressed:
			emit_signal("pressed")
			accept_event()

func _input(e):
	if e is InputEventMouseMotion:
		var old_h = hover
		var rect = get_global_rect()
		hover = rect.has_point(get_global_mouse_position())
		if old_h != hover:
			update()

func _draw():
	if hover:
		draw_style_box(hover_box, Rect2(Vector2(0, 0), rect_size))