extends Popup

const MenuEntry = preload("res://Widgets/Menu/MenuEntry.tscn")
const SubMenuEntry = preload("res://Widgets/Menu/SubMenuEntry.tscn")

signal id_pressed(id)
signal menu_closed()

var empty = true

export(StyleBox) var bg_box
export(StyleBox) var hover_box
export(StyleBox) var header_box
export(StyleBox) var seperator_box

export(Font) var header_font
export(Font) var label_font

func _ready():
	self.connect("about_to_show", self, "reset_contents")
	self.add_stylebox_override("panel", bg_box)

func is_empty():
	return empty

func add_item(label, id=-1, accel=0, icon=null, icon_size=Vector2(24, 24)):
	var node = MenuEntry.instance()
	node.label = label
	node.id = id
	node.accel = accel
	node.hover_box = hover_box
	if icon:
		node.set_icon(icon)
		
	$Entries.add_child(node)
	$Entries/Spacer2.raise()
	node.set_icon_size(icon_size)
	node.connect("pressed", self, "on_item_pressed", [id])
	minimum_size_changed()
	empty = false
	return node

func add_label(text):
	var node = Label.new()
	node.text = text
	node.align = HALIGN_CENTER
	node.add_font_override("font", label_font)
	$Entries.add_child(node)
	$Entries/Spacer2.raise()
	minimum_size_changed()

func add_header(text):
	var node = Label.new()
	node.text = text
	node.align = HALIGN_CENTER
	node.add_font_override("font", header_font)
	node.add_stylebox_override("normal", header_box)
	$Entries.add_child(node)
	$Entries/Spacer2.raise()
	minimum_size_changed()

func add_submenu(label, menu):
	var node = SubMenuEntry.instance()
	node.label = label
	node.menu = menu
	node.hover_box = hover_box
	$Entries.add_child(node)
	$Entries/Spacer2.raise()
	node.menu.connect("menu_closed", self, "close_menu")
	minimum_size_changed()
	empty = false
	return node

func close_menu():
	emit_signal("menu_closed")
	self.hide()

func on_item_pressed(id):
	emit_signal("id_pressed", id)
	emit_signal("menu_closed")
	self.hide()

func reset_contents():
	for entry in $Entries.get_children():
		if entry.has_method("unhover"):
			entry.unhover()

func add_separator():
	var node = HSeparator.new()
	node.add_stylebox_override("separator", seperator_box)
	$Entries.add_child(node)
	minimum_size_changed()

func _get_minimum_size():
	return $Entries.get_minimum_size()