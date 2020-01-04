extends Node

func _init():
	Actions.register_placeholder_action("OpenContext", "Open Context Menu", [InputEventMouseButton, BUTTON_RIGHT])
	
	Actions.register_placeholder_action("ZoomInFine", "Zoom In (Fine)", [InputEventMouseButton, BUTTON_WHEEL_UP])
	Actions.register_placeholder_action("ZoomOutFine", "Zoom Out (Fine)", [InputEventMouseButton, BUTTON_WHEEL_DOWN])

	Actions.register_placeholder_action("ZoomInUI", "UI-Zoom In", [InputEventKey, KEY_KP_ADD, KEY_MASK_CTRL])
	Actions.register_placeholder_action("ZoomOutUI", "UI-Zoom Out", [InputEventKey, KEY_KP_SUBTRACT, KEY_MASK_CTRL])
	
	Actions.register_placeholder_action("ZoomIn", "Zoom In", [InputEventKey, KEY_KP_ADD])
	Actions.register_placeholder_action("ZoomOut", "Zoom Out", [InputEventKey, KEY_KP_SUBTRACT])

	Actions.register_placeholder_action("MoveCanvas", "Move Canvas", [InputEventMouseButton, BUTTON_MIDDLE], [InputEventKey, KEY_SPACE])