extends Control
## RXLA logo, then the silent tower's MP3 player with an unresolved burst of radio static.
signal finished
const LOGO := preload("res://assets/branding/rxla_logo.png")
const PLAYER := preload("res://assets/weapons/remote.svg")
const STATIC := preload("res://assets/audio/cine/end_radio_static.wav")
const LOGO_LENGTH := 3.0
const STATIC_LENGTH := 6.0
var clock := 0.0
var stage := "logo"
var static_player: AudioStreamPlayer
var finished_once := false
func _ready() -> void:
	name = "PostCredits"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	static_player = AudioStreamPlayer.new()
	static_player.stream = STATIC
	static_player.bus = "Effects"
	static_player.volume_db = -5.0
	add_child(static_player)
func start_static() -> void:
	if stage == "static":
		return
	stage = "static"
	clock = 0.0
	if DisplayServer.get_name() != "headless":
		static_player.play()
	queue_redraw()
func _process(delta: float) -> void:
	clock += delta
	if stage == "logo" and clock >= LOGO_LENGTH:
		start_static()
	elif stage == "static" and clock >= STATIC_LENGTH:
		finish()
	queue_redraw()
func _input(event: InputEvent) -> void:
	var pad: bool = event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_B, JOY_BUTTON_START]
	var key: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_TAB, KEY_ESCAPE, KEY_ENTER, KEY_SPACE]
	if pad or key:
		get_viewport().set_input_as_handled()
		if stage == "logo":
			start_static()
		else:
			finish()
func finish() -> void:
	if finished_once:
		return
	finished_once = true
	static_player.stop()
	finished.emit()
func _draw() -> void:
	var unit := size / Vector2(640, 360)
	draw_set_transform(Vector2.ZERO, 0, unit)
	draw_rect(Rect2(0, 0, 640, 360), Color.BLACK)
	if stage == "logo":
		var alpha := minf(1.0, clock / 0.25)
		draw_texture_rect(LOGO, Rect2(155, 15, 330, 330), false, Color(1, 1, 1, alpha))
	else:
		var tremor := Vector2(0.5 if fmod(clock, 1.37) < 0.045 else 0.0, 0)
		draw_texture_rect(PLAYER, Rect2(Vector2(242, 102) + tremor, Vector2(156, 156)), false)
func _exit_tree() -> void:
	if is_instance_valid(static_player):
		static_player.stop()
		static_player.stream = null
