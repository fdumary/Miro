extends Control
## The remote is the detonator. A small remote/MP3 screen pops up whenever charges are detonated,
## and fills the screen in the ending. Art hook: res://assets/ui/remote_screen.png (portrait,
## screen area roughly the middle 70%) replaces the placeholder body.
var left := 1.2
var full_screen := false
var label := "SIGNAL SENT"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not full_screen:
		position = Vector2(560, 250)
		size = Vector2(64, 92)

func _process(delta: float) -> void:
	if full_screen:
		queue_redraw()
		return
	left -= delta
	queue_redraw()
	if left <= 0:
		queue_free()

## Draws the remote in a rectangle; also used by the ending cinematic.
static func draw_remote(canvas: CanvasItem, rect: Rect2, text: String, pulse: float) -> void:
	if ResourceLoader.exists("res://assets/ui/remote_screen.png"):
		canvas.draw_texture_rect(load("res://assets/ui/remote_screen.png"), rect, false)
	else:
		var body := StyleBoxFlat.new()
		body.bg_color = Color("494d7e")
		body.border_color = Color("272744")
		body.set_border_width_all(2)
		body.set_corner_radius_all(int(rect.size.x * 0.12))
		canvas.draw_style_box(body, rect)
	var screen := Rect2(rect.position + rect.size * Vector2(0.15, 0.1), rect.size * Vector2(0.7, 0.45))
	canvas.draw_rect(screen, Color("272744"))
	var center := screen.get_center()
	var r := screen.size.y * 0.28
	var glow := Color(0.95, 0.83, 0.67, 0.5 + 0.5 * pulse)
	# The sigil, upside-down Keeper service glyph.
	canvas.draw_polyline(PackedVector2Array([center + Vector2(-r, -r * 0.7), center + Vector2(0, r), center + Vector2(r, -r * 0.7), center + Vector2(-r, -r * 0.7)]), glow, maxf(1.0, r * 0.15))
	canvas.draw_line(center + Vector2(0, -r * 1.2), center + Vector2(0, r * 1.2), glow, maxf(1.0, r * 0.15))
	var font_size := int(maxf(6, screen.size.y * 0.12))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(screen.position.x, screen.end.y - 2), text, HORIZONTAL_ALIGNMENT_CENTER, screen.size.x, font_size, Color("f2d3ab"))
	var button := rect.position + rect.size * Vector2(0.5, 0.75)
	canvas.draw_circle(button, rect.size.x * 0.16, Color("8b6d9c"))
	canvas.draw_circle(button, rect.size.x * 0.07, Color("f2d3ab"))

func _draw() -> void:
	var pulse := absf(sin(Time.get_ticks_msec() / 90.0))
	if full_screen:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
		var height := size.y * 0.8
		draw_remote(self, Rect2(Vector2(size.x / 2 - height * 0.35, size.y * 0.1), Vector2(height * 0.7, height)), label, pulse)
	else:
		draw_remote(self, Rect2(Vector2.ZERO, size), label, pulse)
