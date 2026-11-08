extends Node2D
## MISSING (stealth) or WANTED - DANGEROUS (offense) poster: the cheapest visible branch signal.
## Art hooks: res://assets/environment/poster_missing.png and poster_wanted.png replace the placeholder.
var wanted := false

func _draw() -> void:
	var art := "res://assets/environment/poster_wanted.png" if wanted else "res://assets/environment/poster_missing.png"
	if ResourceLoader.exists(art):
		draw_texture_rect(load(art), Rect2(-14, -18, 28, 36), false)
		return
	draw_rect(Rect2(-14, -18, 28, 36), Color("f2d3ab"))
	draw_rect(Rect2(-14, -18, 28, 36), Color("8b6d9c"), false, 1)
	draw_circle(Vector2(0, -4), 6, Color("8b6d9c"))
	draw_rect(Rect2(-6, 2, 12, 8), Color("8b6d9c"))
	draw_string(ThemeDB.fallback_font, Vector2(-13, -10), "WANTED" if wanted else "MISSING", HORIZONTAL_ALIGNMENT_CENTER, 26, 6, Color("b62432") if wanted else Color("272744"))
	if wanted:
		draw_line(Vector2(-12, 14), Vector2(12, 6), Color("b62432"), 2)
