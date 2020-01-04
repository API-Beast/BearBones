tool
extends OptionButton

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	self.connect("item_selected", self, "clear_text")
	self.connect("item_focused", self, "clear_text")
	clear_text()

func clear_text(tmp=0):
	text = ""
	minimum_size_changed()

func _get_minimum_size():
	return Vector2(30, 18)