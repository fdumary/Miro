extends Control
## Screen-space text anchored to a world-space speaker; never intercepts gameplay input.
var actor: Node2D
var thought := false
## Forced dialogue: shows the speaker's name and the continue prompt inside the bubble.
var dialogue := false
var speaker := ""
var text_label: Label
var name_label: Label
var prompt_label: Label
var below := false
const SPEECH = preload("res://assets/library/speech.png")
const THOUGHT = preload("res://assets/library/thought.png")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(252, 88)
	text_label = Label.new()
	text_label.position = Vector2(12, 7)
	text_label.size = Vector2(228, 72)
	text_label.add_theme_font_size_override("font_size", 11)
	text_label.add_theme_color_override("font_color", Color("272744"))
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(text_label)
	name_label = Label.new()
	name_label.position = Vector2(12, 4)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color("8b6d9c"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(name_label)
	prompt_label = Label.new()
	prompt_label.text = "[E] Continue   [Tab] Skip"
	prompt_label.add_theme_font_size_override("font_size", 8)
	prompt_label.add_theme_color_override("font_color", Color("8b6d9c"))
	prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt_label)
	name_label.visible = false
	prompt_label.visible = false

func follow_actor() -> void:
	if not is_instance_valid(actor):
		visible = false
		return
	name_label.visible = dialogue
	prompt_label.visible = dialogue
	name_label.text = speaker
	var top := 18.0 if dialogue else 7.0
	var bottom := 20.0 if dialogue else 7.0
	text_label.position.y = top
	size.y = maxf(42, text_label.get_line_count() * text_label.get_line_height() + top + bottom)
	text_label.size.y = size.y - top - bottom
	prompt_label.position = Vector2(size.x - 118, size.y - 15)
	var point := actor.get_global_transform_with_canvas().origin
	var viewport := get_viewport_rect().size
	var top_limit := 52.0 if dialogue else 124.0
	var bottom_limit := viewport.y - 34.0
	var x := clampf(point.x - size.x / 2, 8, viewport.x - size.x - 8)
	var y := point.y - size.y - 40
	below = y < top_limit
	if below:
		# Not enough room above the speaker: hang the bubble under them instead.
		y = point.y + 22
	y = clampf(y, top_limit, bottom_limit - size.y)
	var miro_screen := point
	if Rect2(Vector2(x, y), size).grow(6).has_point(miro_screen):
		# Still overlapping (very tall bubble): slide sideways, away from the speaker.
		x = point.x + 26 if point.x < viewport.x / 2 else point.x - 26 - size.x
		x = clampf(x, 8, viewport.x - size.x - 8)
	position = Vector2(x, y)
	queue_redraw()

func _draw() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("fbf5ef")
	style.border_color = Color("8b6d9c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12 if thought else 5)
	draw_style_box(style, Rect2(Vector2.ZERO, size))
	var tail_x := size.x / 2
	if is_instance_valid(actor):
		tail_x = clampf(actor.get_global_transform_with_canvas().origin.x - position.x, 20, size.x - 20)
	# Reuse the licensed bubble assets as the speaker/thought tail badge.
	var tail_y := -22.0 if below else size.y - 2
	draw_texture_rect(THOUGHT if thought else SPEECH, Rect2(tail_x - 12, tail_y, 24, 24), false, Color("fbf5ef"), false)
