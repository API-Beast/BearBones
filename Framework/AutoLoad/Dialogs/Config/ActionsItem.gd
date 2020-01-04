extends HBoxContainer

var action = null

func _ready():
	$Primary.connect("pressed", self, "assign_prompt", [0])
	$Secondary.connect("pressed", self, "assign_prompt", [1])
	$Third.connect("pressed", self, "assign_prompt", [2])

func set_action(p_action):
	action = p_action
	$Label.text = action.label
	$Primary.text = action.default_primary_trigger.get_text()
	$Secondary.text = action.default_secondary_trigger.get_text()
	$Third.text = ""

func set_trigger(target, trigger):
	if target == 0:
		$Primary.text = trigger.get_text()
	elif target == 1:
		$Secondary.text = trigger.get_text()
	elif target == 2:
		$Third.text = trigger.get_text()

func assign_prompt(key):
	var diag = Dialog.push_dialog("AssignKey")
	var names = {0:"Primary", 1:"Secondary", 2:"Third"}
	diag.set_text(names[key], action.label)
	diag.connect("trigger_confirmed", $"../..", "assign", [action.name, key])