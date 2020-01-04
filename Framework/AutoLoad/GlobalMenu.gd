extends Node

var menu_map = {}
var entry_map = {}
var current_menu = null

var config = {}

################

var default_context = {}
var context = {}

func set_context(key, obj):
	if typeof(obj) == TYPE_OBJECT:
		context[key] = weakref(obj)
	else:
		context[key] = obj

func set_default_context(key, obj):
	if typeof(obj) == TYPE_OBJECT:
		default_context[key] = weakref(obj)
	else:
		default_context[key] = obj
	
func get_context(key):
	var obj = get_context_ref(key)
	if typeof(obj) == TYPE_OBJECT and obj is WeakRef:
		obj = obj.get_ref()
	return obj

func get_context_ref(key):
	var obj = null
	if context.has(key):
		obj = context[key]
	if typeof(obj) == TYPE_OBJECT and obj is WeakRef and obj.get_ref() == null:
		obj = null
	if obj == null and default_context.has(key):
		obj = default_context[key]
	if typeof(obj) == TYPE_OBJECT and obj is WeakRef and obj.get_ref() == null:
		obj = null
	return obj

func clear_context():
	context = {}

#################

class Menu:
	var entries = []
	var label = ""
	var hide_from_config = false

class SpecialMenu:
	var entries = []
	var label = ""
	var obj = null
	var get_fn = ""
	var execute_fn = ""
	var hide_from_config = true

class Seperator:
	var dummy = null

class Entry:
	var label = ""
	var obj = null
	var function_name = ""
	var prereq_function_name = ""
	var default_hotkey = 0

class ContextEntry:
	var label = ""
	var script = null
	var function_name = ""
	var params = []
	var default_hotkey = 0

class ActionRefEntry:
	var action = ""
	var req_context = []

class SubMenu:
	var menu_id = ""

class InlineMenu:
	var menu_id = ""

##################

func has_menu(menu):
	return menu_map.has(current_menu)

func begin_menu(new_menu, label, hide = false):
	if not menu_map.has(current_menu):
		var menu = Menu.new()
		menu.label = label
		menu.hide_from_config = hide
		menu_map[new_menu] = menu
	current_menu = menu_map[new_menu]
	return current_menu

func begin_special_menu(new_menu, label, obj, get_fn, execute_fn):
	if not menu_map.has(current_menu):
		var menu = SpecialMenu.new()
		menu.label = label
		menu.obj = obj
		menu.get_fn = get_fn
		menu.execute_fn = execute_fn
		menu_map[new_menu] = menu
	current_menu = menu_map[new_menu]
	return current_menu

func add_separator():
	current_menu.entries.push_back(Seperator.new())

func add_entry(text, obj, function, accel=0, prereq_function=null):
	var entry = Entry.new()
	entry.label = text
	entry.obj = obj
	entry.function_name = function
	
	if prereq_function == null:
		entry.prereq_function_name = function + "_test"
	else:
		entry.prereq_function_name = prereq_function

	if OS.get_name() == "OSX":
		if accel & (KEY_MASK_META | KEY_MASK_CTRL):
			pass
		elif accel & KEY_MASK_META:
			accel &= ~KEY_MASK_META
			accel |= KEY_MASK_CTRL
		elif accel & KEY_MASK_CTRL:
			accel &= ~KEY_MASK_CTRL
			accel |= KEY_MASK_CMD

	entry.default_hotkey = accel
	current_menu.entries.push_back(entry)
	entry_map[function] = entry

func add_context_entry(text, script, function, params = [], accel=0):
	var entry = ContextEntry.new()
	entry.label  = text
	entry.script = script
	entry.function_name  = function
	entry.params    = params
	entry.default_hotkey = accel

	current_menu.entries.push_back(entry)
	
func add_submenu(subid):
	var entry = SubMenu.new()
	entry.menu_id = subid
	current_menu.entries.push_back(entry)

func add_inline_menu(subid):
	var entry = InlineMenu.new()
	entry.menu_id = subid
	current_menu.entries.push_back(entry)

func add_action_link(action, req_context = []):
	var entry = ActionRefEntry.new()
	entry.action = action
	entry.req_context = req_context
	current_menu.entries.push_back(entry)

