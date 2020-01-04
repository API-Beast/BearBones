extends Control

signal tab_added(tab)
signal tab_removed(tab)
signal tab_saved(tab)

var tabs = []
var active_view = ""
var current_tab = null
var views = {}

func _ready():
	### Context Menus
	var m = GlobalMenu
	m.begin_menu("TabContext", "Context: Tabs", true)
	m.add_context_entry("Close Tab", self, "context_close_tab", ["tab"])
	m.add_context_entry("Close Other Tabs", self, "context_close_other_tabs", ["tab"])

	$TabDisplay.connect("context_requested", self, "on_tab_context")
	$TabDisplay.connect("tab_changed", self, "on_tab_changed")
	$TabDisplay.connect("tab_close", self, "on_tab_close_requested")
	$TabDisplay.connect("reposition_active_tab_request", self, "on_tab_move_request")

	for view in views.values():
		view.propagate_call("_init_session")

	if Session.recover("failure", false):
		Dialog.queue_dialog("RecoveryFailed")

	var session_data = Session.recover("main_window")
	if session_data:
		restore_session(session_data)

	App.document_interface = self
	add_to_group("session_data")
	get_tree().call_group("bootstrap", "on_mdi_initialized", self)

	get_tree().connect("files_dropped", self, "drop_files")

func drop_files(files, screen):
	# TODO
	pass

func _exit_tree():
	for tab in tabs:
		if tab.content:
			tab.content.free()
		tab.free()
	for view in views.values():
		view.free()

func popup_menu(node, menu_name, min_width = 0):
	var menu = GlobalMenu.create_popup_menu(menu_name)
	var parent = Functions.get_popup_parent(node)
	parent.add_child(menu)
	var size = menu.get_combined_minimum_size()
	size.x = max(min_width, size.x)
	menu.popup(Rect2(node.rect_global_position+node.rect_size*Vector2(0, 1), size))
	menu.connect("hide", menu, "queue_free")
	return menu

var last_context_menu = WeakRef.new()

func context_menu(menu_name):
	var menu = GlobalMenu.create_popup_menu(menu_name)
	#add_child(menu)
	Dialog.push_context(menu)
	menu.popup(Rect2(get_local_mouse_position(), menu.get_combined_minimum_size()))
	menu.connect("hide", menu, "queue_free")
	if last_context_menu.get_ref():
		last_context_menu.get_ref().hide()
	last_context_menu = weakref(menu)
	return menu

func get_session_data():
	return {"main_window": get_data()}

func get_data():
	var data = {}
	data["current_tab"] = tabs.find(current_tab)
	data["tabs"] = tabs
	return data

func restore_session(data):
	for tab in data["tabs"]:
		if tab.has_method("set_doc"):
			var doc = null
			if not tab.path.empty():
				doc = find_doc(tab.path)
			else:
				doc = find_doc(tab.id)
			if doc:
				tab.set_doc(doc)
				if tab.view in views.keys():
					add_tab(tab)
		
	#if tabs.size() > data["current_tab"]:
	#	$TabDisplay.current_tab = data["current_tab"]
	#	on_tab_changed(data["current_tab"])
	#else:
	#	on_tab_changed(0)
	#open_tab("", "Home")

######################

func add_tab(new_tab):
	tabs.push_back(new_tab)
	var icon = new_tab.get_icon()
	if icon:
		icon = self.get(icon)
	$TabDisplay.add_tab(new_tab.get_name(), icon)
	if new_tab.doc:
		new_tab.doc.incr_users()
	emit_signal("tab_added", new_tab)
	return new_tab

func close_tab(tab):
	if tab.has_unsaved_changes():
		var node = Dialog.queue_dialog("UnsavedChanges")
		node.add_item(tab.get_name())
		yield(node, "hide")

		if node.selected_action == "Cancel":
			return

		if node.selected_action == "Save":
			var dialog = save_tab(tab)
			if dialog:
				yield(dialog, "hide")

	var index = tabs.find(tab)
	on_tab_close(index)

func close_tabs(list):
	var unsaved_tabs = []
	for tab in list:
		if tab.has_unsaved_changes():
			unsaved_tabs.push_back(tab)
	
	if unsaved_tabs.size() > 0:
		var node = Dialog.queue_dialog("UnsavedChanges")
		for tab in unsaved_tabs:
			node.add_item(tab.get_name())
		yield(node, "hide")

		if node.selected_action == "Cancel":
			return

		if node.selected_action == "Save":
			for tab in unsaved_tabs:
				save_tab(tab)

	for tab in list:
		var index = tabs.find(tab)
		on_tab_close(index)

func activate_tab(tab):
	var index = tabs.find(tab)
	$TabDisplay.current_tab = index
	on_tab_changed($TabDisplay.current_tab)
	return tab

