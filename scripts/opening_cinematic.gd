extends Control
## Opening (C1), before Level 1 on a new run. 15 s; Tab, Enter, E, Space or Esc skips.
##   0-4.5    storm over the woods: rolling clouds, heavy rain, lightning strikes the far tower
##   4.5-8.5  tilt up the tower through the rain; the PA's calm voice; a flash lights the stone
##   8.5-12   push into the barred window of cell 07; on the thunder a figure sits up
##   12-15    MIRO / LAST MAN STANDING lit by a last flash; YZ33 comes in under the rain
## The rain bed carries on into Level 1 and fades as YZ33 takes over.
const C = preload("res://scripts/cinema.gd")
## Miro's in-game sprite, so the cutscene shows the same Miro the player controls.
const MIRO := preload("res://assets/characters/miro_idle.png")
const NEXT := "res://scenes/intro.tscn"
const LENGTH := 15.0
## Lightning flashes: [time, seed, strength]. Thunder follows each flash.
const STRIKES := [[1.4, 3, 1.0], [1.62, 4, 0.6], [3.4, 8, 0.7], [6.6, 12, 0.9], [10.2, 17, 1.0], [12.25, 21, 0.8]]
var elapsed := 0.0
var frame_count := 0
var leaving := false
var audio: Node
var rain_bed: AudioStreamPlayer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Pixel-art sprite stays crisp when scaled up.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_node("/root/MusicDirector").silence()
	audio = preload("res://scripts/cine_audio.gd").new()
	add_child(audio)
	rain_bed = audio.loop("rain_loop", -8.0, 1.2)
	audio.loop("wind_loop", -20.0, 2.0)
	audio.at(1.5, func(): audio.play("thunder_near", -2.0))
	audio.at(3.9, func(): audio.play("thunder_far", -7.0, 0.92))
	audio.at(6.9, func(): audio.play("thunder_near", -6.0, 0.85))
	audio.at(10.3, func(): audio.play("thunder_near", -1.0, 1.05))
	# The first level's song starts under the title so the cut into the cell lands on the beat.
	audio.at(12.4, func(): get_node("/root/MusicDirector").start_floor(1))
	# The Tower PA announcement (data/interludes.json opening_pa), through the tower speakers.
	audio.at(4.8, func(): get_node("/root/RemoteRadio").say_in_room(str(JSON.parse_string(FileAccess.get_file_as_string("res://data/interludes.json")).opening_pa), "pa"))
	audio.at(12.6, func(): audio.play("thunder_far", -9.0, 0.8))

func _process(delta: float) -> void:
	elapsed += delta
	audio.tick(elapsed)
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
	get_node("/root/MusicDirector").start_floor(1)
	audio.hand_off(rain_bed, 6.0)
	if has_meta("reel"):
		get_meta("reel").call_deferred()
		queue_free()
		return
	get_tree().call_deferred("change_scene_to_file", NEXT)

## 0..1 brightness of the sky at time t (a fast flash with a flicker, then decay).
func lightning(t: float) -> float:
	var best := 0.0
	for strike in STRIKES:
		var since: float = t - strike[0]
		if since >= 0 and since < 0.45:
			var flicker := 1.0 if since < 0.06 or (since > 0.11 and since < 0.16) else 0.55
			best = maxf(best, strike[2] * flicker * (1.0 - since / 0.45))
	return best

## The strike being drawn now, if any: [seed, alpha].
func current_bolt(t: float) -> Array:
	for strike in STRIKES:
		var since: float = t - strike[0]
		if since >= 0 and since < 0.22:
			return [strike[1], 1.0 - since / 0.22]
	return []

func shake(t: float) -> Vector2:
	var amount := 0.0
	for strike in STRIKES:
		var since: float = t - strike[0] - 0.1
		if since >= 0 and since < 0.8 and strike[2] >= 0.9:
			amount = maxf(amount, 2.5 * (1.0 - since / 0.8))
	return Vector2(sin(t * 63.0), cos(t * 51.0)) * amount

