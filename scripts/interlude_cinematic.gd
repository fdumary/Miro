extends Control
## Between-floor cinematics (C6-C9). About 12 s; Tab/Enter/Space/Esc skips with the same result.
##   0-4    the tower at night, one more sigil lit, Miro's silhouette in the rain
##   4-8.5  the remote glows; the voice speaks (subtitled; Niro's name only after Level 3)
##   8.5-12 Miro's thought, then the next floor's title
signal finished
const C = preload("res://scripts/cinema.gd")
const LENGTH := 12.0
const BASE := Vector2(410, 262)
## Keyed by the floor just finished.
const SCENES := {
	1: {"title": "LEVEL 2", "speaker": "THE VOICE", "voice": "You have the remote. Keep it close, and keep quiet.", "thought": "Someone is guiding me down. I should find out why."},
	2: {"title": "LEVEL 3", "speaker": "THE VOICE", "voice": "If you go any lower, I can't protect you.", "thought": "From who?"},
	3: {"title": "LEVEL 4", "speaker": "NIRO", "voice": "Now you know my name. Please, stop at the records.", "thought": "Brother. The word feels true, and I hate that."},
	4: {"title": "LEVEL 5", "speaker": "NIRO", "voice": "Don't come down here, Miro. Please.", "thought": "The seals, the supports. Everything rests on the floor below."},
}
var floor_done := 1
var elapsed := 0.0
var done := false
var audio: Node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	audio = preload("res://scripts/cine_audio.gd").new()
	add_child(audio)
	audio.loop("wind_loop", -20.0, 1.0)
	audio.at(1.0, func(): get_node("/root/SoundFX").play_sound("sigil", -10, 1.0 + floor_done * 0.1))

func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	audio.tick(elapsed)
	queue_redraw()
	if elapsed >= LENGTH:
		finish()

func _input(event: InputEvent) -> void:
	if not done and (event.is_action_pressed("skip") or event.is_action_pressed("advance") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if done:
		return
	done = true
	finished.emit()
	queue_free()

func _draw() -> void:
	var unit := size / C.FRAME
	draw_set_transform(Vector2.ZERO, 0.0, unit)
	var data: Dictionary = SCENES.get(floor_done, SCENES[1])
	var t := elapsed
	C.night_sky(self, Color("090b1a"), Color("1d2140"))
	C.pines(self, 300.0, 60.0, 26.0, 0.5, t * 2.0)
	C.tower(self, BASE, 40.0, 70.0, t, float(floor_done) / 5.0)
	C.pines(self, 340.0, 90.0, 34.0, 1.0, t * 4.0)
	C.rain(self, t, 0.25)
	C.miro(self, Vector2(150, 330), 2.2)
	if t >= 3.5 and t < 9.0:
		# The remote's glow washes the foreground while the voice speaks.
		var glow := C.phase(t, 3.5, 0.8) * (1.0 - C.phase(t, 8.3, 0.7))
		draw_circle(Vector2(170, 300), 70.0, Color(0.55, 0.85, 0.7, 0.12 * glow))
		draw_rect(Rect2(160, 292, 20, 28), Color(0.6, 0.95, 0.8, 0.5 * glow))
		C.subtitle(self, "%s:  \"%s\"" % [data.speaker, data.voice], glow)
	elif t >= 9.0:
		C.subtitle(self, data.thought, C.phase(t, 9.0, 0.8))
		C.title(self, Vector2(320, 150), data.title, 28, Color("e6d9c3"), 6.0, true)
	C.letterbox(self, 1.0)
	C.vignette(self, 0.6)
	C.grain(self, int(t * 24.0), 0.05)
	C.fade(self, 1.0 - C.phase(t, 0.0, 0.8) + C.phase(t, LENGTH - 0.8, 0.8))
