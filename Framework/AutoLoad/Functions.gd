extends Node

func h_call(obj, name, args):
	while true:
		if not obj:
			return null
		if obj.has_method(name):
			return obj.callv(name, args)
		obj = obj.get_parent()

func h_get(obj, name):
	while true:
		if not obj:
			return null
		if obj.has_meta(name):
			return obj.get_meta(name)
		obj = obj.get_parent()

func h_set(obj, name, val):
	obj.set_meta(name, val)

func get_offset_to_anchor(c, anchor):
	var rect = Rect2(c.rect_position, c.rect_size)
	var p_rect = Rect2(Vector2(0, 0), c.get_parent_control().rect_size)
	match anchor:
		Control.PRESET_TOP_LEFT:
			return rect.position
		Control.PRESET_TOP_RIGHT:
			return Vector2(p_rect.end.x - rect.end.x, rect.position.y)
		Control.PRESET_BOTTOM_LEFT:
			return Vector2(rect.position.x, p_rect.end.y - rect.end.y)
		Control.PRESET_BOTTOM_RIGHT:
			return Vector2(p_rect.end.x - rect.end.x, p_rect.end.y - rect.end.y)
	
func get_best_anchor(c):
	var tl = get_offset_to_anchor(c, Control.PRESET_TOP_LEFT).length()
	var tr = get_offset_to_anchor(c, Control.PRESET_TOP_RIGHT).length()
	var bl = get_offset_to_anchor(c, Control.PRESET_BOTTOM_LEFT).length()
	var br = get_offset_to_anchor(c, Control.PRESET_BOTTOM_RIGHT).length()
	if tl < tr and tl < bl and tl < br: return Control.PRESET_TOP_LEFT
	if tr < tl and tr < bl and tr < br: return Control.PRESET_TOP_RIGHT
	if bl < tl and bl < tr and bl < br: return Control.PRESET_BOTTOM_LEFT
	if br < tl and br < tr and br < bl: return Control.PRESET_BOTTOM_RIGHT
	return Control.PRESET_BOTTOM_RIGHT

func apply_anchor_and_offset(c, anchor, offset):
	var position = Vector2(0, 0)
	var pc = c.get_parent_control()
	if not pc:
		return
	
	var p_size = pc.rect_size
	var size = c.rect_size
	match anchor:
		Control.PRESET_TOP_LEFT:
			position = offset
		Control.PRESET_TOP_RIGHT:
			position.x = p_size.x - size.x - offset.x
			position.y = offset.y
		Control.PRESET_BOTTOM_LEFT:
			position.x = offset.x
			position.y = p_size.y - size.y - offset.y
		Control.PRESET_BOTTOM_RIGHT:
			position = p_size - size - offset
	c.rect_position = position

func replace_node_tree(old_node, new_node):
	if old_node == new_node:
		return

	var p = old_node.get_parent()
	p.add_child_below_node(old_node, new_node)
	p.remove_child(old_node)
	new_node.request_ready()
	new_node.name = old_node.name

func remove_children(parent):
	for child in parent.get_children():
		parent.remove_child(child)
		child.free()

func replace_children(parent, new_child):
	for child in parent.get_children():
		parent.remove_child(child)
		child.free()
	parent.add_child(new_child)

func clone(obj):
	match typeof(obj):
		TYPE_ARRAY, TYPE_DICTIONARY:
			return obj.duplicate()
		TYPE_OBJECT:
			if obj is Resource:
				return obj.duplicate()
			else:
				return obj
		_:
			return obj

func deep_copy(val):
	match typeof(val):
		TYPE_COLOR_ARRAY, TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY, TYPE_STRING_ARRAY, TYPE_INT_ARRAY, TYPE_RAW_ARRAY, TYPE_REAL_ARRAY:
			return val.duplicate()
		TYPE_ARRAY:
			var ret = []
			ret.resize(val.size())
			for i in range(val.size()):
				ret[i] = deep_copy(val[i])
			return ret
		TYPE_DICTIONARY:
			var ret = {}
			for key in val.keys():
				ret[key] = deep_copy(val[key])
			return ret
		TYPE_OBJECT:
			if Serializer.has_registry_for(val):
				return Serializer.deserialize(Serializer.serialize(val))
			return val
		_:
			return val

