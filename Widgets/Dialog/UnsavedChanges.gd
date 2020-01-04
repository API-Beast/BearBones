extends WindowDialog

var selected_action = "Cancel"

func _ready():
	$Layout/Buttons/Save.connect("pressed", self, "select_action", ["Save"])
	$Layout/Buttons/Discard.connect("pressed", self, "select_action", ["Discard"])
	$Layout/Buttons/Cancel.connect("pressed", self, "select_action", ["Cancel"])

func select_action(action):
	selected_action = action
	hide()

func add_item(label):
	$Layout/List.add_item(label)