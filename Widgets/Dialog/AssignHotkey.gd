extends WindowDialog

var new_trigger = null
var new_scancode = null
var scancode_only = false

signal trigger_confirmed(trigger)
signal scancode_confirmed(scancode)

func _ready():
	$Content/Buttons/Ok.connect("pressed", self, "confirm")
	$Content/Buttons/Cancel.connect("pressed", self, "hide")
	$Content/Buttons/Remove.connect("pressed", self, "remove_hotkey")
	$Content/Panel.connect("received_input_event", self, "assign_trigger")

func set_text(target, name):
	$Content/Label.text = "Assign {target} Hotkey for \"{name}\"".format({"target": target, "name": name})

func set_scancode_only():
	scancode_only = true
	$Content/Panel/Label.text = "Press Key"

func assign_trigger(e):
	var trigger = InputTrigger.new()
	if e is InputEventKey:
		trigger.scancode = e.scancode
	if e is InputEventMouse:
		trigger.mouse_button = e.button_index
		trigger.doubleclick = e.doubleclick
	if e is InputEventWithModifiers:
		trigger.control = e.control
		trigger.command = e.command
		trigger.shift = e.shift
		trigger.meta = e.meta
		trigger.alt = e.alt

	new_trigger = trigger

	if scancode_only:
		if e is InputEventKey:
			new_scancode = e.get_scancode_with_modifiers()
			$Content/Panel/Label.text = Functions.get_hotkey_text(new_scancode)
	else:
		$Content/Panel/Label.text = trigger.get_text()

func remove_hotkey():
	new_trigger = InputTrigger.new()
	new_scancode = 0
	$Content/Panel/Label.text = "(no key)"

func confirm():
	if new_trigger != null:
		emit_signal("trigger_confirmed", new_trigger)
	if new_scancode != null:
		emit_signal("scancode_confirmed", new_scancode)
	hide()
