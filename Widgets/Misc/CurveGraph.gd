extends Control

var shape : CurveShape setget set_shape
export var gamma := 1.0
export var resolution := 100
export var antiAliased := true
export var bg_color := Color(1.0, 1.0, 1.0, 0.2)
export var min_val := 0.0
export var max_val := 1.0

func _ready():
	if shape == null:
		shape = CurveShape.new()
	
func set_shape(new_shape):
	shape = new_shape
	update()
	
func _draw()->void:
	if shape == null:
		return
		
	var points := PoolVector2Array()
	var last_point := Vector2(0, rect_size.y)
	var last_x := 0.0
	points.resize(resolution)
	for i in resolution:
		var x:float = i / float(resolution-1)
		var y := shape.calculate(pow(x, gamma))
		y = inverse_lerp(min_val, max_val, y)
		var point := Vector2(x, 1.0 - y) * rect_size
		points.set(i, point)
		
		if last_x != x:
			var poly := PoolVector2Array()
			poly.resize(4)
			
			if (last_point.y > rect_size.y) == (point.y > rect_size.y): # Skip bad polygons
				poly.set(0, Vector2(last_x, 1.0) * rect_size)
				poly.set(1, last_point)
				poly.set(2, point)
				poly.set(3, Vector2(x, 1.0) * rect_size)
				draw_colored_polygon(poly, bg_color)

		last_point = point
		last_x = x
		
	draw_polyline(points, Color.white, 2.0, antiAliased)
	points.resize(resolution + 3)
	points.set(resolution, Vector2(1.0, 1.0) * rect_size)
	points.set(resolution+1, Vector2(0.0, 1.0) * rect_size)
	points.set(resolution+2, points[0])
	#