func create_menu_items(popup, name):
	var menu = menu_map[name]
	for entry in menu.entries:
		match entry.get_script():
			Seperator:
				popup.add_separator()
			SubMenu:
				var key = entry.menu_id
				var submenu = menu_map[key]
				var submenu_popup = create_popup_menu(key)
				var submenu_entry = popup.add_submenu(submenu.label, submenu_popup)
				if submenu_popup.is_empty():
					submenu_entry.disable()
			InlineMenu:
				create_menu_items(popup, entry.menu_id)
			Entry:
				var item = popup.add_item(entry.label, -1, get_primary_hotkey(entry))
				if entry.obj.has_method(entry.prereq_function_name):
					var result = entry.obj.call(entry.prereq_function_name)
					if not result:
						item.disable()
					if typeof(result) == TYPE_STRING:
						item.set_label(result)
				item.connect("pressed", self, "trigger_menu_item", [entry])
			ContextEntry:
				var item = popup.add_item(entry.label, -1, get_primary_hotkey(entry))
				var ctxt = {}
				var params = entry.params
				if typeof(entry.script) == TYPE_STRING:
					params.push_back(entry.script)
				for param in params:
					ctxt[param] = get_context_ref(param)
				var enabled = true
				for val in ctxt.values():
					if val == null:
						enabled = false
				if not enabled:
					item.disable()
				item.connect("pressed", self, "trigger_context_menu_item", [entry, ctxt])
			ActionRefEntry:
				var action = Actions.actions
				var item = popup.add_item(Actions.get_action_label(entry.action), -1, Actions.get_action_trigger(entry.action).get_text())

				var ctxt = {}
				for param in entry.req_context:
					ctxt[param] = get_context_ref(param)
				var enabled = true
				for val in ctxt.values():
					if val == null:
						enabled = false
				if not enabled:
					item.disable()

				item.connect("pressed", self, "trigger_action_menu_item", [entry])
	if menu is SpecialMenu:
		var obj = menu.obj
		var entries = []
		if typeof(obj) == TYPE_STRING:
			obj = get_context(obj)
		if obj:
			entries = obj.call(menu.get_fn)
		if typeof(entries) == TYPE_ARRAY:
			for entry in entries:
				var type = "item"
				if entry.has("type"):
					type = entry.type
				
				match type:
					"label":
						popup.add_label(entry.text)
					"header":
						popup.add_header(entry.text)
					"item":
						var item = popup.add_item(entry.label, -1)
						if entry.has("icon_size"):
							item.set_icon_size(entry.icon_size)
						if entry.has("icon"):
							item.set_icon(entry.icon)
						item.connect("pressed", self, "trigger_special_menu_item", [menu, entry.value])
	return popup

func create_popup_menu(name):
	var popup = preload("res://Widgets/Menu/PopupMenu.tscn").instance()
	create_menu_items(popup, name)
	return popup

func trigger_menu_item(entry):
	var obj = entry.obj
	obj.call(entry.function_name)

func trigger_special_menu_item(menu, value):
	var obj = menu.obj
	if typeof(obj) == TYPE_STRING:
		obj = get_context(obj)
		
	if typeof(obj) == TYPE_OBJECT:
		obj.call(menu.execute_fn, value)

func trigger_context_menu_item(entry, ctxt = {}):
	var script = entry.script
	var args = []
	for param in entry.params:
		args.push_back(ctxt[param].get_ref())

	for arg in args:
		if arg == null:
			return

	if typeof(script) == TYPE_STRING:
		var obj = get_context(script)
		if obj:
			print(obj, obj.get_script().get_path(), entry.function_name)
			obj.call(entry.function_name)
	else:
		script.callv(entry.function_name, args)

func trigger_action_menu_item(entry):
	Actions.queue_action(entry.action)

func execute_entry(entry):
	var prereq = true
	if entry.obj.has_method(entry.prereq_function_name):
		prereq = entry.obj.call(entry.prereq_function_name)
	if prereq:
		entry.obj.call(entry.function_name)

func call_menu_entry(name, fn):
	var menu = menu_map[name]
	for entry in menu.entries:
		if entry.function_name == fn:
			execute_entry(entry)
			return
	printerr("No menu item ", name, ":", fn)

var echo_timer = null

func get_primary_hotkey(entry):
	if config.has(entry.function_name):
		var entry_config = config[entry.function_name]
		for binding in entry_config.keys():
			var val = entry_config[binding]
			if val != null:
				return val
	return entry.default_hotkey

func _unhandled_key_input(e):
	if Dialog.is_blocking():
		return
		
	if e is InputEventKey and e.is_pressed():
		for entry in entry_map.values():
			var hotkeys = {0: entry.default_hotkey}
			if config.has(entry.function_name):
				var entry_config = config[entry.function_name]
				for binding in entry_config.keys():
					var val = entry_config[binding]
					if val != null:
						hotkeys[binding] = val
			for hotkey in hotkeys.values():
				if e.get_scancode_with_modifiers() == hotkey:
					if e.is_echo() and echo_timer and echo_timer.time_left > 0.0:
						pass
					else:
						execute_entry(entry)
						echo_timer = get_tree().create_timer(0.15)
					return

func _ready():
	self.config = Config.load_config_file("user://hotkeys.json", {})

func save_config():
	Config.save_config_file("user://hotkeys.json", self.config)