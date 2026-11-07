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

func _draw() -> void:
	var scale_factor := size / Vector2(640, 360)
	draw_set_transform(Vector2.ZERO, 0, scale_factor)
	draw_rect(Rect2(0, 0, 640, 360), Color("272744"))
	draw_circle(Vector2(450, 70), 26, Color("8b6d9c"))
	# Fixed storyboard tower pieces: scripted collapse, no structural simulation.
	var collapse := clampf((elapsed - 7.5) / 2.5, 0, 1)
	for tier in range(5):
		var y := 230.0 - tier * 29 + collapse * (tier * 23 + 16)
		var x := 390.0 + sin(tier * 3.1) * collapse * 26
		draw_rect(Rect2(x, y, 78, 28 * (1 - collapse) + 3), Color("494d7e"))
		if elapsed >= 2.5 + tier * 0.75 and collapse < 0.9:
			var center := Vector2(x + 39, y + 12)
			draw_polyline(PackedVector2Array([center + Vector2(-7, 6), center + Vector2(0, -9), center + Vector2(7, 6), center + Vector2(-7, 6)]), Color("f2d3ab"), 2)
			draw_line(center + Vector2(0, -12), center + Vector2(0, 13), Color("f2d3ab"), 2)
			if elapsed >= 6.5:
				draw_circle(center, 9, Color(0.95, 0.83, 0.67, 0.3))
	for x in [30, 95, 160, 540, 600]:
		draw_rect(Rect2(x, 100, 10, 190), Color("494d7e"))
		draw_colored_polygon(PackedVector2Array([Vector2(x - 40, 170), Vector2(x + 5, 50), Vector2(x + 50, 170)]), Color("494d7e"))
	draw_rect(Rect2(0, 280, 640, 80), Color("272744"))
	for x in [10, 60, 120, 510, 560, 610]:
		draw_texture_rect(preload("res://assets/library/grass.png"), Rect2(x - 24, 251, 48, 32), false, Color("494d7e"))
	# Miro looks toward the tower; the final pose lowers his head.
	draw_rect(Rect2(211, 241, 15, 37), Color("c69fa5"))
	var head := Vector2(221, 234) + (Vector2(4, 5) if elapsed >= 11 else Vector2.ZERO)
	draw_circle(head, 8, Color("f2d3ab"))
	draw_line(Vector2(218, 250), Vector2(237, 249), Color("c69fa5"), 5)
	draw_rect(Rect2(234, 244, 7, 8), Color("8b6d9c"))
	var subtitle := "Miro reaches the woods. He looks back."
	if elapsed >= 2.5:
		subtitle = "Five marks. Five charges on the tower's supports."
	if elapsed >= 7.5:
		subtitle = "The tower falls."
	if elapsed >= 11:
		subtitle = "Miro lowers his head."
	draw_string(ThemeDB.fallback_font, Vector2(45, 318), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("fbf5ef"))
	draw_string(ThemeDB.fallback_font, Vector2(45, 343), "[Tab] Skip    [Esc] Pause", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("c69fa5"))
	if elapsed >= 12:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, clampf((elapsed - 12) / 2, 0, 1)))
	if level.paused:
		draw_rect(Rect2(0, 0, 640, 360), Color(0, 0, 0, 0.6))
		draw_string(ThemeDB.fallback_font, Vector2(180, 180), "PAUSED — [Esc] Resume", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("fbf5ef"))
