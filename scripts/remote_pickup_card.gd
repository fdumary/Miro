extends Control
## A 2.8 s close-up when Miro takes the MP3 player (the remote) off the first guard.
## Doesn't pause play or block input: the remote slides up beside the screen edge, its
## screen wakes with a track title, and Miro's hand closes on it.
const C = preload("res://scripts/cinema.gd")
const LENGTH := 2.8
var elapsed := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("/root/SoundFX").play_sound("sigil", -12, 1.6)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= LENGTH:
		queue_free()

func _draw() -> void:
	var unit := size / C.FRAME
	draw_set_transform(Vector2.ZERO, 0, unit)
	var t := elapsed
	var into := C.ease_out(C.phase(t, 0.0, 0.35))
	var away := C.ease_in_out(C.phase(t, LENGTH - 0.4, 0.4))
	var amount := into * (1.0 - away)
	# Thin bars and a soft darkening on the right third, so the play area stays visible.
	var bar := 18.0 * amount
	draw_rect(Rect2(0, 0, 640, bar), Color(0, 0, 0, 0.85))
	draw_rect(Rect2(0, 360 - bar, 640, bar), Color(0, 0, 0, 0.85))
	for i in range(6):
		draw_rect(Rect2(640 - 120 + i * 20, 240, 120 - i * 20, 120), Color(0, 0, 0, 0.06 * amount))
	# Kept small (pocket-sized, about an eighth of the screen height) so it never dominates play.
	var rect := Rect2(Vector2(592, 360 - bar - 52 * amount), Vector2(30, 44))
	var wake := C.phase(t, 0.5, 0.4)
	preload("res://scripts/remote_screen.gd").draw_remote(self, rect, "MP3" if wake < 1.0 else "▶ PLAY", 0.3 + 0.7 * wake * absf(sin(t * 4.0)))
	# Fingers wrapping the body.
	for f in range(3):
		draw_rect(Rect2(rect.position.x - 3, rect.position.y + 25 + f * 5, 6, 3), Color("c69fa5"))
	var text_alpha := C.phase(t, 0.6, 0.4) * (1.0 - away)
	C.title(self, Vector2(470, 306 + (1.0 - amount) * 10.0), "MP3 player", 12, Color(C.SAND.r, C.SAND.g, C.SAND.b, text_alpha), 1, false)
	C.title(self, Vector2(470, 319 + (1.0 - amount) * 10.0), "off the guard. Still warm.", 9, Color(C.PAPER.r, C.PAPER.g, C.PAPER.b, text_alpha), 1, false)
