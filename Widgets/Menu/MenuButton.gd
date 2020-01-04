extends Button

var menu = null

const PopupMenu = preload("res://Widgets/Menu/PopupMenu.tscn")

func _ready():
	menu = PopupMenu.instance()
	Dialog.add_child(menu)

func _pressed():
	menu.popup(Rect2(rect_position+rect_size*Vector2(0, 1), menu.get_combined_minimum_size()))

func get_popup():
	return menu