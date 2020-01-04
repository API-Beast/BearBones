extends Control

enum PathMode{SAVE, LOAD, SELECT_FOLDER}

export(PathMode) var mode = PathMode.SAVE
export var label = "File"
export var path_root = ""
export(PoolStringArray) var filters = PoolStringArray()
export var check_file_extension = true
export var default_file_extension = ""

export(String) var value = "" setget set_value, get_value

export(Texture) var icon_warning
export(Texture) var icon_info

export var show_options = false
export var options = {}

export var show_history = false
export var history_category = ""
var history = []
const HistorySize = 5

var valid = false
var validation_timer = 0.0

signal value_changed(new_value)
signal changed()
signal valid_value(new_valid_value)

func _init():
	if GlobalMenu and not GlobalMenu.has_menu("PathSelectorOptions"):
		GlobalMenu.begin_special_menu("_PathSelectorOptions", "Path Selector: Builtin Options", "path_selector", "context_options_menu", "context_set_value")
		GlobalMenu.begin_special_menu("_PathSelectorHistory", "Path Selector: History", "path_selector", "context_history_menu", "context_set_value")
		GlobalMenu.begin_menu("PathSelectorOptions", "Context: Path Selector", true)
		GlobalMenu.add_inline_menu("_PathSelectorOptions")
		GlobalMenu.add_separator()
		GlobalMenu.add_inline_menu("_PathSelectorHistory")

func context_options_menu():
	var retVal = []
	retVal.push_back({"type":"header", "text": "Built-In"})
	# TODO FIXME "icon":IconProvider.get_pattern_icon(options[option], Vector2(32, 32))
	for option in options.keys():
		retVal.push_back({"label":option, "value":option, "icon_size":Vector2(32, 32)})
	return retVal

func context_history_menu():
	var retVal = []
	retVal.push_back({"type":"header", "text": "Recently Used"})
	# TODO FIXME "icon":IconProvider.get_pattern_icon(file, Vector2(32, 32))
	for file in history:
		retVal.push_back({"label":file.get_file(), "value":file, "icon_size":Vector2(32, 32)})
	if history.empty():
		retVal.push_back({"type":"label", "text": "~No items~"})
	return retVal

func context_set_value(value):
	self.set_value(value, true)

func show_options():
	GlobalMenu.clear_context()
	GlobalMenu.set_context("path_selector", self)
	App.open_context_menu("PathSelectorOptions", $Entry/LineEdit, $Entry/LineEdit.rect_size.x)

func clean_history():
	var file = File.new()
	var new_history = []
	for item in history:
		if item and file.file_exists(item):
			new_history.push_back(item)
	history = new_history
	if history.size() > HistorySize:
		history.resize(HistorySize)

func add_to_history(new_path):
	if history.empty():
		history.push_front(new_path)
		Session.store("file_history_"+history_category, history)
	elif history.front() != new_path:
		history.erase(new_path)
		history.push_front(new_path)
		clean_history()
		Session.store("file_history_"+history_category, history)

func _ready():
	$Entry/Label.text = label
	$Entry/LineEdit/Options.visible = show_options or show_history
	$Entry/LineEdit/Options.connect("pressed", self, "show_options")
	$Entry/SelectorButton.connect("pressed", self, "select_path")
	$Entry/LineEdit.connect("text_entered", self, "update_value")
	$Entry/LineEdit.connect("text_changed", self, "start_validation_timer")
	$Message.hide()

	if history_category.empty():
		history_category = str(get_path())
		history = Session.recover("file_history_"+history_category, [])
		clean_history()

	if path_root.empty():
		path_root = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)

func start_validation_timer(dummy=null):
	validation_timer = 1.0

func _process(dt):
	if validation_timer != 0.0:
		validation_timer -= dt
		if validation_timer <= 0.0:
			validation_timer = 0.0
			update_value()

