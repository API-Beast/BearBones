extends WindowDialog

var object = null
var property = ""

func _ready():
	$Layout/Buttons/Confirm.connect("pressed", self, "confirm")
	$Layout/Buttons/Cancel.connect("pressed", self, "hide")

func confirm():
	if object:
		object.set(property, $Layout/PathSelector.get_abs_path())
		if object.has_method("update"):
			object.update()
	hide()

func set_label(label):
	$Layout/Label.text = label

func set_path_root(path_root):
	$Layout/PathSelector.path_root = path_root

func set_path(path):
	$Layout/PathSelector.value = path

func set_filters(filters):
	$Layout/PathSelector.filters = filters