extends Node

# Documents
var current_doc = null
var open_docs = []

# Tabs
var current_tab = null

signal on_active_doc_changed()
signal on_active_tab_changed()

signal on_focus_changed()
signal on_doc_composition_changed()

signal on_shard_update()

signal on_open_tabs_changed()

var document_interface = null setget set_document_interface
var application_interfaces = []

const NAME = "BearBones"
const VERSION = "Alpha"

var slow_tick_timer = null

func _init():
	print("-------------------------------")
	print("Initializing ", NAME," ", VERSION)
	print("-------------------------------")

func register_application_interface(interface):
	application_interfaces.push_back(interface)

func _ready():
	add_to_group("session_data")

	var placement = Session.recover("window_placement")
	if placement == null:
		placement = {}
		placement.screen = OS.current_screen
		placement.size   = Vector2(1200, 800)
		placement.position = OS.window_position
		placement.maximized = true
	placement_cache = placement

	var valid = true
	valid = valid and (placement.screen <= OS.get_screen_count())

	var screen_rect = Rect2(OS.get_screen_position(placement.screen), OS.get_screen_size(placement.screen))
	var window_rect = Rect2(placement.position, placement.size)
	screen_rect.grow(50)

	valid = valid and (screen_rect.intersects(window_rect))
	
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")

	OS.window_borderless = false

	if valid:
		OS.current_screen   = placement.screen
		OS.window_position  = placement.position

	OS.window_size      = placement.size
	OS.window_maximized = placement.maximized

	slow_tick_timer = Timer.new()
	slow_tick_timer.wait_time = 1.0
	add_child(slow_tick_timer)
	slow_tick_timer.start()
	slow_tick_timer.connect("timeout", self, "_slow_tick")
	_slow_tick()
	config_updated("user://config.json")
	Config.connect("config_updated", self, "config_updated")

func config_updated(path):
	if path == "user://config.json":
		var always_redraw = Config.get_value("user://config.json", "always_redraw")
		OS.low_processor_usage_mode = not always_redraw
		OS.vsync_enabled = always_redraw

func _exit_tree():
	for doc in open_docs:
		doc.free()

var placement_cache = {}

func get_session_data():
	return {"window_placement": get_placement()}

func get_placement():
	# BUG Workaround
	if not OS.window_minimized:
		placement_cache = {"screen": OS.current_screen, "maximized": OS.window_maximized, "size": OS.get_real_window_size(), "position": OS.window_position}
	return placement_cache

func _slow_tick():
	get_placement()

func _process(delta):
	for doc in open_docs:
		doc._process(delta)

func push_undo(name):
	if current_doc:
		return current_doc.push_undo(name)

func get_focus():
	if current_tab:
		return current_tab.get_focus()
	return null

func add_doc(doc):
	open_docs.append(doc)
	return doc

func delete_doc(doc):
	open_docs.erase(doc)
	doc.free()

func set_focus(shard):
	if current_tab:
		current_tab.set_focus(shard)

func get_context():
	if current_tab and "context" in current_tab:
		return current_tab.context
	return null

func set_active_tab(tab):
	var old_tab = current_tab
	current_tab = tab
	if current_tab:
		var new_doc = tab.doc
		if current_doc != new_doc:
			var old_doc = current_doc
			current_doc = new_doc
			emit_signal("on_active_doc_changed")
			if current_doc:
				if old_doc:
					old_doc.disconnect("on_shard_updated", self, "on_shard_update")
					old_doc.disconnect("on_shard_added", self, "on_shard_added")
					old_doc.disconnect("on_shard_removed", self, "on_shard_removed")
					old_doc.disconnect("invalidate", self, "invalidate_doc")
				current_doc.connect("on_shard_updated", self, "on_shard_update", [], CONNECT_DEFERRED)
				current_doc.connect("on_shard_added", self, "on_shard_added", [], CONNECT_DEFERRED)
				current_doc.connect("on_shard_removed", self, "on_shard_removed", [], CONNECT_DEFERRED)
				current_doc.connect("invalidate", self, "invalidate_doc")
				emit_signal("on_doc_composition_changed")
	else:
		current_doc = null
		emit_signal("on_active_doc_changed")
		emit_signal("on_doc_composition_changed")
	if current_tab != old_tab:
		emit_signal("on_active_tab_changed")

func invalidate_doc():
	emit_signal("on_active_doc_changed")
	emit_signal("on_doc_composition_changed")

func set_document_interface(new):
	assert(document_interface == null)
	document_interface = new
	document_interface.connect("tab_added", self, "open_tabs_changed", [], CONNECT_DEFERRED)
	document_interface.connect("tab_removed", self, "open_tabs_changed", [], CONNECT_DEFERRED)
	document_interface.connect("tab_saved", self, "open_tabs_changed", [], CONNECT_DEFERRED)

func open_context_menu(menu_name, node = null, min_width = 0):
	if document_interface:
		if node:
			return document_interface.popup_menu(node, menu_name, min_width)
		else:
			return document_interface.context_menu(menu_name)
	return null

func open_tabs_changed(tab):
	emit_signal("on_open_tabs_changed")
	var new_docs = []
	for doc in open_docs:
		if doc.users < 1:
			doc.free()
		else:
			new_docs.push_back(doc)
	open_docs = new_docs

func open_tab(doc, view = "Workspace", shard = null):
	if document_interface:
		document_interface.open_tab(doc, view, shard)

func open_file(path):
	#TODO
	pass
	# if FileImport.is_external_palette(path):
	# 	document_interface.open_tab(path, "Palette")
	# else:
	# 	document_interface.open_tab(path, "Workspace")

func on_shard_added(shard):
	emit_signal("on_doc_composition_changed")

func on_shard_removed(shard):
	emit_signal("on_doc_composition_changed")

func on_shard_update():
	emit_signal("on_shard_update")