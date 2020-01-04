tool
extends VBoxContainer

export(StyleBox) var header 
export(StyleBox) var background

export var collapsed = false setget set_collapsed
export var label = "Test" setget set_label
export var enabled = false setget set_enabled

signal on_toggle

func _ready():
	if not Engine.editor_hint:
		for child in get_children():
			if not child.name.begins_with("_"):
				remove_child(child)
				$_Margin.add_child(child)
	$_Header/Collapsed.connect("pressed", self, "update_collapse")
	$_Header/Label.connect("pressed", self, "update_enable")
	set_label(label)
	set_enabled(enabled)
	set_collapsed(collapsed)
	update()

func _draw():
	draw_style_box(header, Rect2(Vector2(0, 0), $_Header.rect_size))
	if not collapsed:
		draw_style_box(background, Rect2(Vector2(0, $_Header.rect_size.y), Vector2(rect_size.x, rect_size.y - $_Header.rect_size.y)))

func set_collapsed(new_state):
	collapsed = new_state
	if is_inside_tree():
		for child in get_children():
			if child.name != "_Header":
				child.visible = not collapsed
		$_Header/Collapsed.pressed = collapsed
		update()

func set_enabled(new_enabled, collapse = true):
	enabled = new_enabled
	if is_inside_tree() and collapse:
		$_Header/Label.pressed = new_enabled

func set_label(new_label):
	if is_inside_tree():
		$_Header/Label.text = new_label
	label = new_label

func update_collapse():
	set_collapsed($_Header/Collapsed.pressed)

func update_enable():
	enabled = $_Header/Label.pressed
	set_collapsed(not enabled)
	emit_signal("on_toggle")