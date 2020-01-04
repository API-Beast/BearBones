tool
extends HBoxContainer

export(Vector2) var min_value = Vector2(2, 2) setget set_min_value
export(Vector2) var max_value = Vector2(128, 128) setget set_max_value
export var step = 1.0
export var curve_shape = 1.0

export var label = "Vector" setget set_label
export var value = Vector2(5, 5) setget set_value, get_value

signal value_changed(new_val)

func _ready():
	for slider in $Sliders.get_children():
		slider.connect("value_changed", self, "update_values", [slider])
		for property in ["step", "curve_shape"]:
			slider.set(property, get(property))

	for property in ["min_value", "max_value"]:
		$Sliders/X.set(property, get(property).x)
		$Sliders/Y.set(property, get(property).y)

	set_value(value)
	set_label(label)
	if not Engine.editor_hint:
		$Chain.pressed = get_node("/root/Session").recover(str(get_path())+"_chain", false)
	update_base_values()

func _exit_tree():
	if not Engine.editor_hint:
		get_node("/root/Session").store(str(get_path())+"_chain", $Chain.pressed)

var base_values = {}

func set_min_value(new_value):
	min_value = new_value
	if is_inside_tree():
		$Sliders/X.min_value = min_value.x
		$Sliders/Y.min_value = min_value.y

func set_max_value(new_value):
	max_value = new_value
	if is_inside_tree():
		$Sliders/X.max_value = max_value.x
		$Sliders/Y.max_value = max_value.y

func update_base_values():
	for slider in $Sliders.get_children():
		base_values[slider] = slider.value

func update_values(value, reference):
	if $Chain.pressed:
		update_base_values()
	else:
		for slider in $Sliders.get_children():
			if slider == reference:
				continue

			var ratio = base_values[slider] / base_values[reference]
			slider.value = value * ratio
	emit_signal("value_changed", get_value())

func set_value(val):
	if has_node("Sliders/X"):
		$Sliders/X.value = val.x
		$Sliders/Y.value = val.y
		value = val
		update_base_values()
	else:
		value = val

func get_value():
	if Engine.editor_hint:
		return value
	if has_node("Sliders/X"):
		return Vector2($Sliders/X.value, $Sliders/Y.value)
	return value

func set_label(text):
	if has_node("Label"):
		$Label.text = text
	label = text