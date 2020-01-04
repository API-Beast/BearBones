extends Panel

var dir_list = null

func _ready():
	App.connect("on_active_doc_changed", self, "update_docks")
	App.connect("on_open_tabs_changed", self, "update_docks")
	update_docks()

func _enter_tree():
	dir_list = $Margin/Docks/DirectoryDock/DirectoryList

func update_docks():
	var doc = App.current_doc
	if is_inside_tree():
		if doc and not doc.filepath.empty():
			dir_list.directory = doc.filepath.get_base_dir()
			$Margin/Docks/DirectoryDock.label = doc.filepath.get_base_dir().get_file()
		else:
			dir_list.directory = ""

		$Margin/Docks/DirectoryDock.visible = not dir_list.directory.empty()
