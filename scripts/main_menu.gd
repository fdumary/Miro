extends Control
## Start screen. Title → Play opens level select (players see only floors they have reached;
## dev builds see all five), plus the MP3 beats tracker and settings (difficulty, volume).
## The first child, "Backdrop", is the full-screen picture behind every screen.
const SCREENS = preload("res://scripts/menu_screens.gd")
var music: Node
var screen := ""
var page: Control

func _ready() -> void:
	theme = preload("res://scripts/visual_assets.gd").ui_theme()
	music = get_node("/root/MusicDirector")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			var number := clampi(argument.trim_prefix("--level=").to_int(), 1, 5)
			get_node("/root/Campaign").launch_consumed = true
			# Go directly to the requested scene; avoid nested scene changes from intro._ready().
			get_tree().call_deferred("change_scene_to_file", "res://scenes/intro.tscn" if number == 1 else "res://scenes/levels/level_%02d.tscn" % number)
			return
	if "--verify-playthrough" in OS.get_cmdline_user_args():
		get_tree().call_deferred("change_scene_to_file", "res://scenes/intro.tscn")
		return
	music.review_override = false
	# After a finished Play run the menu switches to the completed-game track.
	music.play_track(music.MENU_COMPLETED_TRACK if get_node("/root/Campaign").game_completed() else music.MENU_TRACK)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color("272744")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var campaign = get_node("/root/Campaign")
	var first: String = "levels" if "--level-select" in OS.get_cmdline_user_args() else "title"
	if not campaign.menu_screen.is_empty():
		first = campaign.menu_screen
		campaign.menu_screen = ""
	show_screen(first)

func show_screen(id: String) -> void:
	screen = id
	if is_instance_valid(page):
		page.queue_free()
	page = Control.new()
	page.name = "Screen_" + id
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	match id:
		"title":
			build_title()
		"levels":
			SCREENS.level_select(page, launch_level)
			back_button()
		"settings":
			SCREENS.settings(page, Rect2(130, 70, 380, 180))
			back_button()
		"beats":
			SCREENS.beats(page, Rect2(40, 30, 560, 210))
			if get_node("/root/Campaign").dev_mode():
				review_picker()
			back_button()

func build_title() -> void:
	var title := Label.new()
	title.text = "MIRO"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", SCREENS.SAND)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 58)
	title.size = Vector2(640, 54)
	page.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "LAST MAN STANDING"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", SCREENS.ROSE)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(0, 112)
	subtitle.size = Vector2(640, 20)
	page.add_child(subtitle)
	var box := VBoxContainer.new()
	box.position = Vector2(250, 156)
	box.size = Vector2(140, 150)
	box.add_theme_constant_override("separation", 6)
	page.add_child(box)
	var play := SCREENS.button(box, "Play", func(): show_screen("levels"), 14)
	play.name = "Play"
	SCREENS.button(box, "Beats", func(): show_screen("beats"), 14).name = "BeatsButton"
	SCREENS.button(box, "Settings", func(): show_screen("settings"), 14).name = "SettingsButton"
	SCREENS.button(box, "Quit", func(): get_tree().quit(), 14)
	play.call_deferred("grab_focus")
	var caption := Label.new()
	caption.text = "M mutes all audio · F10 returns here from a floor" + (" · dev build" if get_node("/root/Campaign").dev_mode() else "")
	caption.add_theme_font_size_override("font_size", 9)
	caption.add_theme_color_override("font_color", SCREENS.DIM)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.position = Vector2(0, 336)
	caption.size = Vector2(640, 14)
	page.add_child(caption)

func back_button() -> void:
	var back := Button.new()
	back.name = "Back"
	back.text = "Back  [Esc]"
	back.add_theme_font_size_override("font_size", 11)
	back.position = Vector2(14, 326)
	back.pressed.connect(func(): show_screen("title"))
	page.add_child(back)

## Dev only: audition any track in the catalog, locked or not.
func review_picker() -> void:
	var tracks := OptionButton.new()
	tracks.position = Vector2(420, 326)
	tracks.add_theme_font_size_override("font_size", 10)
	tracks.add_item("Dev: soundtrack review")
	var ids: Array = music.catalog.keys()
	for id in ids:
		tracks.add_item(music.catalog[id].title)
	tracks.item_selected.connect(func(index):
		if index > 0:
			music.review_override = true
			music.play_track(ids[index - 1]))
	page.add_child(tracks)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_ESCAPE and screen != "title":
		show_screen("title")
		get_viewport().set_input_as_handled()

func launch_level(number: int) -> void:
	var campaign = get_node("/root/Campaign")
	if not campaign.level_unlocked(number):
		return
	campaign.case_anchors.clear()
	campaign.completed_sigils.clear()
	campaign.narrative_milestones.clear()
	campaign.launch_consumed = true
	# A new run from the cell opens on the cinematic, which hands over to Level 1.
	get_tree().change_scene_to_file("res://scenes/opening_cinematic.tscn" if number == 1 else "res://scenes/levels/level_%02d.tscn" % number)
