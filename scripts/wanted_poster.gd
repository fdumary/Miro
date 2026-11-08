extends Node2D
## MISSING (stealth) or WANTED - DANGEROUS (offense) poster: the cheapest visible branch signal.
## Art hooks: res://assets/environment/poster_missing.png and poster_wanted.png replace the placeholder.
var wanted := false
const MIRO := preload("res://assets/characters/miro_idle.png")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	var art := "res://assets/environment/poster_wanted.png" if wanted else "res://assets/environment/poster_missing.png"
	draw_rect(Rect2(-14, -18, 28, 36), Color("f2d3ab"))
	draw_rect(Rect2(-14, -18, 28, 36), Color("8b6d9c"), false, 1)
	# Miro's own face, cropped from his sprite: the head and shoulders, printed in sepia.
	draw_texture_rect_region(MIRO, Rect2(-10, -10, 20, 20), Rect2(6, 0, 20, 20), Color(0.55, 0.42, 0.5))
	draw_string(ThemeDB.fallback_font, Vector2(-13, -10), "WANTED" if wanted else "MISSING", HORIZONTAL_ALIGNMENT_CENTER, 26, 6, Color("b62432") if wanted else Color("272744"))
	if wanted:
		draw_line(Vector2(-12, 14), Vector2(12, 6), Color("b62432"), 2)
