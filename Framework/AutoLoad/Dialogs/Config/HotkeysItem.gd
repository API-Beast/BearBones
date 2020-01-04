extends HBoxContainer

var label
var id
var first_scancode = 0
var second_scancode = 0
var third_scancode = 0

func _ready():
	$Label.text = label
	update_button_texts()

	$Primary.connect("pressed", self, "assign_prompt", [0])
	$Secondary.connect("pressed", self, "assign_prompt", [1])
	$Third.connect("pressed", self, "assign_prompt", [2])

func set_scancode(target, scancode):
	if target == 0:
		first_scancode = scancode
	elif target == 1:
		second_scancode = scancode
	elif target == 2:
		third_scancode = scancode

	update_button_texts()

func update_button_texts():
	$Primary.text = Functions.get_hotkey_text(first_scancode)
	$Secondary.text = Functions.get_hotkey_text(second_scancode)
	$Third.text = Functions.get_hotkey_text(third_scancode)

func assign_prompt(key):
	var diag = Dialog.push_dialog("AssignKey")
	diag.set_scancode_only()
	var names = {0:"Primary", 1:"Secondary", 2:"Third"}
	diag.set_text(names[key], label)
	diag.connect("scancode_confirmed", $"../..", "assign", [id, key])
