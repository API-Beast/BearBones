extends HBoxContainer

export var label = "Text"
export(StyleBox) var hover_box = null

var menu = null
var hover = false
var active = false
var disabled = false

func _ready():
	$Label.text = label
	self.add_child(menu)

func disable():
	disabled = true
	modulate = Color(1,1,1,0.60)
	update()

func _input(e):
	if e is InputEventMouseMotion:
		var old_h = hover
		var rect = get_global_rect().grow(2.0)
		hover = rect.has_point(get_global_mouse_position())

		if menu.visible:
			var menu_rect = menu.get_global_rect()
			if menu_rect.has_point(get_global_mouse_position()):
				active = true

		if old_h != hover:
			update()
			if hover and not menu.visible and not disabled:
				menu.popup(Rect2(rect_global_position+rect_size*Vector2(1, 0)+Vector2(0, -4), menu.get_combined_minimum_size()))
			if not hover and not active:
				menu.hide()

func set_label(new_label):
	label = new_label
	$Label.text = label

func _draw():
	if hover:
		draw_style_box(hover_box, Rect2(Vector2(0, 0), rect_size))