func shortn_path(text, target):
	var initial_text = text
	if text.length() > target and (text.is_rel_path() or text.is_abs_path()):
		text = text.get_file()
	if text.length() > target:
		text = text.strip_edges()
	if text.length() > target:
		text = text.replace("e", "")
	#if text.length() > target:
	#	text = text.replace("a", "")
	#if text.length() > target:
	#	text = text.replace("o", "")
	#if text.length() > target:
	#	text = text.replace("i", "")
	if text.length() > target:
		var strip = ceil((text.length() - target - 3) / 2)
		var first_half_end = text.length()/2-strip
		var second_half_start = text.length()/2+strip
		text = text.substr(0, first_half_end) + "…" + text.substr(second_half_start, text.length() - second_half_start)
	if text[0] != initial_text[0]:
		text = initial_text[0] + text
	return text

func shortn_visual(text, max_width, font):
	var initial_text = text

	if max_width < 24:
		return text

	var strip = ((font.get_string_size(text).x - max_width) / 36) + 1
	var max_strip = initial_text.length() / 2

	while font.get_string_size(text).x > max_width:
		text = initial_text

		var first_half_end = text.length()/2-strip
		var second_half_start = text.length()/2+strip
		text = text.substr(0, first_half_end) + "…" + text.substr(second_half_start, text.length() - second_half_start + 1)
		
		strip += 1
		if strip >= max_strip:
			break

	return text

func sort_parallel(values, sort_by):
	var temp = []
	for i in values.size():
		temp.push_back([i, sort_by[i]])
	temp.sort_custom(self, "_sort_parallel")
	var retVal = []
	for val in temp:
		retVal.push_back(values[val[0]])
	return retVal

func _sort_parallel(a, b):
	if a[1]<b[1]:
		return true
	return false

func create_shortcut(accel):
	var event = InputEventKey.new()
	event.pressed = true
	event.scancode = accel &~ (KEY_MASK_CTRL|KEY_MASK_SHIFT|KEY_MASK_ALT|KEY_MASK_META)
	event.control = accel & KEY_MASK_CTRL
	event.shift = accel & KEY_MASK_SHIFT
	event.alt = accel & KEY_MASK_ALT
	event.meta = accel & KEY_MASK_META
	var sc = ShortCut.new()
	sc.shortcut = event
	return sc

func get_hotkey_text(hotkey):
	var text = ""
	if hotkey & KEY_MASK_ALT:
		text += "Alt+"
	if hotkey & KEY_MASK_CTRL:
		text += "Ctrl+"
	if hotkey & KEY_MASK_SHIFT:
		text += "Shift+"
	if OS.get_name() == "OSX":
		if hotkey & KEY_MASK_CMD:
			text += "Cmd+"
	else:
		if hotkey & KEY_MASK_META:
			text += "Win+"
			
	var scancode = hotkey &~ (KEY_MASK_CTRL|KEY_MASK_SHIFT|KEY_MASK_ALT|KEY_MASK_META)
	match scancode:
		KEY_DELETE:
			text += "Del"
		_:
			text += OS.get_scancode_string(scancode)
	return text

func get_popup_parent(node):
	var control = node
	while true:
		if control is Popup:
			return control
		if control.get_parent_control() == null:
			return control
		control = control.get_parent_control()

func control_enable(node):
	node.set_process_internal(true)
	node.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func control_disable(node):
	node.set_process_internal(false)
	node.self_modulate = Color(1.0, 1.0, 1.0, 0.5)
	
