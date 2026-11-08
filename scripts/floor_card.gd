extends Control
## In-level cinematic cards over the opening seconds of a floor or a story beat (non-blocking:
## they never hold up dialogue or controls, and any key that advances dialogue dismisses them).
##   "floor": letterbox, the camera settles in from a closer zoom, big floor number and title,
##            the tower's emblem and the branch report (MISSING/HUNTED) underneath
##   "alarm": Level 5 guitar pickup, red alarm sweeps and ALARM
##   "name":  a character name card (Niro's first appearance)
const C = preload("res://scripts/cinema.gd")
var mode := "floor"
var heading := ""
var title_text := ""
var detail := ""
var accent := Color("c69fa5")
var length := 3.4
var elapsed := 0.0
var level: Node
var camera: Camera2D
var frame_count := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if level != null and is_instance_valid(level.player):
		camera = level.player.get_node_or_null("Camera2D")

func _process(delta: float) -> void:
	if level != null and level.get("paused"):
		return
	elapsed += delta
	if mode == "floor" and is_instance_valid(camera):
		var settle := C.ease_in_out(C.phase(elapsed, 0.0, length * 0.8))
		var zoom := lerpf(1.35, 1.0, settle)
		camera.zoom = Vector2(zoom, zoom)
	queue_redraw()
	if elapsed >= length:
		finish()

func finish() -> void:
	if is_instance_valid(camera):
		camera.zoom = Vector2.ONE
	queue_free()

func _draw() -> void:
	frame_count += 1
	draw_set_transform(Vector2.ZERO, 0, size / C.FRAME)
	var t := elapsed
	var out := 1.0 - C.phase(t, length - 0.6, 0.6)
	var into := C.phase(t, 0.0, 0.5)
	var alpha := into * out
	if mode == "alarm":
		var pulse := 0.5 + 0.5 * sin(t * 12.0)
		C.fade(self, 0.22 * pulse * out, Color(0.9, 0.1, 0.15))
		C.letterbox(self, alpha)
		C.title(self, Vector2(320, 70), "ALARM", 22, Color(1, 0.85, 0.85, alpha * (0.6 + 0.4 * pulse)), 10)
		return
	C.letterbox(self, alpha)
	C.vignette(self, 0.6 * alpha)
	if mode == "name":
		C.title(self, Vector2(320, 300), title_text, 26, Color(C.PAPER.r, C.PAPER.g, C.PAPER.b, alpha), 12)
		if not detail.is_empty():
			C.title(self, Vector2(320, 318), detail, 9, Color(accent.r, accent.g, accent.b, alpha), 4)
		return
	# Floor card, lower third (bubbles near Miro stay readable): emblem, number, rule, title, report.
	var slide := (1.0 - C.ease_out(into)) * -14
	var left := 34.0 + slide
	C.emblem(self, Vector2(left + 14, 262), 12, Color(accent.r, accent.g, accent.b, 0.75 * alpha), 2)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(left + 36, 274), heading, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(C.PAPER.r, C.PAPER.g, C.PAPER.b, alpha))
	var line_width := 150.0 * C.ease_out(C.phase(t, 0.2, 0.8))
	draw_rect(Rect2(left + 88, 262, line_width, 1), Color(accent.r, accent.g, accent.b, alpha))
	C.title(self, Vector2(left + 88 + 75, 256), title_text, 11, Color(C.SAND.r, C.SAND.g, C.SAND.b, alpha), 4)
	if not detail.is_empty():
		draw_string(font, Vector2(left + 88, 278), detail, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(C.ROSE.r, C.ROSE.g, C.ROSE.b, alpha * C.phase(t, 0.8, 0.6)))
