extends Control
## Ending (C10): Miro blows the tower from the forest viewpoint. 15 s; Tab skips.
## When it finishes, the finale (beach, then end credits) takes over: scripts/finale.gd.
##   0.0-1.5   Miro steps out of the tree line; slow dolly with parallax pines, moonlight
##   1.5-2.8   the C4 trigger (same art as the in-game C4 pop-up, never the MP3) fills the screen
##   2.8-5.0   wide: sigils ignite floor by floor from the bottom; the ground starts to rumble
##   5.0-6.8   the PA line (MISSING/HUNTED); windows flicker; the tremor grows
##   6.8-11    DETONATION: white flash, chained fireballs up the floors, shock ring, debris,
##             heavy camera shake with a sub-bass hit and rumble; the tower falls into fire
##   11-13.5   Miro in the foreground against the fire, embers drifting; he lowers his head
##   13.5-15   LAST MAN STANDING; fade
signal finished
const C = preload("res://scripts/cinema.gd")
const LENGTH := 15.0
const BLAST := 6.8
const BASE := Vector2(410, 262)
var elapsed := 0.0
var done := false
var level: Node
var frame_count := 0
var audio: Node
var rumble: AudioStreamPlayer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	audio = preload("res://scripts/cine_audio.gd").new()
	add_child(audio)
	audio.loop("wind_loop", -18.0, 1.0)
	# The fight music falls away; this scene is carried by sound design until the beach.
	audio.at(1.5, func():
		get_node("/root/MusicDirector").silence()
		get_node("/root/SoundFX").play_sound("sigil", -8, 1.4))
	audio.at(2.8, func(): rumble = audio.loop("rumble_loop", -14.0, 3.5))
	for floor_index in range(5):
		audio.at(2.9 + floor_index * 0.5, func(): get_node("/root/SoundFX").play_sound("sigil", -14, 0.8 + floor_index * 0.08))
	# The Tower PA, heard far off through the trees, then Miro's last thought (his reputation's line).
	var ending_branch: Dictionary = get_node("/root/Campaign").branch()[get_node("/root/Campaign").reputation()]
	audio.at(4.6, func(): get_node("/root/RemoteRadio").say_in_room(str(ending_branch.ending_pa), "pa", "Voice", -12.0))
	audio.at(11.2, func(): get_node("/root/RemoteRadio").say_in_room(str(ending_branch.ending_thought), "miro", "Thought", 0.0))
	# Ethan's chord progression begins with the blast and carries on into the beach.
	audio.at(BLAST, func():
		var carried: AudioStreamPlayer = audio.loop("ending_chords", -6.0, 3.0, "Music")
		if carried != null:
			carried.get_parent().remove_child(carried)
			carried.name = "EndingChords"
			get_tree().root.add_child(carried))
	audio.at(BLAST, func():
		audio.play("explosion_big", 0.0)
		audio.fade(rumble, -2.0, 0.3)
		audio.loop("fire_loop", -9.0, 2.5))
	audio.at(BLAST + 0.55, func(): audio.play("explosion_big", -7.0, 0.78))
	audio.at(BLAST + 1.3, func(): get_node("/root/SoundFX").play_sound("collapse", -6, 0.7))
	audio.at(10.5, func(): audio.fade(rumble, -16.0, 3.0))

func _process(delta: float) -> void:
	if done:
		return
	if level.paused:
		queue_redraw()
		return
	elapsed += delta
	audio.tick(elapsed)
	queue_redraw()
	if elapsed >= LENGTH:
		finish()

func _unhandled_input(event: InputEvent) -> void:
	if not level.paused and event.is_action_pressed("skip"):
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if done:
		return
	done = true
	finished.emit()
	# Beach, then end credits. Lives on the level's HUD so a retry or a test reset clears it.
	# Its own top layer so the HUD never shows through; a child of the level, so a retry or a
	# test reset clears it.
	if is_instance_valid(level):
		var layer := CanvasLayer.new()
		layer.layer = 90
		var finale: Control = preload("res://scripts/finale.gd").new()
		finale.level = level
		layer.add_child(finale)
		level.add_child(layer)
	queue_free()

## Camera shake in frame pixels: a growing tremor before the blast, a hard kick after.
func shake(t: float) -> Vector2:
	var strength := 0.0
	if t >= 2.8 and t < BLAST:
		strength = 0.4 + 1.6 * C.phase(t, 2.8, BLAST - 2.8)
	elif t >= BLAST:
		strength = 9.0 * exp(-(t - BLAST) * 0.9) + 0.6 * (1.0 - C.phase(t, 10.0, 3.0))
	return Vector2(sin(t * 61.0) + sin(t * 23.0) * 0.5, cos(t * 47.0) + cos(t * 17.0) * 0.5) * strength * 0.67

