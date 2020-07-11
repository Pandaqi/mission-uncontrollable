extends Node2D

var pos1 = Vector2.ZERO
var pos2 = Vector2.ZERO

func _draw():
	draw_line(pos1, pos2, Color(1.0, 0, 0), 1.0)

func set_line(p1, p2):
	pos1 = p1
	pos2 = p2
