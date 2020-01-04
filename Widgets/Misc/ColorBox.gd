tool
extends Control

export var color = Color(1.0, 0.0, 0.0) setget set_color
export(StyleBox) var box_panel

func set_color(new_color):
	color = new_color
	update()

func _draw():
	draw_rect(Rect2(Vector2(2, 2), rect_size - Vector2(4, 4)), color)
	draw_style_box(box_panel, Rect2(Vector2(2, 2), rect_size - Vector2(4, 4)))