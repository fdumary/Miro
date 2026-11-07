extends Control
## Prepared in-engine fallback for mirospec.md final encounter and cinematic rules.
signal finished
var elapsed := 0.0
var done := false
var level: Node
var collapse_sounded := false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if done:
		return
	if level.paused:
		queue_redraw()
		return
	elapsed += delta
	if elapsed >= 7.5 and not collapse_sounded:
		collapse_sounded = true
		get_node("/root/SoundFX").play_sound("collapse", -18)
		# Set Me Free starts on the collapse: the game ends on a triumphant note.
		get_node("/root/MusicDirector").play_outro()
	queue_redraw()
	if elapsed >= 14:
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
	queue_free()

const C = preload("res://scripts/cinema.gd")
var frame_count := 0

## Ending (14 s, same beats as before so hooks and tests hold):
##   0.0-1.2  Miro steps out of the tree line; slow dolly with parallax pines, moonlight
##   1.2-2.6  the remote fills the screen: SIGNAL SENT
##   2.5-5.0  wide: the tower over the woods, sigils ignite floor by floor from the bottom
##   5.0-7.5  the PA line (MISSING/HUNTED), windows flicker
##   7.5-11   collapse: floors drop, dust, shake; Set Me Free starts
##   11-14    Miro in the foreground lowers his head; last thought; title; fade
func _draw() -> void:
	frame_count += 1
	var scale_factor := size / C.FRAME
	var t := elapsed
	var shake := Vector2.ZERO
	if t >= 7.5 and t < 10.5:
		var strength := 4.0 * (1.0 - C.phase(t, 7.5, 3.0))
		shake = Vector2(sin(t * 61.0), cos(t * 47.0)) * strength
	draw_set_transform(shake * scale_factor, 0, scale_factor)
	var branch: Dictionary = get_node("/root/Campaign").branch()[get_node("/root/Campaign").reputation()]
	if t < 2.5:
		shot_tree_line(t)
	else:
		shot_tower(t)
	draw_set_transform(Vector2.ZERO, 0, scale_factor)
	C.vignette(self, 0.8)
	C.grain(self, frame_count, 0.045)
	C.letterbox(self, C.phase(t, 0.0, 0.8))
	var subtitle := ""
	if t < 1.2:
		subtitle = "The woods. Air that nobody rationed."
	elif t >= 2.6 and t < 5.0:
		subtitle = "Five marks. Five floors."
	elif t >= 5.0 and t < 7.5:
		subtitle = "TOWER PA:  \"%s\"" % branch.ending_pa
	elif t >= 11.0:
		subtitle = "\"%s\"" % branch.ending_thought
	C.subtitle(self, subtitle, 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(16, 352), "[Tab] Skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(C.ROSE.r, C.ROSE.g, C.ROSE.b, 0.7))
	# The remote is the detonator: it fills the screen as the signal goes out.
	if t >= 1.2 and t < 2.6:
		var punch := C.ease_out(C.phase(t, 1.2, 0.25))
		C.fade(self, 0.7 * punch)
		var rect := Rect2(250, 40, 140, 200)
		rect = rect.grow(-20 * (1.0 - punch))
		preload("res://scripts/remote_screen.gd").draw_remote(self, rect, "SIGNAL SENT", absf(sin(t * 9)))
		if t > 2.35:
			C.fade(self, (t - 2.35) / 0.25, Color.WHITE)
	if t >= 12.0:
		C.title(self, Vector2(320, 175), "LAST MAN STANDING", 20, Color(C.PAPER.r, C.PAPER.g, C.PAPER.b, C.phase(t, 12.0, 0.8)), 6)
		C.fade(self, C.phase(t, 12.6, 1.4))
	if level.paused:
		C.fade(self, 0.6)
		draw_string(ThemeDB.fallback_font, Vector2(180, 180), "PAUSED — [Esc] Resume", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, C.PAPER)

## Miro walks out of the trees toward camera-right; the camera dollies with him.
func shot_tree_line(t: float) -> void:
	C.night_sky(self, Color("0f1224"), Color("2b2f4f"), Vector2(500, 70))
	var dolly := t * 22.0
	C.pines(self, 250, 120, 70, 0.0, -dolly * 0.3)
	C.pines(self, 285, 150, 90, 0.5, -dolly * 0.6)
	draw_rect(Rect2(0, 285, 640, 75), Color("0d1118"))
	# Moonlight on the ground where he steps out.
	for ring in range(5):
		draw_circle(Vector2(300, 300), 90.0 - ring * 15, Color(0.85, 0.85, 1.0, 0.025))
	C.miro(self, Vector2(250 + t * 30, 300), 1.6)
	C.pines(self, 380, 300, 160, 1.0, -dolly * 1.4)

## The tower over the woods: sigils, PA, collapse, and Miro watching in the foreground.
func shot_tower(t: float) -> void:
	var sky_warm := C.phase(t, 7.5, 4.0)
	C.night_sky(self, Color("0f1224").lerp(Color("2a1d33"), sky_warm), Color("2b2f4f").lerp(Color("6b4a5c"), sky_warm), Vector2(130, 60))
	# Slow push in on the tower during the ignition, then hold for the collapse.
	var push := 1.0 + 0.12 * C.ease_in_out(C.phase(t, 2.5, 5.0))
	var base := Vector2(400, 250)
	var unit := size / C.FRAME
	draw_set_transform(base * (1.0 - push) * unit, 0, unit * push)
	C.pines(self, 245, 70, 46, 0.1, 0)
	var ignite := 5.0 * C.phase(t, 2.6, 2.6)
	var collapse := C.ease_in_out(C.phase(t, 7.5, 3.2))
	C.tower(self, base, 28, 70, t, ignite, collapse, 1.0 if t < 5.0 else 0.6 + 0.4 * absf(sin(t * 7)))
	C.dust(self, base, C.phase(t, 7.6, 3.5))
	C.pines(self, 270, 90, 60, 0.6, 12)
	draw_set_transform(Vector2.ZERO, 0, size / C.FRAME)
	draw_rect(Rect2(0, 300, 640, 60), Color("0d1118"))
	# Foreground: Miro, the last man standing, watching it fall; he bows his head at 11 s.
	C.pines(self, 330, 260, 140, 1.0, 40)
	draw_rect(Rect2(90, 300, 160, 60), Color("0d1118"))
	C.miro(self, Vector2(170, 312), 2.4, C.ease_in_out(C.phase(t, 11.0, 1.0)))
