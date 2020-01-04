extends MarginContainer

const Item = preload("res://Autoload/Dialogs/Config/HotkeysItem.tscn")

var config = {}
var items = {}

func _ready():
	self.config = Functions.deep_copy(GlobalMenu.config)
	build_entries()

func build_entries():
	for item in items.values():
		item.free()
	for child in $Items.get_children():
		child.free()
	items = {}

	for menu in GlobalMenu.menu_map.values():
		if not menu.hide_from_config:
			var label = Label.new()
			label.text = menu.label
			$Items.add_child(label)
			for entry in menu.entries:
				if entry is GlobalMenu.Entry:
					var node = Item.instance()
					node.label = entry.label
					node.first_scancode = entry.default_hotkey
					node.id = entry.function_name
					$Items.add_child(node)

					var targets = ["0", "1", "2"]
					if config.has(entry.function_name):
						for target in targets:
							if config[entry.function_name].has(target):
								node.set_scancode(int(target), config[entry.function_name][target])

					items[entry.function_name] = node

func assign(scancode, menu, target=0):
	if not config.has(menu):
		config[menu] = {}
	config[menu][str(target)] = scancode
	items[menu].set_scancode(target, scancode)

func was_modified():
	return GlobalMenu.config.hash() != self.config.hash()

func save_data():
	GlobalMenu.config = Functions.deep_copy(self.config)
	GlobalMenu.save_config()

func reset():
	self.config = {}
	build_entries()