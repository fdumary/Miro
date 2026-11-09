extends RefCounted
## Screens shared by the start menu and the pause menu: level select, settings (difficulty and
## volume) and the MP3 beats tracker. Everything is built from code in a 640x360 frame.
const VISUALS = preload("res://scripts/visual_assets.gd")
const TITLES := ["THE PRISONER", "THE BARRACKS", "THE WATCH", "THE WARD", "THE FOUNDATION"]
const INK := Color("1b1b30")
const SAND := Color("f2d3ab")
const ROSE := Color("c69fa5")
const DIM := Color(0.55, 0.53, 0.6)

static func campaign(node: Node) -> Node:
	return node.get_node("/root/Campaign")

static func music(node: Node) -> Node:
	return node.get_node("/root/MusicDirector")

static func heading(parent: Node, text: String, size := 18) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", SAND)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label

static func note(parent: Node, text: String, size := 10, color := DIM) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

static func button(parent: Node, text: String, action: Callable, size := 12) -> Button:
	var item := Button.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.pressed.connect(action)
	parent.add_child(item)
	return item

## A centred column inside a panel; returns the column to fill.
static func column(parent: Node, rect: Rect2, separation := 6) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", VISUALS.panel_style())
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	panel.add_child(box)
	return box

# --- Level select ---------------------------------------------------------------------------

## Five floor cards. Reached floors can be launched; completed ones carry a check, locked ones
## a padlock and no button. `pick` receives the floor number.
static func level_select(parent: Node, pick: Callable) -> Control:
	var root := Control.new()
	root.name = "LevelSelect"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(root)
	var title := heading(root, "CHOOSE A FLOOR", 18)
	title.position = Vector2(0, 30)
	title.size = Vector2(640, 26)
	var row := HBoxContainer.new()
	row.position = Vector2(30, 80)
	row.size = Vector2(580, 190)
	row.add_theme_constant_override("separation", 10)
	root.add_child(row)
	var progress = campaign(parent)
	for number in range(1, 6):
		var card := LevelCard.new()
		card.number = number
		card.title = TITLES[number - 1]
		card.unlocked = progress.level_unlocked(number)
		card.completed = progress.level_completed(number)
		card.custom_minimum_size = Vector2(108, 190)
		card.pressed.connect(func():
			if card.unlocked:
				pick.call(number))
		row.add_child(card)
	var footer := note(root, "Dev build: every floor is open." if progress.dev_mode() else "Finish a floor to open the next one.", 10)
	footer.position = Vector2(0, 282)
	footer.size = Vector2(640, 16)
	return root

class LevelCard extends Button:
	var number := 1
	var title := ""
	var unlocked := false
	var completed := false

	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE
		disabled = not unlocked
		tooltip_text = title if unlocked else "Locked"
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW

	func _draw() -> void:
		var area := Rect2(Vector2.ZERO, size)
		var hover := is_hovered() or has_focus()
		draw_rect(area, Color("2b2a45") if unlocked else Color("1d1c2c"))
		draw_rect(area, SAND if hover and unlocked else Color(0.4, 0.38, 0.5), false, 2.0 if hover and unlocked else 1.0)
		var font := ThemeDB.fallback_font
		var ink := SAND if unlocked else DIM
		draw_string(font, Vector2(0, 46), "%02d" % number, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, ink)
		draw_multiline_string(font, Vector2(6, 132), title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 12, 11, 2, ink)
		var badge := Vector2(size.x / 2, 90)
		if not unlocked:
			# Padlock: shackle arc over a body with a keyhole.
			draw_arc(badge + Vector2(0, -6), 9, PI, TAU, 16, DIM, 3.0)
			draw_rect(Rect2(badge + Vector2(-13, -6), Vector2(26, 20)), DIM)
			draw_circle(badge + Vector2(0, 2), 3, Color("1d1c2c"))
			draw_rect(Rect2(badge + Vector2(-1, 2), Vector2(2, 7)), Color("1d1c2c"))
			draw_string(font, Vector2(0, 176), "LOCKED", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, DIM)
		elif completed:
			draw_circle(badge, 15, Color(0.36, 0.62, 0.42))
			draw_polyline(PackedVector2Array([badge + Vector2(-7, 0), badge + Vector2(-2, 6), badge + Vector2(8, -6)]), Color.WHITE, 3.0)
			draw_string(font, Vector2(0, 176), "CLEARED", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, Color(0.6, 0.85, 0.65))
		else:
			draw_arc(badge, 15, 0, TAU, 24, ROSE, 2.0)
			draw_colored_polygon(PackedVector2Array([badge + Vector2(-5, -8), badge + Vector2(9, 0), badge + Vector2(-5, 8)]), ROSE)
			draw_string(font, Vector2(0, 176), "PLAY", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, ROSE)

	func _process(_delta: float) -> void:
		queue_redraw()

