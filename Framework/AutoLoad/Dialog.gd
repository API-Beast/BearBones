extends Control

var dialogs = {}
var backlog = []
var queue = []
var stack = []
var current = null

func _ready():
	call_deferred("raise")
	for child in $Templates.get_children():
		$Templates.remove_child(child)
		dialogs[child.name] = child
	$BlockerLayer/Blocker.hide()

func _exit_tree():
	for dialog in dialogs.values():
		dialog.free()

func _process(delta):
	if current and current.visible == false:
		display_next()
	elif not queue.empty() and current == null:
		display_next()

func display_next():
	if current:
		backlog.push_back(current)
		current.get_parent().remove_child(current)
		on_dialog_closed(current)
	
	if not stack.empty():
		current = stack.pop_back()
		show_dialog(current)
	elif not queue.empty():
		current = queue.pop_front()
		show_dialog(current)
	else:
		for node in backlog:
			node.queue_free()
		backlog = []
		current = null
		$BlockerLayer/Blocker.hide()

func on_display_dialog(node):
	if node.has_method("on_display_dialog"):
		node.on_display_dialog()

func on_dialog_closed(node):
	if node.has_method("on_dialog_closed"):
		node.on_dialog_closed()

func show_dialog(dialog):
	if dialog.get_parent():
		dialog.get_parent().remove_child(dialog)

	$ActiveLayer.add_child(dialog)
	on_display_dialog(dialog)
	dialog.show()
	if dialog.has_method("invalidate"):
		dialog.call("invalidate")
	dialog.raise()
	dialog.set_anchors_and_margins_preset(Control.PRESET_CENTER, Control.PRESET_MODE_KEEP_SIZE)
	$BlockerLayer/Blocker.show()

func move_to_blocked(dialog):
	if dialog.get_parent():
		dialog.get_parent().remove_child(dialog)

	$BlockedLayer.add_child(dialog)

func queue_dialog(name):
	var node
	if typeof(name) == TYPE_STRING:	
		node = dialogs[name].duplicate(7)
	else:
		node = name
	queue.push_back(node)
	node.theme = self.theme
	return node

func push_dialog(name):
	var node
	if typeof(name) == TYPE_STRING:	
		node = dialogs[name].duplicate(7)
	else:
		node = name
	if current:
		stack.push_back(current)
		move_to_blocked(current)
	current = node
	node.theme = self.theme
	show_dialog(current)
	return node

func push_context(context):
	$ActiveLayer.add_child(context)
	context.raise()

func is_blocking() -> bool:
	return $BlockerLayer/Blocker.visible

func error(msg:String) -> void:
	printerr(msg)
	var node = Dialog.push_dialog("Error")
	node.dialog_text = msg