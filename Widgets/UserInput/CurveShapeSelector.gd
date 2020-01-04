tool
extends Control

var value : CurveShape setget set_curve_shape
export(Texture) var icon setget set_icon

signal value_changed(new_curve)

func _ready():
	if value == null:
		value = CurveShape.new()
	
	sync_in()
	for slider in $Sliders.get_children():
		if slider is SliderBox:
			slider.connect("changed", self, "sync_out")
		elif slider is LineEdit:
			slider.connect("text_entered", self, "sync_out")
		else:
			for sl in slider.get_children():
				sl.connect("changed", self, "sync_out")
	$Label/CurveType.connect("item_selected", self, "item_selected")
	$Label/CurveType.connect("item_focused", self, "item_selected")
	set_icon(icon)
	
func set_icon(new_icon:Texture):
	if is_inside_tree():
		$Label/Icon.texture = new_icon
	icon = new_icon
	
func set_curve_shape(new_shape:CurveShape):
	value = new_shape
	if is_inside_tree():
		sync_in()
	
func item_selected(new_item):
	value.type = new_item
	for slider in $Sliders.get_children():
		slider.visible = false
	$Sliders/Offsets.visible = true
	match(new_item):
		CurveShape.CONSTANT:
			$Sliders/Threshold.visible = true
		CurveShape.EASE, CurveShape.SYMMETRIC:
			$Sliders/Exponent.visible = true
		CurveShape.OVERSHOOT:
			#$Sliders/Exponent.visible = true
			$Sliders/Amplitude.visible = true
		CurveShape.SINE, CurveShape.NOISE:
			$Sliders/Amplitude.visible = true
			$Sliders/Frequency.visible = true
		CurveShape.MANUAL:
			$Sliders/Manual.visible = true
		CurveShape.FRACTAL:
			$Sliders/Manual.visible = true
	sync_out()

func sync_out(dummy=null):
	value.threshold = $Sliders/Threshold.value
	value.exponent = $Sliders/Exponent.value
	value.amplitude = $Sliders/Amplitude.value
	value.frequency = $Sliders/Frequency.value
	value.offset_start = $Sliders/Offsets/Start.value
	value.offset_end = $Sliders/Offsets/End.value
	value.set_mapping_from_string($Sliders/Manual.text)
	emit_signal("value_changed", value)
	
func sync_in():
	$Sliders/Threshold.value = value.threshold
	$Sliders/Exponent.value = value.exponent
	$Sliders/Amplitude.value = value.amplitude
	$Sliders/Frequency.value = value.frequency
	$Sliders/Offsets/Start.value = value.offset_start
	$Sliders/Offsets/End.value = value.offset_end
	$Label/CurveType.selected = value.type
	$Label/CurveType.clear_text()
	$Sliders/Manual.text = value.get_mapping_string()
	item_selected(value.type)