func json_box(val):
	match typeof(val):
		TYPE_COLOR:
			return [val.r, val.g, val.b, val.a]
		TYPE_VECTOR2:
			return [val.x, val.y]
		TYPE_VECTOR3:
			return [val.x, val.y, val.z]
		TYPE_RECT2:
			return [val.position.x, val.position.y, val.size.x, val.size.y]
		TYPE_ARRAY, TYPE_COLOR_ARRAY, TYPE_VECTOR2_ARRAY, TYPE_VECTOR3_ARRAY, TYPE_STRING_ARRAY, TYPE_INT_ARRAY, TYPE_RAW_ARRAY, TYPE_REAL_ARRAY:
			var ret = []
			ret.resize(val.size())
			for i in range(val.size()):
				ret[i] = json_box(val[i])
			return ret
		TYPE_DICTIONARY:
			var ret = {}
			for key in val.keys():
				ret[key] = json_box(val[key])
			return ret
		_:
			return val

func json_unbox(val, type):
	match type:
		TYPE_COLOR:
			return Color(val[0], val[1], val[2], val[3])
		TYPE_VECTOR2:
			return Vector2(val[0], val[1])
		TYPE_VECTOR3:
			return Vector3(val[0], val[1], val[2])
		TYPE_RECT2:
			return Rect2(val[0], val[1], val[2], val[3])
		TYPE_COLOR_ARRAY:
			var ret = PoolColorArray()
			for color in val:
				ret.push_back(json_unbox(color, TYPE_COLOR))
			return ret
		TYPE_INT:
			return int(val)
		_:
			return val

func get_directory_hash(path):
	var folders = []
	var files = []
	var data = []
	var FileClass = File.new()

	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)		
		while true:
			var name = dir.get_next()
			if name == "":
				break
			if dir.current_is_dir():
				folders.push_back(name)
			else:
				files.push_back(name)
		dir.list_dir_end()

		var root = dir.get_current_dir()
		for folder in folders:
			var full_path = root.plus_file(folder)
			data.push_back([folder, get_directory_hash(full_path)])
		
		for file in files:
			var full_path = root.plus_file(file)
			data.push_back([file, FileClass.get_modified_time(full_path)])
	
		return data.hash()

func n_distance(a, b):
	var square_distance = 0
	for i in range(a.size()):
		square_distance += pow(a[i] - b[i], 2)
	return sqrt(square_distance)

func trigger_from_array(arr):
	var retVal = InputTrigger.new()
	var mods = 0
	match arr:
		[InputEventMouseButton, var val]:
			retVal.mouse_button = val
		[InputEventMouseButton, var val, var m_mods]:
			retVal.mouse_button = val
			mods = m_mods
		[InputEventMouseButton, var val, var m_mods, var dblclick]:
			retVal.mouse_button = val
			retVal.doubleclick = bool(dblclick)
		[InputEventKey, var val]:
			retVal.scancode = val
		[InputEventKey, var val, var m_mods]:
			retVal.scancode = val
			mods = m_mods
		[]:
			pass
	
	retVal.shift = bool(mods & KEY_MASK_SHIFT)
	if OS.get_name() == "OSX":
		retVal.command = bool(mods & KEY_MASK_CMD)
		retVal.control = bool(mods & KEY_MASK_META)
	else:
		retVal.control = bool(mods & KEY_MASK_CTRL)
		retVal.meta = bool(mods & KEY_MASK_META)
	retVal.alt = bool(mods & KEY_MASK_ALT)

	return retVal

func map_array_linear(arr, f):
	var s = arr.size()-1
	var index_below := int(floor(s * f))
	var index_above := int(min(index_below + 1, s))
	var f_below = index_below / float(s)
	var f_above = index_above / float(s)
	return range_lerp(f, f_below, f_above, arr[index_below], arr[index_above])

func map_array_fractal(arr, f, octaves = 8):
	var s = arr.size()-1
	var index_below := int(floor(s * f))
	var index_above := int(min(index_below + 1, s))
	var f_below = index_below / float(s)
	var f_above = index_above / float(s)
	var weight = inverse_lerp(f_below, f_above, f)
	if octaves > 0:
		weight = map_array_fractal(arr, weight, octaves - 1)
	return lerp(arr[index_below], arr[index_above], weight)