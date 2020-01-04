tool
extends Container

export var vertical = false
export var reverse_order = false
export var seperation = 2
export var align = 0.0

func _ready():
	connect("sort_children", self, "sort_children")

func _process(delta):
	if Engine.editor_hint:
		sort_children()
	else:
		set_process(false)

func sort_children():
	var sep = seperation
	var stretch_min = 0
	var stretch_avail = 0
	var stretch_ratio_total = 0.0

	var min_size = {}
	var will_stretch = {}
	var final_size = {}

	var max_size = rect_size.x
	if vertical:
		max_size = rect_size.y

	var children = get_children()
	if reverse_order:
		children.invert()
	
	var temp = []
	for c in children:
		if c is Control:
			if not c.is_visible_in_tree(): continue
			if c.is_set_as_toplevel(): continue
			temp.push_back(c)
	children = temp
	
	if children.size() == 0:
		minimum_size_changed()
		return

	for c in children:
		var size = c.get_combined_minimum_size()
		if vertical:
			stretch_min += size.y
			min_size[c] = size.y
			will_stretch[c] = c.size_flags_vertical & SIZE_EXPAND
		else:
			stretch_min += size.x
			min_size[c] = size.x
			will_stretch[c] = c.size_flags_horizontal & SIZE_EXPAND
		
		if will_stretch[c]:
			stretch_avail += min_size[c]
			stretch_ratio_total += c.size_flags_stretch_ratio

		final_size[c] = min_size[c]

	var stretch_max = max_size
	stretch_max -= (children.size() - 1) * seperation

	var stretch_diff = stretch_max - stretch_min
	if stretch_diff < 0:
		stretch_max = stretch_min
		stretch_diff = 0
	
	stretch_avail += stretch_diff

	var has_stretched = false
	var refit_successful = false
	while stretch_ratio_total > 0 and not refit_successful:
		has_stretched = true
		for c in children:
			if will_stretch[c]:
				var final_pixel_size = stretch_avail * c.size_flags_stretch_ratio / stretch_ratio_total
				if final_pixel_size >= min_size[c]:
					final_size[c] = final_pixel_size
					refit_successful = true
				else:
					will_stretch[c] = false
					stretch_ratio_total -= c.size_flags_stretch_ratio
					refit_successful = false
					stretch_avail -= min_size[c]
					final_size[c] = min_size[c]
					break
	
	
	var current_pos = 0
	if not has_stretched:
		current_pos = int(stretch_diff * align)

	var first = true
	for c in children:
		if first:
			first = false
		else:
			current_pos += sep

		var from = int(current_pos)
		var to = int(current_pos + final_size[c])
		if will_stretch[c] and c == children.back():
			to = max_size
		
		var size = int(to - from)
		var rect = null
		if vertical:
			rect = Rect2(0, from, rect_size.x, size)
		else:
			rect = Rect2(from, 0, size, rect_size.y)
		fit_child_in_rect(c, rect)
		
		current_pos = to
	minimum_size_changed()

func _get_minimum_size():
	var size = 0
	for c in get_children():
		if not c.is_visible_in_tree(): continue
		if c.is_set_as_toplevel(): continue
		if vertical:
			size += c.get_combined_minimum_size().y + seperation
		else:
			size += c.get_combined_minimum_size().x + seperation
	if vertical:
		return Vector2(0, size)
	else:
		return Vector2(size, 0)
