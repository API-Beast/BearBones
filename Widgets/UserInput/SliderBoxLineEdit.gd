extends LineEdit

func _ready():
	connect("text_changed", self, "on_text_changed")

func on_text_changed(text):
	self.rect_min_size = Vector2(min(12 * text.length(), 12 * 5), 0)