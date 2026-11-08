extends Control
## Compact gameplay confirmation; the device art is also shared with cinematics.
var left := 1.2
var full_screen := false
var label := "SIGNAL SENT"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not full_screen:
		position = Vector2(505, 259)
		size = Vector2(119, 62)

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

## The C4 trigger: a rugged olive clacker with an antenna, a status LED, a flipped-up safety
## cover and a red firing button. Deliberately unlike the MP3 (purple, round button, sigil
## screen) so the C4 pop-up and the ending's close-up never read as the MP3. `press` 0..1
## pushes the button in; `pulse` drives the LED.
static func draw_c4_trigger(canvas: CanvasItem, rect: Rect2, text: String, pulse: float, press := 0.0) -> void:
	var w := rect.size.x
	var olive := Color("4d5a32")
	var dark := Color("262c19")
	# Antenna out of the top-left corner.
	var antenna_base := rect.position + Vector2(w * 0.2, rect.size.y * 0.12)
	canvas.draw_line(antenna_base, antenna_base + Vector2(0, -rect.size.y * 0.22), dark, maxf(1.0, w * 0.05))
	canvas.draw_circle(antenna_base + Vector2(0, -rect.size.y * 0.22), maxf(1.0, w * 0.045), dark)
	# Body, with hazard stripes along the bottom.
	var body := Rect2(rect.position + Vector2(0, rect.size.y * 0.12), rect.size * Vector2(1.0, 0.88))
	var box := StyleBoxFlat.new()
	box.bg_color = olive
	box.border_color = dark
	box.set_border_width_all(maxi(1, int(w * 0.03)))
	box.set_corner_radius_all(maxi(1, int(w * 0.05)))
	canvas.draw_style_box(box, body)
	var stripe_h := body.size.y * 0.1
	var stripe_y := body.end.y - stripe_h * 1.6
	for i in range(6):
		var x0 := body.position.x + w * 0.08 + i * w * 0.15
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x0, stripe_y + stripe_h), Vector2(x0 + w * 0.07, stripe_y), Vector2(x0 + w * 0.12, stripe_y), Vector2(x0 + w * 0.05, stripe_y + stripe_h)]), Color("e0b03a"))
	# Status LED and a small amber readout.
	var led := Color(1.0, 0.18, 0.12, 0.45 + 0.55 * pulse)
	canvas.draw_circle(body.position + Vector2(w * 0.82, body.size.y * 0.1), maxf(1.0, w * 0.06), led)
	var screen := Rect2(body.position + Vector2(w * 0.12, body.size.y * 0.06), Vector2(w * 0.56, body.size.y * 0.16))
	canvas.draw_rect(screen, Color("1a1a12"))
	var font_size := int(maxf(6, screen.size.y * 0.62))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(screen.position.x, screen.end.y - screen.size.y * 0.22), text, HORIZONTAL_ALIGNMENT_CENTER, screen.size.x, font_size, Color("ffb347"))
	# Firing button in a square guard, the safety cover flipped up behind it.
	var center := body.position + Vector2(w * 0.5, body.size.y * 0.55)
	var guard := w * 0.3
	canvas.draw_rect(Rect2(center - Vector2(guard, guard * 0.9), Vector2(guard * 2, guard * 0.35)), Color(0.85, 0.12, 0.1, 0.55))
	canvas.draw_rect(Rect2(center - Vector2(guard, guard * 0.55), Vector2(guard * 2, guard * 1.5)), dark)
	var radius := w * 0.2 * (1.0 - 0.12 * press)
	canvas.draw_circle(center + Vector2(0, w * 0.03 * press), radius, Color("c0281f"))
	canvas.draw_circle(center + Vector2(-radius * 0.3, -radius * 0.3 + w * 0.03 * press), radius * 0.35, Color(1, 0.55, 0.5, 0.6))

func _draw() -> void:
	var pulse := absf(sin(Time.get_ticks_msec() / 90.0))
	if full_screen:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55))
		var height := size.y * 0.3
		draw_remote(self, Rect2(Vector2(size.x / 2 - height * 0.35, size.y * 0.1), Vector2(height * 0.7, height)), label, pulse)
	else:
		draw_c4_trigger(self, Rect2(Vector2(75, 0), Vector2(44, 62)), "C4", pulse, 1.0)
		draw_string(ThemeDB.fallback_font, Vector2(0, 30), "C4 DETONATED", HORIZONTAL_ALIGNMENT_CENTER, 72, 10, Color("f2d3ab"))
