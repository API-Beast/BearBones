extends "res://Widgets/ComboList.gd"

export(String, DIR) var directory = "" setget set_directory

export(Texture) var icon_palette
export(Texture) var icon_image
export(Texture) var icon_folder
export(Texture) var icon_file
export(Texture) var icon_add

var old_data_hash = null
var update_check_timer = 0.0

func _ready():
	rebuild()

func _process(dt):
	update_check_timer += dt
	if update_check_timer > 5.0:
		var new_hash = Functions.get_directory_hash(directory)
		if old_data_hash != new_hash:
			rebuild()
			old_data_hash = new_hash
		update_check_timer = 0.0

func rebuild():
	clear()

	var dir = Directory.new()
	if dir.open(directory) == OK:
		build_directory(dir)

	minimum_size_changed()

func build_directory(dir, parent = null, depth = 0):
	var folders = []
	var files = []

	if depth >= 6:
		return

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
		dir.change_dir(root)
		if dir.change_dir(folder) == OK:
			var tree = add_item(parent, dir.get_current_dir(), folder)
			build_directory(dir, tree, depth + 1)
			if tree.has_children:
				tree.collapsed = true
			else:
				tree.icon = icon_folder
		else:
			var item = add_item(parent, root.plus_file(folder), folder, icon_folder)
	
	for file in files:
		if file.ends_with(".png") or file.ends_with(".jpg") or file.ends_with(".jpeg") or file.ends_with(".clrpal"):
			var item = add_item(parent, root.plus_file(file), file, icon_file)
			var add = item.add_button("add", icon_add)
			add.visible = false

			if file.ends_with(".clrpal"):
				item.icon = icon_palette
			if file.ends_with(".png") or file.ends_with(".jpg") or file.ends_with(".jpeg"):
				item.icon = icon_image
				add.visible = true


func select_item(item):
	for obj in selection:
		obj.selected = false
	selection = [item]
	item.selected = true
	for child in $Items.get_children():
		if not child in selection and "selected" in child:
			child.selected = false

func open_file(path):
	App.open_tab(path, "Workspace")

func set_directory(new_dir):
	directory = new_dir
	rebuild()
	old_data_hash = Functions.get_directory_hash(directory)

func _button_left_click(entry, button):
	match button.id:
		"add":
			App.load_file_into_current_document(entry.id)

func _entry_double_clicked(entry):
	#TODO
	pass
	# if FileImport.is_colortool_document(entry.id):
	# 	App.open_tab(entry.id)