# --- Settings -------------------------------------------------------------------------------

## Difficulty buttons and the three volume sliders. `in_run` adds a note that difficulty takes
## effect from the next floor or restart.
static func settings(parent: Node, rect: Rect2, in_run := false, open_controller := Callable()) -> VBoxContainer:
	var box := column(parent, rect, 5)
	box.name = "Settings"
	heading(box, "SETTINGS", 16)
	var progress = campaign(parent)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	var label := Label.new()
	label.text = "Difficulty"
	label.custom_minimum_size.x = 70
	row.add_child(label)
	var detail := note(box, "", 10)
	var choices: Array[Button] = []
	for id in ["easy", "medium", "hard"]:
		var choice := Button.new()
		choice.name = "Difficulty_" + id
		choice.text = progress.DIFFICULTIES[id].label
		choice.toggle_mode = true
		choice.custom_minimum_size.x = 70
		choice.add_theme_font_size_override("font_size", 12)
		row.add_child(choice)
		choices.append(choice)
	var refresh := func():
		var current: String = progress.difficulty()
		for choice in choices:
			choice.set_pressed_no_signal(choice.name == "Difficulty_" + current)
		detail.text = describe(progress.DIFFICULTIES[current]) + ("\nApplies from the next floor or a restart." if in_run else "")
	for choice in choices:
		var id: String = choice.name.trim_prefix("Difficulty_")
		choice.pressed.connect(func():
			progress.set_difficulty(id)
			refresh.call())
	refresh.call()
	for bus in ["Music", "Effects", "Voice"]:
		var line := HBoxContainer.new()
		box.add_child(line)
		var name_label := Label.new()
		name_label.text = bus
		name_label.custom_minimum_size.x = 70
		line.add_child(name_label)
		var slider := HSlider.new()
		slider.name = bus + "Volume"
		slider.min_value = -40
		slider.max_value = 0
		slider.step = 1
		slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.custom_minimum_size.x = 180
		line.add_child(slider)
		var director = music(parent)
		slider.value_changed.connect(func(value): director.set_volume(bus, value))
	note(box, "M mutes all audio. Music lowers during speech; overheard lines have subtitles.", 9)
	if open_controller.is_valid():
		var controllers := button(box, "Controller settings", open_controller)
		controllers.name = "ControllerSettingsButton"
		controllers.call_deferred("grab_focus")
	return box

static func controller_settings(parent: Node, rect: Rect2, back: Callable) -> VBoxContainer:
	var box := column(parent, rect, 3)
	box.name = "ControllerSettings"
	box.set_script(load("res://scripts/controller_settings_panel.gd"))
	box.setup(back)
	return box

static func describe(tuning: Dictionary) -> String:
	var waves := "fewer Keepers per wave" if int(tuning.wave_extra) < 0 else ("an extra armed Keeper per wave" if int(tuning.wave_extra) > 0 else "waves as built")
	return "%d hearts · blanket recharges in %ds · %s" % [int(tuning.health), int(tuning.stealth_cooldown), waves]

