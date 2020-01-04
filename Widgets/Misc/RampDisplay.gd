tool
extends Control

export var colors = [Color(0.0, 0.0, 0.0), Color(0.5, 0.5, 0.5), Color(1.0, 1.0, 1.0)] setget set_colors
export var offset = true
export var cell_size = Vector2(16, 16)

func set_colors(new_colors):
	colors = new_colors
	minimum_size_changed()
	update()

func _draw():
	var position = Vector2(0, 0)
	var cell_size = rect_size / Vector2(colors.size(), 1.0)
	if offset:
		cell_size = rect_size / Vector2(colors.size() - 1.0, 1.0)
		position.x -= cell_size.x/2.0
	for col in colors:
		draw_rect(Rect2(position, cell_size), col)
		position.x += cell_size.x

func _get_minimum_size():
	return cell_size * Vector2(colors.size(), 1.0)