extends Node2D
## A records terminal with one log about Prisoner M-07 (data/terminal_logs.json).
## Optional reading; scripts/inner_conflict.gd opens it with [E].
const INK := Color("272744")
const BLUE := Color("494d7e")
const GLOW := Color("8bb5c9")
var log_entry: Dictionary = {}
var read := false
var time := 0.0

func _ready() -> void:
	add_to_group("security_terminals")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	# A desk with a cathode screen; an unread log blinks a cursor.
	draw_rect(Rect2(-14, 2, 28, 14), BLUE.darkened(0.25))
	draw_rect(Rect2(-14, 2, 28, 2), BLUE.lightened(0.1))
	draw_rect(Rect2(-12, 4, 3, 12), INK)
	draw_rect(Rect2(9, 4, 3, 12), INK)
	var glow := GLOW if not read else GLOW.darkened(0.45)
	for ring in range(3, 0, -1):
		draw_circle(Vector2(0, -9), 8.0 + ring * 5, Color(glow.r, glow.g, glow.b, 0.025))
	draw_rect(Rect2(-11, -20, 22, 20), INK)
	draw_texture_rect(preload("res://assets/library/terminal.png"), Rect2(-9, -18, 18, 18), false, glow)
	if not read and fmod(time, 1.0) < 0.55:
		draw_rect(Rect2(-5, -6, 4, 2), Color("f2d3ab"))