func activate_doc(doc):
	for tab in tabs:
		if tab.doc == doc:
			return activate_tab(tab)
	return null

func open_tab(path := "", view := "Workspace", focus_obj=null):
	var doc = null
	var load_from_file := typeof(path) != TYPE_OBJECT
	var file_type := ""
	var error := false

	if path.empty():
		load_from_file = false
	else:
		if load_from_file:
			doc = find_doc(path)
			if doc:
				file_type = doc.get_file_type()
			else:
				# TODO
				if not doc:
					error = true
				elif not doc.open(path):
					App.delete_doc(doc)
					error = true
		else:
			doc = path
			file_type = doc.get_file_type()

		if error:
			Dialog.error(tr("Can't load {path}").format({"path": path}))
			return null


	var tab = find_tab(doc, view)
	if tab:
		activate_tab(tab)
		return tab

	# TODO
	# match(view):
	# 	"Workspace":
	# 		tab = DocTab.new()
	# 		tab.set_doc(doc)
	# 	"Palette":
	# 		tab = PaletteTab.new()
	# 		tab.set_doc(doc)
	# 	"Home":
	# 		tab = HomeTab.new()

	add_tab(tab)
	activate_tab(tab)
	if focus_obj:
		tab.set_focus(focus_obj)
	return tab

func save_tab(tab):
	# TODO
	pass

func find_tab(doc=null, view=null):
	if view and doc:
		for tab in tabs:
			if tab.view == view and tab.doc == doc:
				return tab
	elif view:
		for tab in tabs:
			if tab.view == view:
				return tab
	else:
		for tab in tabs:
			if tab.doc == doc:
				return tab

func find_doc(path):
	for doc in App.open_docs:
		if doc.filepath == path or doc.id == path:
			return doc
	return null

#####################

func load_document(path):
	RecentFiles.add(path)
	#TODO
	# if FileImport.is_external_palette(path):
	# 	open_tab(path, "Palette")
	# else:
	# 	open_tab(path, "Workspace")

func save_document(document, path):
	if document.save(path):
		RecentFiles.add(path)
		emit_signal("tab_saved", find_tab(document))
	else:
		Dialog.error(tr("Can't save to {path}").format({"path": path}))

###############

func _process(delta):
	update_tabs()

func update_tabs():
	var i = 0
	for i in tabs.size():
		$TabDisplay.set_tab_title(i, tabs[i].get_name())

################
# Tab Managment
################
func on_tab_changed(index):
	var new_tab = null
	if index == -1 or tabs.size() <= index:
		# TODO
		# var welcome_tab = find_tab(null, "Home")
		# if welcome_tab == null:
		# 	welcome_tab = HomeTab.new()
		# new_tab = welcome_tab
		# add_tab(welcome_tab)
		# activate_tab(welcome_tab)
		return
	else:
		new_tab = tabs[index]

	var view = views[new_tab.view]
	if active_view != new_tab.view:
		for child in $TabBG/View.get_children():
			$TabBG/View.remove_child(child)
		$TabBG/View.add_child(view)
		
	if view.has_method("set_content"):
		view.set_content(new_tab, new_tab.content)

	current_tab = new_tab
	active_view = new_tab.view
	App.set_active_tab(new_tab)

func on_tab_close_requested(index):
	close_tab(tabs[index])

func on_tab_close(index):
	var tab = tabs[index]
	tabs.remove(index)
	if tab.doc:
		tab.doc.decr_users()
	
	if current_tab == tab:
		current_tab = null
	
	$TabDisplay.remove_tab(index)

	if current_tab == tab:
		if tabs.size() > index:
			$TabDisplay.current_tab = index
		else:
			$TabDisplay.current_tab = index - 1

	on_tab_changed($TabDisplay.current_tab)
	emit_signal("tab_removed", tab)
	tab.free()

func on_tab_move_request(to):
	var from = $TabDisplay.current_tab
	$TabDisplay.move_tab(from, to)
	
	var doc = tabs[from]
	tabs.remove(from)
	tabs.insert(to, doc)
	activate_tab(doc)

##########
# Context
##########

func on_tab_context(id):
	GlobalMenu.clear_context()
	GlobalMenu.set_context("tab", tabs[id])
	self.context_menu("TabContext")

func context_close_tab(tab):
	close_tab(tab)

func context_close_other_tabs(tab):
	var tabs_copy = tabs.duplicate()
	var list = []
	for other in tabs_copy:
		if other != tab:
			list.push_back(other)
	close_tabs(list)

############

func quit():
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)

func on_load_files(paths):
	for path in paths:
		load_document(path)

func on_save_file(path, doc):
	save_document(doc, path)
	Session.store("last_document_save_folder", path.get_base_dir())

func on_load_references(paths):
	for path in paths:
		App.load_file_into_current_document(path)