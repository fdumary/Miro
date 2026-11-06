extends Node2D
var kind := "case"
var used := false
var title := ""

func _draw() -> void:
	var ink := Color("272744")
	var pale := Color("c69fa5")
	if kind == "case":
		draw_rect(Rect2(-15, -10, 30, 18), ink)
		draw_rect(Rect2(-15, -10, 30, 18), pale, false, 2)
		draw_line(Vector2(-5, -2), Vector2(7, -2), pale if not used else Color("494d7e"), 3)
	else:
		draw_rect(Rect2(-20, -29, 40, 40), ink)
		draw_rect(Rect2(-20, -29, 40, 40), pale, false, 2)
		for y in [-22, -14, -6, 2]:
			draw_line(Vector2(-14, y), Vector2(14, y), Color("494d7e"), 3)
		draw_string(ThemeDB.fallback_font, Vector2(-20, -35), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, pale)
