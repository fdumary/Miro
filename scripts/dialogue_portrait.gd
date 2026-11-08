extends Control
## Small code-native speaker token until final portrait art is supplied.
var speaker := "":
	set(value):
		speaker = value
		queue_redraw()

func _draw() -> void:
	var center := size / 2
	draw_rect(Rect2(center - Vector2(25, 25), Vector2(50, 50)), Color("272744"))
	if speaker == "MIRO":
		draw_texture_rect(preload("res://assets/characters/miro_idle.png"), Rect2(center - Vector2(24, 24), Vector2(48, 48)), false)
	elif speaker == "KEEPER":
		draw_texture_rect(preload("res://assets/characters/standard_keeper_idle.png"), Rect2(center - Vector2(24, 24), Vector2(48, 48)), false)
	elif speaker == "BROTHER":
		draw_rect(Rect2(center + Vector2(-13, 3), Vector2(26, 20)), Color("8b6d9c"))
		draw_circle(center + Vector2(0, -7), 12, Color("c69fa5"))
		draw_rect(Rect2(center + Vector2(-14, -20), Vector2(28, 8)), Color("494d7e"))
	else:
		draw_rect(Rect2(center - Vector2(14, 19), Vector2(28, 38)), Color("f2d3ab"))
		for y in [-10, -2, 6]:
			draw_line(center + Vector2(-8, y), center + Vector2(8, y), Color("8b6d9c"), 2)