func _draw() -> void:
	frame_count += 1
	var unit := size / C.FRAME
	var t := elapsed
	var jolt := shake(t)
	# A slight roll on the big hit sells the weight.
	var roll := 0.012 * sin(t * 13.0) * exp(-maxf(0.0, t - BLAST) * 1.2) if t >= BLAST else 0.0
	draw_set_transform(jolt * unit, roll, unit)
	var campaign = get_node("/root/Campaign")
	var branch: Dictionary = campaign.branch()[campaign.reputation()]
	if t < 1.5:
		shot_tree_line(t)
	else:
		shot_tower(t)
	draw_set_transform(Vector2.ZERO, 0, unit)
	# Detonation flash.
	if t >= BLAST:
		C.fade(self, 1.0 - C.phase(t, BLAST, 0.5), Color(1, 0.96, 0.9))
	C.vignette(self, 0.85)
	C.grain(self, frame_count, 0.045)
	C.letterbox(self, C.phase(t, 0.0, 0.8))
	var subtitle := ""
	if t < 1.5:
		subtitle = "The woods. Air that nobody rationed."
	elif t >= 2.9 and t < 4.6:
		subtitle = "Five marks. Five floors."
	elif t >= 4.6 and t < BLAST:
		subtitle = "TOWER PA:  \"%s\"" % branch.ending_pa
	elif t >= 11.2 and t < 14.4:
		subtitle = "\"%s\"" % branch.ending_thought
	C.subtitle(self, subtitle, 1.0)
	draw_string(C.Type.body(), Vector2(16, 352), "[Tab] Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(C.ROSE.r, C.ROSE.g, C.ROSE.b, 0.7))
	# The C4 detonator fills the screen as the charges go. This is the gameplay C4 trigger,
	# not the MP3: the MP3 only comes back on the beach, as a music player.
	if t >= 1.5 and t < 2.8:
		var punch := C.ease_out(C.phase(t, 1.5, 0.25))
		C.fade(self, 0.7 * punch)
		var rect := Rect2(250, 40, 140, 200)
		rect = rect.grow(-20 * (1.0 - punch))
		# His thumb comes down on the button at 2.2 s.
		var press := C.phase(t, 2.15, 0.1) * (1.0 - C.phase(t, 2.4, 0.1))
		preload("res://scripts/remote_screen.gd").draw_c4_trigger(self, rect, "FIRED" if t > 2.2 else "ARMED", absf(sin(t * 9)) if t > 2.2 else 0.3, press)
		# The charge itself, beside the trigger, so the shot reads as C4.
		draw_texture_rect(preload("res://assets/weapons/c4.svg"), Rect2(rect.end.x + 12, rect.get_center().y - 28, 56, 56), false)
		if t > 2.55:
			C.fade(self, (t - 2.55) / 0.25, Color.WHITE)
	if t >= 13.5:
		C.fade(self, 0.55 * C.phase(t, 13.5, 0.6))
		C.title(self, Vector2(320, 190), "Last Man Standing", 38, Color(C.PAPER.r, C.PAPER.g, C.PAPER.b, C.phase(t, 13.5, 0.7)), 3)
		C.fade(self, C.phase(t, 14.3, 0.7))
	if level.paused:
		C.fade(self, 0.6)
		draw_string(C.Type.body(), Vector2(180, 180), "PAUSED — [Esc] Resume", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C.PAPER)

## Miro walks out of the trees toward camera-right; the camera dollies with him.
func shot_tree_line(t: float) -> void:
	C.night_sky(self, Color("0f1224"), Color("2b2f4f"), Vector2(500, 70))
	var dolly := t * 22.0
	C.pines(self, 250, 120, 70, 0.0, -dolly * 0.3)
	C.pines(self, 285, 150, 90, 0.5, -dolly * 0.6)
	draw_rect(Rect2(0, 285, 640, 75), Color("0d1118"))
	for ring in range(5):
		draw_circle(Vector2(300, 300), 90.0 - ring * 15, Color(0.85, 0.85, 1.0, 0.025))
	C.miro(self, Vector2(250 + t * 30, 300), 1.6)
	C.pines(self, 380, 300, 160, 1.0, -dolly * 1.4)

## The tower over the woods: sigils, PA, the blast, the fall, and Miro watching in front.
func shot_tower(t: float) -> void:
	var fire := C.phase(t, BLAST, 1.5)
	var sky_top := Color("0f1224").lerp(Color("3a1a22"), fire)
	var sky_bottom := Color("2b2f4f").lerp(Color("a2452c"), fire)
	C.night_sky(self, sky_top, sky_bottom, Vector2(130, 60))
	var unit := size / C.FRAME
	var shake_offset := shake(t)
	var roll := 0.012 * sin(t * 13.0) * exp(-maxf(0.0, t - BLAST) * 1.2) if t >= BLAST else 0.0
	# Slow push in during the ignition, a punch-out on the blast, then hold.
	var push := 1.0 + 0.14 * C.ease_in_out(C.phase(t, 2.8, 4.0)) - 0.1 * C.ease_out(C.phase(t, BLAST, 0.6))
	draw_set_transform((BASE * (1.0 - push) + shake_offset) * unit, roll, unit * push)
	if fire > 0:
		C.glow(self, BASE + Vector2(0, -60), 260, Color(1.0, 0.45, 0.2, 0.55 * fire * (1.0 - C.phase(t, 12.0, 3.0) * 0.4)))
	C.pines(self, 245, 70, 46, 0.1, 0)
	var ignite := 5.0 * C.phase(t, 2.9, 2.4)
	var collapse := C.ease_in_out(C.phase(t, BLAST + 0.35, 3.4))
	var lit := 1.0 if t < 5.0 else 0.6 + 0.4 * absf(sin(t * 7))
	C.tower(self, BASE, 32, 80, t, ignite, collapse, lit)
	if t < BLAST:
		C.tower_flag(self, BASE, 32, t * 0.4, 0.9)
	# Dust trickling off the tower as the tremor builds.
	if t > 4.0 and t < BLAST:
		for i in range(10):
			var y := fmod(C.hash01(i, 5) * 120.0 + t * 60.0, 120.0)
			draw_rect(Rect2(BASE.x - 30 + C.hash01(i, 6) * 60.0, BASE.y - 150 + y, 1, 2), Color(0.8, 0.75, 0.8, 0.5))
	# Chained blasts: the base first, then each floor up the tower.
	C.explosion(self, BASE + Vector2(0, -12), t - BLAST, 1.6, 1, BASE.y + 10)
	for floor_index in range(5):
		var at := BLAST + 0.12 + floor_index * 0.16
		C.explosion(self, BASE + Vector2((C.hash01(floor_index, 9) - 0.5) * 34.0, -30 - floor_index * 32), t - at, 0.75, 10 + floor_index, BASE.y + 10)
	C.explosion(self, BASE + Vector2(0, -80), t - (BLAST + 0.55), 1.25, 30, BASE.y + 10)
	# What burns afterwards.
	if t > BLAST + 0.4:
		var burn := C.phase(t, BLAST + 0.4, 1.2)
		C.flames(self, BASE + Vector2(0, 4), 200, 80, t, burn, 3)
		C.flames(self, BASE + Vector2(-95, 8), 80, 40, t + 1.7, burn * 0.8, 7)
		C.flames(self, BASE + Vector2(100, 8), 90, 46, t + 0.6, burn * 0.8, 9)
	C.pines(self, 292, 40, 34, 0.6, 12)
	draw_set_transform(shake_offset * unit, roll, unit)
	draw_rect(Rect2(-20, 300, 680, 80), Color("0d1118"))
	# Foreground: Miro, the last man standing, watching it fall; rim-lit by fire after the blast.
	var rim := Color(0.9, 0.85, 0.95, 0.35).lerp(Color(1.0, 0.6, 0.3, 0.75), fire)
	# Foreground trees only at the frame edges, so the tower stays clear.
	for tree in [[20.0, 250.0], [95.0, 190.0], [600.0, 260.0], [655.0, 210.0]]:
		draw_colored_polygon(PackedVector2Array([Vector2(tree[0] - 55, 320), Vector2(tree[0] + 55, 320), Vector2(tree[0], 320 - tree[1])]), Color("0b0e14"))
	C.miro(self, Vector2(170, 312), 2.4, C.ease_in_out(C.phase(t, 11.3, 1.2)), Color("1a1626"), rim)
	# Embers blowing past the camera.
	if t > BLAST + 1.0:
		for i in range(26):
			var life := fmod(t * 0.35 + C.hash01(i, 50), 1.0)
			var x := 660.0 - life * 700.0 + sin(t * 2.0 + i) * 8.0
			var y := 120.0 + C.hash01(i, 51) * 200.0 - life * 60.0
			draw_rect(Rect2(x, y, 2, 2), Color(C.FLAME.r, C.FLAME.g, C.FLAME.b, 0.8 * sin(life * PI)))
