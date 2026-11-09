extends Control
## After the tower falls: Miro on a beach, finally free (12 s), then the end credits.
## Tab, Esc or Enter skips the beach to the credits, and the credits to the start screen.
## Music: Ethan's emotional chord progression (assets/audio/cine/ending_chords.ogg) on the beach;
## the end credits play Set Me Free.
##   0-4    wide: dawn over the sea, waves rolling in, gulls; Miro small on the sand
##   4-8    closer: Miro leaning back, earbuds in, the MP3 on his lap. "Finally free."
##   8-12   the camera lifts to the sun; the sky opens; into the credits
const C = preload("res://scripts/cinema.gd")
const BEACH := 12.0
## Credits roll slowly for the whole of Set Me Free (2:29): the last line arrives near the end of
## the song, "Thank you for playing" holds, and the start screen loads as the song ends.
const SONG_LENGTH := 149.0
const CREDITS_LENGTH := SONG_LENGTH - 12.0
var scroll_speed := 24.0
const MENU := "res://scenes/main_menu.tscn"
var level: Node
var elapsed := 0.0
var credits_time := -1.0
var frame_count := 0
var audio: Node
var chords: AudioStreamPlayer
var credits: Dictionary = {}
var credits_height := 0.0
## Set by the menu's Credits button: skip the beach and roll the credits.
@export var credits_only := false
var leaving := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var file := FileAccess.open("res://data/credits.json", FileAccess.READ)
	if file:
		credits = JSON.parse_string(file.get_as_text())
	credits_height = 140.0
	for block in credits.get("blocks", []):
		credits_height += 30.0 + 16.0 * block.lines.size()
	scroll_speed = clampf((credits_height + 200.0) / CREDITS_LENGTH, 4.0, 40.0)
	audio = preload("res://scripts/cine_audio.gd").new()
	add_child(audio)
	get_node("/root/MusicDirector").silence()
	audio.loop("waves_loop", -10.0, 2.0)
	audio.loop("wind_loop", -24.0, 3.0)
	# The chords already began under the explosion; carry them on instead of starting them again.
	chords = get_node_or_null("/root/EndingChords")
	if chords == null:
		chords = audio.loop("ending_chords", -4.0, 2.5, "Music")
	else:
		chords.volume_db = -4.0
	audio.at(1.8, func(): audio.play("gulls", -14.0))
	audio.at(6.5, func(): audio.play("gulls", -18.0, 1.1))
	if credits_only:
		elapsed = BEACH
		start_credits()

