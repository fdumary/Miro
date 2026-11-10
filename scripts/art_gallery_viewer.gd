extends CanvasLayer
## Full-resolution view of an inspected gallery painting; usable while the game is paused.
var previous_focus: Control
var picture: TextureRect
var close_button: Button
var art_id := ""
func _ready() -> void:
	name = "GalleryArtworkViewer"
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
func open(work: Dictionary, texture: Texture2D) -> void:
	art_id = str(work.id)
	previous_focus = get_viewport().gui_get_focus_owner()
	var shade := ColorRect.new()
	shade.theme = preload("res://scripts/visual_assets.gd").ui_theme()
	shade.color = Color(0.025, 0.025, 0.045, 0.97)
	shade.size = Vector2(640, 360)
	add_child(shade)
	picture = TextureRect.new()
	picture.position = Vector2(20, 12)
	picture.size = Vector2(600, 278)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture = texture
	shade.add_child(picture)
	var caption := Label.new()
	caption.position = Vector2(20, 292)
	caption.size = Vector2(600, 30)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 11)
	caption.text = "%s — %s, %s" % [work.title, work.artist, work.year]
	shade.add_child(caption)
	close_button = Button.new()
	close_button.position = Vector2(245, 327)
	close_button.size = Vector2(150, 24)
	get_node("/root/ControllerSettings").bind_prompt(close_button, "Close artwork [Esc]")
	close_button.pressed.connect(close)
	shade.add_child(close_button)
	close_button.grab_focus()
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
func close() -> void:
	if is_instance_valid(previous_focus):
		previous_focus.grab_focus()
	queue_free()