func set_value(new_value, update=false):
	if typeof(new_value) != TYPE_STRING:
		return
	if not has_node("Entry/LineEdit"):
		return

	if is_special_option(new_value):
		if options.values().has(new_value):
			var idx = options.values().find(new_value)
			new_value = options.keys()[idx]
	else:
		var r = path_root
		if not r.ends_with("/"):
			r += "/"

		r = r.replace("\\", "/")
		new_value = new_value.replace("\\", "/")

		if OS.get_name() == "Windows":
			new_value = new_value.replacen(r, "")
		else:
			new_value = new_value.replace(r, "")

	$Entry/LineEdit.text = new_value
	if update:
		update_value()

func update_value(new_val=null):
	if not new_val:
		new_val = $Entry/LineEdit.text
	validate()
	validation_timer = 0.0

	emit_signal("value_changed", new_val)
	emit_signal("changed")
	if valid:
		emit_signal("valid_value", new_val)
		if not is_special_option():
			add_to_history(get_abs_path())

var last_message_priority = 0
func set_message(type, msg, priority=1):
	if priority > last_message_priority:
		last_message_priority = priority

		match(type):
			"INFO":
				$Message/Label.add_color_override("font_color", Color("#2a98c9"))
				$Message/Icon.texture = icon_info
			"ERROR":
				$Message/Label.add_color_override("font_color", Color("#ff2323"))
				$Message/Icon.texture = icon_warning
				valid = false

		$Message/Label.text = msg
		$Message.show()

func is_special_option(val=null):
	if not show_options:
		return false

	if not val:
		val = $Entry/LineEdit.text
	return options.has(val) or options.values().has(val)

func clear_message():
	last_message_priority = 0
	$Message.hide()

func validate():
	clear_message()
	valid = true

	if is_special_option():
		valid = true
		return

	var p = get_abs_path()
	var file = File.new()
	var dir = Directory.new()

	if p.empty():
		valid = false
		return

	if not p.is_abs_path(): set_message("ERROR", tr("Invalid path."), 5)
	match(mode):
		PathMode.SAVE:
			if file.file_exists(p): set_message("INFO", tr("File will be overriden."), 1)
			if not dir.dir_exists(p.get_base_dir()): set_message("ERROR", tr("Folder does not exist."), 3)
		PathMode.LOAD:
			if not file.file_exists(p): set_message("ERROR", tr("File does not exist."), 3)
		PathMode.SELECT_FOLDER:
			if not dir.dir_exists(p): set_message("ERROR", tr("Folder does not exist."), 3)

	if check_file_extension and mode != PathMode.SELECT_FOLDER:
		var matching_filter = false
		for filter in filters:
			var patterns = filter.split(";",true,1)[0].split(",",true)
			for pattern in patterns:
				if p.matchn(pattern):
					matching_filter = true
					break
		if not matching_filter:
			set_message("ERROR", tr("Invald file extension: {extension}").format({"extension": p.get_extension()}), 2)

func is_valid():
	return valid

func get_value():
	var v = $Entry/LineEdit.text
	if show_options and options.has(v):
		return options[v]
	return v

func get_abs_path():
	var v = get_value()

	if show_options:
		if options.values().has(v):
			return v

	if not v.empty():
		if v.is_rel_path():
			if v.get_extension().empty() and not default_file_extension.empty():
				return path_root.plus_file(v)+default_file_extension
			else:
				return path_root.plus_file(v)
	return v

func select_path():
	var node = Dialog.push_dialog("File")

	if mode == PathMode.SAVE:
		node.mode = FileDialog.MODE_SAVE_FILE
	if mode == PathMode.LOAD:
		node.mode = FileDialog.MODE_OPEN_FILE
	if mode == PathMode.SELECT_FOLDER:
		node.mode = FileDialog.MODE_OPEN_DIR

	var v = get_value()
	if is_special_option(v):
		node.current_path = path_root+"/"
	else:
		if not v.empty():
			if v.is_rel_path():
				node.current_path = path_root.plus_file(v)
			else:
				node.current_path = v
		else:
			node.current_path = path_root+"/"
	
	if filters:
		node.filters = filters

	node.connect("file_selected", self, "set_value")
	node.connect("dir_selected", self, "set_value")