func _draw() -> void:
	frame_count += 1
	var unit := size / C.FRAME
	var t := elapsed
	draw_set_transform(shake(t) * unit, 0, unit)
	if t < 4.5:
		shot_storm(t)
	elif t < 8.5:
		shot_tilt(t)
	elif t < 12.0:
		shot_window(t)
	else:
		shot_title(t)
	draw_set_transform(Vector2.ZERO, 0, unit)
	C.fade(self, lightning(t) * 0.4, Color(0.85, 0.88, 1.0))
	C.vignette(self, 0.9)
	C.grain(self, frame_count, 0.05)
	C.letterbox(self, C.phase(t, 0.2, 1.2) * (1.0 - C.phase(t, 12.0, 0.8)))
	var line := ""
	if t >= 1.8 and t < 4.5:
		line = "The tower keeps what it takes."
	elif t >= 4.7 and t < 9.2:
		line = "TOWER PA:  \"Lights out. Cells sealed. Report every cough, including your own.\""
	elif t >= 9.4 and t < 12.0:
		line = "Cell 07."
	C.subtitle(self, line, 1.0)
	draw_string(C.Type.body(), Vector2(16, 352), "[Tab] Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(C.ROSE.r, C.ROSE.g, C.ROSE.b, 0.7))
	C.fade(self, 1.0 - C.phase(t, 0.0, 1.4))
	C.fade(self, C.phase(t, LENGTH - 1.0, 1.0))

## Rain in the woods; the tower far off, struck by lightning. The camera drifts right.
func shot_storm(t: float) -> void:
	var flash := lightning(t)
	C.night_sky(self, Color("07080f").lerp(Color("3a4270"), flash * 0.7), Color("141830").lerp(Color("5b6496"), lightning(t) * 0.6), Vector2(-100, -100))
	C.storm_clouds(self, t, flash, 130)
	var tower_base := Vector2(430 - t * 4.0, 238)
	var bolt := current_bolt(t)
	if not bolt.is_empty():
		var target := tower_base + Vector2(0, -21 * 5.5 - 32) if bolt[0] in [3, 4] else Vector2(150 + bolt[0] * 9, 200)
		C.bolt(self, Vector2(target.x - 40 + bolt[0] * 3, -10), target, bolt[0], bolt[1], 1.6)
	C.tower(self, tower_base, 21, 52, t, 0, 0, 0.3 + flash)
	C.tower_flag(self, tower_base, 21, t * 0.4, 1.0)
	C.pines(self, 250, 50, 44, 0.2, -t * 6)
	C.natural_rain(self, t, lightning(t) * 0.6, -1.0, Rect2(0, 0, 640, 300), 0.6)
	C.pines(self, 285, 70, 70, 0.6, -t * 14)
	C.natural_rain(self, t + 4.0, lightning(t) * 0.6, 300.0)
	C.pines(self, 350, 150, 150, 1.0, -t * 30)

## The camera tilts up the tower face, past each floor's windows, to the emblem.
func shot_tilt(t: float) -> void:
	var tilt := C.ease_in_out(C.phase(t, 4.5, 4.0))
	var flash := lightning(t)
	C.night_sky(self, Color("07080f").lerp(Color("3a4270"), flash * 0.7), Color("141830").lerp(Color("5b6496"), lightning(t) * 0.6), Vector2(-100, -100))
	C.storm_clouds(self, t, flash, 220)
	var bolt := current_bolt(t)
	if not bolt.is_empty():
		C.bolt(self, Vector2(520, -10), Vector2(470, 260), bolt[0], bolt[1], 2.2)
	var base := Vector2(320, 380 + tilt * 420)
	C.tower(self, base, 120, 260, t, 0, 0, 1.0)
	C.tower_flag(self, base, 120, t * 0.4, 1.0)
	if flash > 0:
		# The flash rakes the stone from the right.
		draw_rect(Rect2(320 + 130 - 40, 0, 40, 360), Color(0.85, 0.88, 1.0, 0.25 * flash))
	C.storm_rain(self, t, 0.3, -1, 4.0)

## Push into a barred window; inside, a figure on a bed sits up on the thunder.
func shot_window(t: float) -> void:
	var push := C.ease_in_out(C.phase(t, 8.5, 3.3))
	var flash := lightning(t)
	draw_rect(Rect2(Vector2.ZERO, C.FRAME), Color("20223a"))
	var w := lerpf(60, 520, push)
	var h := lerpf(110, 300, push)
	var window := Rect2(Vector2(320 - w / 2, 180 - h / 2), Vector2(w, h))
	for row in range(14):
		for column in range(16):
			var x := column * 48 - (24 if row % 2 else 0)
			var brick := Color("2e3150").darkened(0.2 + (column * 7 + row) % 3 * 0.05)
			draw_rect(Rect2(x + 1, row * 28 + 1, 46, 26), brick.lerp(Color("8890c0"), flash * 0.35))
	draw_rect(window.grow(6), Color("14152a"))
	draw_rect(window, Color("272744").lerp(Color("5a6090"), lightning(t) * 0.6))
	var floor_y := window.position.y + window.size.y * 0.82
	draw_rect(Rect2(window.position.x + window.size.x * 0.18, floor_y - window.size.y * 0.12, window.size.x * 0.45, window.size.y * 0.06), Color("4a3b4f"))
	var rise := C.ease_out(C.phase(t, 10.25, 0.6))
	# Miro (his in-game sprite) lies on the bunk, then sits up on the thunder: the sprite
	# pivots at his feet from lying flat to upright.
	var figure := Vector2(window.position.x + window.size.x * 0.36, floor_y - window.size.y * 0.12)
	var tall := window.size.y * 0.32
	var lit := Color(1, 1, 1).lerp(Color(0.75, 0.8, 1.1), lightning(t) * 0.6).darkened(0.25 * (1.0 - flash))
	var unit := size / C.FRAME
	var shot := Transform2D(0, unit, 0, shake(t) * unit)
	draw_set_transform_matrix(shot * Transform2D(-PI / 2 * (1.0 - rise), figure + Vector2(window.size.x * 0.06, 0)))
	draw_texture_rect(MIRO, Rect2(Vector2(-tall / 2, -tall), Vector2(tall, tall)), false, lit)
	draw_set_transform_matrix(shot)
	# Bars throw shadows across the cell when the lightning hits.
	for bar in range(1, 5):
		var x := window.position.x + bar * window.size.x / 5
		if flash > 0:
			draw_colored_polygon(PackedVector2Array([Vector2(x, window.position.y), Vector2(x + window.size.x * 0.03, window.position.y), Vector2(x + window.size.x * 0.12, window.end.y), Vector2(x + window.size.x * 0.06, window.end.y)]), Color(0, 0, 0, 0.35 * flash))
		draw_rect(Rect2(x - window.size.x * 0.012, window.position.y, window.size.x * 0.024, window.size.y), Color("8b6d9c"))
	# Rain running down the glass as we get close.
	if push > 0.5:
		for i in range(18):
			var x := window.position.x + C.hash01(i, 90) * window.size.x
			var y := window.position.y + fmod(C.hash01(i, 91) * window.size.y + t * (40.0 + C.hash01(i, 92) * 50.0), window.size.y)
			draw_line(Vector2(x, y), Vector2(x, y + 6), Color(0.8, 0.85, 1.0, 0.25 * (push - 0.5) * 2.0), 1.0)

func shot_title(t: float) -> void:
	var flash := lightning(t)
	draw_rect(Rect2(Vector2.ZERO, C.FRAME), Color("0d0e1a").lerp(Color("2a2f55"), lightning(t) * 0.6))
	C.storm_clouds(self, t, lightning(t) * 0.6, 90)
	var bolt := current_bolt(t)
	if not bolt.is_empty():
		C.bolt(self, Vector2(470, -10), Vector2(420, 120), bolt[0], bolt[1], 1.8)
	C.storm_rain(self, t, 0.12, -1, 2.0)
	var reveal := C.phase(t, 12.2, 1.0)
	C.emblem(self, Vector2(320, 128), 26, Color(C.ROSE.r, C.ROSE.g, C.ROSE.b, reveal * 0.8 + flash * 0.2), 2.5)
	C.title(self, Vector2(320, 214), "Miro", 64, Color(C.PAPER.r, C.PAPER.g, C.PAPER.b, reveal), 6)
	C.title(self, Vector2(320, 248), "Last Man Standing", 22, Color(C.SAND.r, C.SAND.g, C.SAND.b, C.phase(t, 12.8, 0.8)), 3)
