extends Control
## Opening (C1), before Level 1 on a new run. About 17 s; Tab, Enter, E or Space skips.
##   0-4    storm over the woods; lightning shows the tower on the horizon
##   4-9    tilt up the tower, floor by floor; the PA's calm voice
##   9-13   push into one barred window: cell 07, a figure on the bed sits up
##   13-17  title: MIRO / LAST MAN STANDING, fade into the cell
const C = preload("res://scripts/cinema.gd")
const NEXT := "res://scenes/intro.tscn"
const LENGTH := 17.0
var elapsed := 0.0
var frame_count := 0
var leaving := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("/root/MusicDirector").silence()

func _process(delta: float) -> void:
	elapsed += delta
	if absf(elapsed - 2.6) < delta or absf(elapsed - 10.8) < delta:
		get_node("/root/SoundFX").play_sound("collapse", -26, 0.55)
	queue_redraw()
	if elapsed >= LENGTH:
		leave()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_TAB, KEY_ENTER, KEY_E, KEY_SPACE, KEY_ESCAPE]:
		get_viewport().set_input_as_handled()
		leave()

func leave() -> void:
	if leaving:
		return
	leaving = true
	get_tree().call_deferred("change_scene_to_file", NEXT)

func lightning(t: float) -> float:
	for strike in [2.6, 2.85, 10.8]:
		if t >= strike and t < strike + 0.18:
			return 1.0 - (t - strike) / 0.18
	return 0.0

func _draw() -> void:
	frame_count += 1
	var unit := size / C.FRAME
	var t := elapsed
	draw_set_transform(Vector2.ZERO, 0, unit)
	if t < 4.0:
		shot_storm(t)
	elif t < 9.0:
		shot_tilt(t)
	elif t < 13.0:
		shot_window(t)
	else:
		shot_title(t)
	draw_set_transform(Vector2.ZERO, 0, unit)
	C.fade(self, lightning(t) * 0.55, Color(0.85, 0.88, 1.0))
	C.vignette(self, 0.85)
	C.grain(self, frame_count, 0.05)
	C.letterbox(self, C.phase(t, 0.2, 1.2) * (1.0 - C.phase(t, 13.0, 0.8)))
	var line := ""
	if t >= 1.0 and t < 4.0:
		line = "The tower keeps what it takes."
	elif t >= 5.0 and t < 9.0:
		line = "TOWER PA:  \"Lights out. Cells sealed. Report every cough, including your own.\""
	elif t >= 10.0 and t < 13.0:
		line = "Cell 07."
	C.subtitle(self, line, minf(1.0, C.phase(t, 1.0, 0.6) + (1.0 if t >= 4.0 else 0.0)))
	draw_string(ThemeDB.fallback_font, Vector2(16, 352), "[Tab] Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(C.ROSE.r, C.ROSE.g, C.ROSE.b, 0.7))
	C.fade(self, 1.0 - C.phase(t, 0.0, 1.4))
	C.fade(self, C.phase(t, LENGTH - 1.2, 1.2))

## Rain in the woods; the tower far off, shown by lightning.
func shot_storm(t: float) -> void:
	C.night_sky(self, Color("0a0c18"), Color("1d2140"), Vector2(560, 50))
	var flash := lightning(t)
	C.tower(self, Vector2(430, 220), 16, 40, t, 0, 0, 0.4 + flash)
	C.pines(self, 230, 80, 50, 0.2, -t * 6)
	C.pines(self, 270, 120, 80, 0.6, -t * 14)
	C.rain(self, t, 0.22)
	C.pines(self, 340, 260, 150, 1.0, -t * 30)

## The camera tilts up the tower face, past each floor's windows, to the emblem.
func shot_tilt(t: float) -> void:
	var tilt := C.ease_in_out(C.phase(t, 4.0, 5.0))
	C.night_sky(self, Color("0a0c18"), Color("1d2140"), Vector2(560, 50))
	var base := Vector2(320, 380 + tilt * 420)
	C.tower(self, base, 120, 260, t, 0, 0, 1.0)
	C.rain(self, t, 0.18)

## Push into a barred window; inside, a figure on a bed sits up.
func shot_window(t: float) -> void:
	var push := C.ease_in_out(C.phase(t, 9.0, 3.5))
	draw_rect(Rect2(Vector2.ZERO, C.FRAME), Color("20223a"))
	var w := lerpf(60, 520, push)
	var h := lerpf(110, 300, push)
	var window := Rect2(Vector2(320 - w / 2, 180 - h / 2), Vector2(w, h))
	# Masonry around the window.
	for row in range(14):
		for column in range(16):
			var x := column * 48 - (24 if row % 2 else 0)
			draw_rect(Rect2(x + 1, row * 28 + 1, 46, 26), Color("2e3150").darkened(0.2 + (column * 7 + row) % 3 * 0.05))
	draw_rect(window.grow(6), Color("14152a"))
	draw_rect(window, Color("272744"))
	# The cell: a bed and a figure sitting up.
	var floor_y := window.position.y + window.size.y * 0.82
	draw_rect(Rect2(window.position.x + window.size.x * 0.18, floor_y - window.size.y * 0.12, window.size.x * 0.45, window.size.y * 0.06), Color("4a3b4f"))
	var rise := C.ease_out(C.phase(t, 10.6, 1.2))
	var figure := Vector2(window.position.x + window.size.x * 0.36, floor_y - window.size.y * 0.12)
	draw_circle(figure + Vector2(-window.size.x * 0.08 * (1 - rise), -window.size.y * (0.04 + 0.14 * rise)), window.size.y * 0.045, Color("c69fa5"))
	draw_rect(Rect2(figure + Vector2(-window.size.x * 0.03, -window.size.y * 0.12 * rise), Vector2(window.size.x * 0.06, window.size.y * 0.12 * rise + 2)), Color("c69fa5"))
	# Lightning through the bars.
	var flash := lightning(t)
	if flash > 0:
		draw_rect(window, Color(0.85, 0.88, 1.0, 0.25 * flash))
	for bar in range(1, 5):
		draw_rect(Rect2(window.position.x + bar * window.size.x / 5 - window.size.x * 0.012, window.position.y, window.size.x * 0.024, window.size.y), Color("8b6d9c"))

func shot_title(t: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, C.FRAME), Color("0d0e1a"))
	C.rain(self, t, 0.08)
	var reveal := C.phase(t, 13.2, 1.2)
	C.emblem(self, Vector2(320, 140), 26, Color(C.ROSE.r, C.ROSE.g, C.ROSE.b, reveal * 0.8), 2.5)
	C.title(self, Vector2(320, 214), "MIRO", 40, Color(C.PAPER.r, C.PAPER.g, C.PAPER.b, reveal), 14)
	C.title(self, Vector2(320, 244), "LAST MAN STANDING", 12, Color(C.SAND.r, C.SAND.g, C.SAND.b, C.phase(t, 14.0, 1.0)), 6)
