extends Control

var page = null

func _ready():
	for child in $Scroller/Contents.get_children():
		child.hide()
		$PageList.add_item(child.name)
	activate_page(0)
	$PageList.select(0)
	$PageList.connect("item_selected", self, "activate_page")
	$Buttons/Ok.connect("pressed", self, "confirm")
	$Buttons/Cancel.connect("pressed", self, "hide")
	$Buttons/Apply.connect("pressed", self, "apply")
	$Buttons/Reset.connect("pressed", self, "reset_to_default")

func activate_page(pg):
	for child in $Scroller/Contents.get_children():
		child.hide()
	page = $Scroller/Contents.get_child(pg)
	page.show()

func confirm():
	apply()
	hide()

func apply():
	for child in $Scroller/Contents.get_children():
		if child.was_modified():
			child.save_data()
		else:
			print("Child was not modified ", child.name)

func reset_to_default():
	page.reset()