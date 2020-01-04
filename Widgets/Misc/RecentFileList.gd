extends ItemList

var paths = []

func _ready():
	RecentFiles.connect("list_changed", self, "rebuild_entries")
	rebuild_entries()
	self.connect("item_selected", self, "on_select_item")

func rebuild_entries():
	self.clear()
	paths = []
	for item in RecentFiles.list:
		self.add_item(item.get_file(), preload("res://Theme/gui/item/file_document.png"))
		paths.push_back(item)

func on_select_item(index):
	var path = paths[index]
	App.open_file(path)