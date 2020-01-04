tool
extends Container

export var label = "Dock" setget set_label
export var collapsible = true
export var collapsed = false setget set_collapsed
export var row_height = 18

export(Texture) var icon_collapsed
export(Texture) var icon_expanded
export(StyleBox) var box_header
export(StyleBox) var box_panel
export(Font) var font_label

func _ready():
	if not Engine.editor_hint:
		for child in get_children():
			if not child.name.begins_with("_"):
				remove_child(child)
				$_Scroll/_Content.add_child(child)
	$_Scroll.visible = not collapsed
	$_Tween.connect("tween_completed", self, "on_tween_completed")

func _draw():
	draw_style_box(box_panel, Rect2(Vector2(0, 0), rect_size))
	if box_header:
		draw_style_box(box_header, Rect2(0, 0, rect_size.x, row_height))

	var x = 4
	if collapsible:
		if collapsed:
			draw_texture(icon_collapsed, Vector2(x, 0))
			x += icon_collapsed.get_width() + 2
		else:
			draw_texture(icon_expanded, Vector2(x, 0))
			x += icon_expanded.get_width() + 2

	draw_string(font_label, Vector2(x, floor(row_height / 2.0 + font_label.get_ascent()/2.0)), label, Color(1.0, 1.0, 1.0, 1.0), rect_size.x)

func set_label(new_label):
	label = new_label
	update()

func set_collapsed(new_collapsed):
	var old_collapsed = collapsed
	collapsed = new_collapsed

	if not is_inside_tree():
		if collapsed:
			self.size_flags_vertical = 0
		else:
			self.size_flags_vertical = SIZE_EXPAND_FILL
		return
	
	if old_collapsed != new_collapsed:
		if collapsed: # Collapse
			$_Tween.remove_all()
			$_Tween.interpolate_property(self, "rect_min_size", self.rect_size, Vector2(0, row_height), 0.15, Tween.TRANS_QUAD, Tween.EASE_OUT)
			$_Tween.start()
		else: # Expand
			self.size_flags_vertical = SIZE_EXPAND_FILL
			get_parent_control().notification(Container.NOTIFICATION_SORT_CHILDREN)

			$_Tween.remove_all()
			$_Tween.interpolate_property(self, "rect_min_size", Vector2(0, row_height), self.rect_size, 0.15, Tween.TRANS_QUAD, Tween.EASE_IN)
			$_Tween.start()
		self.size_flags_vertical = 0
		$_Scroll.visible = false
	update()

func on_tween_completed(obj, path):
	if collapsed:
		self.size_flags_vertical = 0
	else:
		self.size_flags_vertical = SIZE_EXPAND_FILL
	$_Scroll.visible = not collapsed

	self.rect_min_size = Vector2(0, row_height)
	minimum_size_changed()
	update()

func _gui_input(e):
	if collapsible and e is InputEventMouseButton:
		if e.is_pressed() and e.button_index == BUTTON_LEFT and e.position.y < row_height:
			self.collapsed = not collapsed

