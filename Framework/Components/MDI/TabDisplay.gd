extends Tabs

export(StyleBox) var active_tab_style

signal context_requested(tab)

func _draw():
	if current_tab >= get_tab_count():
		return
	var rect = get_tab_rect(current_tab)
	var icon = get_tab_icon(current_tab)
	var text = get_tab_title(current_tab)
	var font = get_font("font")
	var top_margin = rect.size.y / 2
	var close_icon = get_icon("close")
	draw_style_box(active_tab_style, rect)
	draw_texture(icon, rect.position + active_tab_style.get_offset() + Vector2(2, top_margin - icon.get_height()/2))
	draw_string(font, rect.position + active_tab_style.get_offset() + Vector2(18, top_margin + floor(font.get_height()/2) - 1), text)
	draw_texture(close_icon, rect.position + Vector2(rect.size.x - 20 - active_tab_style.content_margin_right, top_margin - close_icon.get_height()/2))

func _gui_input(e):
	if e is InputEventMouseButton:
		if e.is_pressed() and not e.is_echo():
			if e.button_index == BUTTON_MIDDLE:
				for i in get_tab_count():
					if get_tab_rect(i).has_point(e.position):
						emit_signal("tab_close", i)
						accept_event()
						return
			if e.button_index == BUTTON_RIGHT:
				for i in get_tab_count():
					if get_tab_rect(i).has_point(e.position):
						emit_signal("context_requested", i)