# --- Beats tracker --------------------------------------------------------------------------

static func achievements(parent: Node, rect: Rect2) -> TabContainer:
	var tabs := TabContainer.new()
	tabs.name = "Achievements"
	tabs.position = rect.position
	tabs.size = rect.size
	parent.add_child(tabs)
	var beats_tab := Control.new()
	beats_tab.name = "Beats"
	tabs.add_child(beats_tab)
	beats(beats_tab, Rect2(0, 0, rect.size.x, rect.size.y - 20))
	var art_tab := ScrollContainer.new()
	art_tab.name = "Artwork"
	tabs.add_child(art_tab)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	art_tab.add_child(grid)
	var progress = campaign(parent)
	var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_catalog.json"))
	for work in Array(catalog.get("works", []) if catalog is Dictionary else []):
		var item := VBoxContainer.new()
		item.custom_minimum_size = Vector2(170, 110)
		var id := str(work.get("id", ""))
		var viewed: bool = progress.has_viewed_art(id)
		var image := TextureRect.new()
		image.custom_minimum_size = Vector2(160, 78)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if viewed:
			image.texture = load(str(work.get("asset_path", "")))
		else:
			image.modulate = Color(0.25, 0.25, 0.25)
		item.add_child(image)
		var label := Label.new()
		label.text = str(work.get("title", "???")) if viewed else "???"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", SAND if viewed else DIM)
		item.add_child(label)
		grid.add_child(item)
	return tabs

## Every beat the MP3 can hold: unlocked ones play on click, locked ones are greyed out with
## what earns them. Calm beats come from staying unseen, aggressive ones from Keepers taken down.
static func beats(parent: Node, rect: Rect2) -> VBoxContainer:
	var box := column(parent, rect, 3)
	box.name = "Beats"
	var progress = campaign(parent)
	var director = music(parent)
	var unlocked: Array = progress.unlocked_tracks()
	var entries: Array = progress.branch().get("mp3_unlocks", []).duplicate()
	entries.append({"track": director.MENU_COMPLETED_TRACK, "completion": true, "mood": "menu"})
	var owned := 0
	for entry in entries:
		if beat_owned(progress, unlocked, entry):
			owned += 1
	heading(box, "MP3 · BEATS %d / %d" % [owned, entries.size()], 15)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 2)
	box.add_child(grid)
	for entry in entries:
		var track: String = entry.track
		var have := beat_owned(progress, unlocked, entry)
		var item := Button.new()
		item.name = "Beat_" + track
		item.custom_minimum_size = Vector2(250, 18)
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.add_theme_font_size_override("font_size", 10)
		var title: String = director.catalog.get(track, {}).get("title", track)
		if have:
			item.text = "%s   · %s" % [title, mood_word(entry)]
			item.add_theme_color_override("font_color", SAND)
			item.pressed.connect(func():
				director.review_override = true
				director.play_track(track))
		else:
			item.text = "LOCKED  %s   · %s" % [title, requirement(entry)]
			item.disabled = true
			item.modulate = Color(1, 1, 1, 0.45)
		grid.add_child(item)
	note(box, "On a floor, [B] skips to the next beat on Miro's MP3 (or type next on the remote).", 9)
	return box

static func beat_owned(progress: Node, unlocked: Array, entry: Dictionary) -> bool:
	if entry.get("completion", false):
		return progress.game_completed()
	return unlocked.has(entry.track)

static func mood_word(entry: Dictionary) -> String:
	if entry.get("completion", false):
		return "menu theme"
	return "stealth" if entry.has("stealth_points") else "combat"

static func requirement(entry: Dictionary) -> String:
	if entry.get("completion", false):
		return "finish the game"
	if entry.has("kills"):
		return "take down %d Keepers" % int(entry.kills)
	return "%d stealth points" % int(entry.stealth_points)
