extends Node

var file_dialog = null

func _ready():
	file_dialog = NativeFileDialog.new()
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.show()