func _process(delta: float) -> void:
	elapsed += delta
	audio.tick(elapsed)
	if credits_time < 0 and elapsed >= BEACH:
		start_credits()
	if credits_time >= 0:
		credits_time += delta
		if credits_time > SONG_LENGTH + 1.0:
			to_menu()
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	if event.physical_keycode in [KEY_TAB, KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
		if credits_time < 0:
			elapsed = BEACH
			start_credits()
		else:
			to_menu()

func start_credits() -> void:
	if credits_time >= 0:
		return
	credits_time = 0.0
	audio.fade(chords, -40.0, 3.0, true)
	get_node("/root/MusicDirector").play_outro()

func to_menu() -> void:
	if leaving:
		return
	leaving = true
	get_tree().call_deferred("change_scene_to_file", MENU)

func _draw() -> void:
	frame_count += 1
	var unit := size / C.FRAME
	var t := minf(elapsed, BEACH + 30.0)
	# Camera: wide, then closer on Miro, then lifting to the sky.
	var zoom := 1.0 + 0.5 * C.ease_in_out(C.phase(t, 3.6, 1.6)) - 0.35 * C.ease_in_out(C.phase(t, 8.0, 3.5))
	var lift := 90.0 * C.ease_in_out(C.phase(t, 8.0, 4.0))
	var focus := Vector2(300, 290).lerp(Vector2(470, 150), C.ease_in_out(C.phase(t, 8.0, 4.0)))
	draw_set_transform((focus * (1.0 - zoom) + Vector2(0, lift)) * unit, 0, unit * zoom)
	draw_beach(t)
	draw_set_transform(Vector2.ZERO, 0, unit)
	# Sun flare as the camera finds it.
	var flare := C.phase(t, 9.0, 2.5)
	if flare > 0:
		C.glow(self, Vector2(470, 150 + lift - 60), 300 * flare, Color(1, 0.95, 0.8, 0.35 * flare))
	C.vignette(self, 0.6)
	C.grain(self, frame_count, 0.03)
	if credits_time < 0:
		C.letterbox(self, 1.0 - C.phase(t, 9.5, 2.0))
		if t >= 4.6 and t < 8.4:
			C.title(self, Vector2(320, 96), "Finally free.", 20, Color(C.PAPER.r, C.PAPER.g, C.PAPER.b, C.phase(t, 4.6, 0.8) * (1.0 - C.phase(t, 7.8, 0.6))), 2, false)
		draw_string(C.Type.body(), Vector2(16, 352), "[Tab] Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(C.ROSE.r, C.ROSE.g, C.ROSE.b, 0.7))
	else:
		draw_credits()
	C.fade(self, 1.0 - C.phase(t, 0.0, 2.0))

func draw_beach(t: float) -> void:
	C.day_sky(self, Color("5f8fc9"), Color("ffd9a8"), Vector2(470, 150), t, Color("fff1c4"))
	C.birds(self, t, Rect2(80, 60, 480, 70), 5, Color("3a3550"), 4.0)
	# Far off on the horizon, where the tower was, a thin smoke trail still rises.
	for i in range(7):
		var life := fmod(t * 0.08 + i / 7.0, 1.0)
		C.puff(self, Vector2(90 + life * 40.0, 196 - life * 110.0), 4.0 + life * 20.0, Color(0.55, 0.52, 0.6, 0.25 * (1.0 - life)))
	# Sea.
	C.gradient(self, Rect2(-100, 198, 840, 80), Color("3f7aa6"), Color("7fb6c9"))
	# Sun glitter on the water.
	for i in range(40):
		var y := 202.0 + C.hash01(i, 101) * 60.0
		var spread := (y - 198.0) * 0.9 + 6.0
		var x := 470.0 + (C.hash01(i, 102) - 0.5) * spread * 2.0
		var twinkle := 0.5 + 0.5 * sin(t * 5.0 + i * 1.7)
		draw_rect(Rect2(x, y, 3.0 + C.hash01(i, 103) * 6.0, 1), Color(1, 0.96, 0.85, 0.7 * twinkle))
	# Waves rolling up the sand and back, every six seconds.
	var surge := sin(t * TAU / 6.0)
	var shore := 272.0 + surge * 7.0
	draw_rect(Rect2(-100, shore - 2, 840, 200), Color("e9c99a"))
	draw_rect(Rect2(-100, shore - 2, 840, 9.0 + maxf(0.0, -surge) * 6.0), Color("c9a77c"))
	var foam := PackedVector2Array()
	for i in range(34):
		var x := -100.0 + i * 26.0
		foam.append(Vector2(x, shore - 2 + sin(x * 0.05 + t * 2.0) * 1.5))
	draw_polyline(foam, Color(1, 1, 1, 0.85), 2.0)
	for k in range(2):
		var line := PackedVector2Array()
		for i in range(34):
			var x := -100.0 + i * 26.0
			line.append(Vector2(x, 236.0 + k * 16.0 + surge * 3.0 + sin(x * 0.04 + t * 1.5 + k) * 1.5))
		draw_polyline(line, Color(1, 1, 1, 0.35), 1.0)
	# Sand texture.
	for i in range(80):
		draw_rect(Rect2(C.hash01(i, 104) * 840.0 - 100.0, 285.0 + C.hash01(i, 105) * 80.0, 1, 1), Color("b8956b"))
	# A palm leaning in from the left, fronds moving in the breeze.
	var trunk := PackedVector2Array()
	for i in range(9):
		var u := i / 8.0
		trunk.append(Vector2(40 + u * 70 + sin(u * 2.2) * 18.0, 360 - u * 230))
	draw_polyline(trunk, Color("3d2f3f"), 7.0)
	var crown := trunk[trunk.size() - 1]
	for i in range(7):
		var angle := -PI * 0.95 + i * PI * 0.32 + sin(t * 1.4 + i) * 0.08
		var tip := crown + Vector2(cos(angle), sin(angle) * 0.6 + 0.35) * 70.0
		var mid := crown.lerp(tip, 0.5) + Vector2(0, -10)
		draw_polyline(PackedVector2Array([crown, mid, tip]), Color("2c3d33"), 5.0)
	# Footprints from the tree line to where he sits.
	for i in range(8):
		draw_rect(Rect2(150 + i * 17, 318 - i * 2.2 + (i % 2) * 4, 4, 2), Color("c9a77c"))
	# Miro, earbuds in, leaning back. Breathing.
	C.miro_sitting(self, Vector2(300, 302), 1.8, Color("2a2440"), sin(t * 1.6) * 0.5)

func draw_credits() -> void:
	C.fade(self, 0.62 * C.phase(credits_time, 0.0, 2.0))
	var y := 380.0 - credits_time * scroll_speed
	C.title(self, Vector2(320, y), str(credits.get("title", "Miro")), 52, C.PAPER, 4)
	y += 30
	C.title(self, Vector2(320, y), str(credits.get("subtitle", "")), 20, C.SAND, 2)
	y += 60
	for block in credits.get("blocks", []):
		if str(block.heading) != "":
			C.title(self, Vector2(320, y), str(block.heading), 18, C.ROSE, 1)
			y += 18
		for line in block.lines:
			C.title(self, Vector2(320, y), str(line), 14, C.PAPER, 1, false)
			y += 16
		y += 30
	var closing_y := maxf(180.0, y + 40.0)
	C.title(self, Vector2(320, closing_y), str(credits.get("closing", "")), 28, C.SAND, 2)
