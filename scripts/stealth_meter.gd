extends Control
## Compact meter without the built-in ProgressBar's font-based minimum height.
var value := 1.0:
	set(next):
		value = clampf(next, 0, 1)
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("494d7e"))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * value, size.y)), Color("f2d3ab"))
