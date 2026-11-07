@tool
extends "res://scripts/environment_props.gd"
## Shared architectural blockout, without Level 1's cell-specific decoration.
func _draw() -> void:
	draw_rect(Rect2(0, 0, 1120, 756), Color("272744"))
	for row in range(27):
		for column in range(24):
			var x := column * 48 - (24 if row % 2 else 0)
			draw_rect(Rect2(x + 1, row * 28 + 1, 46, 26), Color("494d7e").darkened(0.35 + (column % 3) * 0.04))
	for x in [28, 420, 812, 1092]:
		draw_rect(Rect2(x, 0, 20, 756), Color("494d7e"))
	for point in [Vector2(180, 155), Vector2(530, 155), Vector2(950, 155), Vector2(450, 350), Vector2(850, 350), Vector2(200, 575), Vector2(700, 575)]:
		draw_rect(Rect2(point, Vector2(8, 14)), Color("8b6d9c"))
		draw_rect(Rect2(point + Vector2(2, -5), Vector2(4, 9)), Color("f2d3ab"))
	for point in [Vector2(980, 252), Vector2(980, 448), Vector2(530, 672)]:
		draw_grounded(CRATE, point)
	for point in [Vector2(1035, 252), Vector2(350, 448), Vector2(700, 672)]:
		draw_grounded(SHROOMS, point)
