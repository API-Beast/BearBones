extends Node

func _ready():
	print(Clipboard.get_text())
	$File.show()