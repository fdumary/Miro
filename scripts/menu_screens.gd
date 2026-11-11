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
	parent.get_node("/root/ControllerSettings").bind_prompt(label, text)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

static func button(parent: Node, text: String, action: Callable, size := 12) -> Button:
	var item := Button.new()
	parent.get_node("/root/ControllerSettings").bind_prompt(item, text)
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
	var footer := note(root, "Dev build: every floor is open." if progress.dev_mode() else "Replays start the floor over with your previous floor's equipment.", 10)
	footer.position = Vector2(0, 282)
	footer.size = Vector2(640, 16)
	var new_game := button(root, "New Playthrough", func():
		progress.start_new_playthrough()
		pick.call(1))
	new_game.name = "NewPlaythrough"
	new_game.position = Vector2(230,306)
	new_game.size = Vector2(180,28)
	new_game.tooltip_text = "Start from Level 1. Resets this run's checkpoints and story; keeps achievements, music, artwork and settings."
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
static func settings(parent: Node, rect: Rect2, in_run := false, open_controller := Callable(), open_display := Callable()) -> VBoxContainer:
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
	for id in ["easy", "medium", "hard", "super_hard"]:
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
	var volume_sliders: Dictionary = {}
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
		volume_sliders[bus] = slider
		var director = music(parent)
		slider.value_changed.connect(func(value): director.set_volume(bus, value))
	var mix_button := button(box, "Music-forward mix", func():
		music(parent).apply_balanced_mix()
		for bus in volume_sliders: volume_sliders[bus].set_value_no_signal(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))))
	mix_button.name = "MusicForwardMix"
	mix_button.tooltip_text = "Music -4 dB · Effects -1 dB · Voice -2 dB. Speech ducking remains active."
	note(box, "M mutes all audio. Music lowers during speech; overheard lines have subtitles.", 9)
	if open_controller.is_valid():
		var controllers := button(box, "Controls and controller settings", open_controller)
		controllers.name = "ControllerSettingsButton"
		controllers.call_deferred("grab_focus")
	if open_display.is_valid():
		button(box, "Display and frame rate", open_display).name = "DisplaySettingsButton"
	return box

static func display_settings(parent: Node, rect: Rect2) -> VBoxContainer:
	var outer := column(parent, rect, 3)
	outer.name = "DisplaySettings"
	heading(outer, "DISPLAY", 16)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.custom_minimum_size.y = rect.size.y - 65
	outer.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	var display = parent.get_node("/root/DisplaySettings")
	var selectors: Dictionary = {}
	var controls := [
		["window_mode", "Window", ["Windowed", "Borderless Fullscreen", "Fullscreen"], [0, 1, 2]],
		["frame_cap", "FPS limit", ["Match display", "Display minus 3 (VRR)", "30", "60", "120", "144", "165", "180", "240", "360", "Unlimited"], display.CAPS],
		["vsync", "V-Sync", ["Off", "On", "Adaptive"], [0, 1, 2]],
	]
	for spec in controls:
		var row := HBoxContainer.new()
		box.add_child(row)
		var label := Label.new()
		label.text = spec[1]
		label.custom_minimum_size.x = 75
		row.add_child(label)
		var choice := OptionButton.new()
		choice.name = str(spec[0])
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.add_theme_font_size_override("font_size", 12)
		for index in range(spec[2].size()): choice.add_item(str(spec[2][index]), int(spec[3][index]) + 2)
		choice.select(spec[3].find(display.preferences[spec[0]]))
		row.add_child(choice)
		selectors[spec[0]] = choice
		var key: String = spec[0]
		choice.item_selected.connect(func(index): display.set_preference(key, choice.get_item_id(index) - 2))
	var presets := HBoxContainer.new()
	box.add_child(presets)
	for vrr in [false, true]:
		var preset := button(presets, "VRR / low latency" if vrr else "Smooth / tear-free", func():
			display.set_preset(vrr)
			for key in selectors:
				var selector: OptionButton = selectors[key]
				selector.select(selector.get_item_index(int(display.preferences[key]) + 2)))
		preset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var counter := CheckButton.new()
	counter.name = "ShowFPS"
	counter.text = "Show FPS"
	counter.button_pressed = display.preferences.show_fps == 1
	counter.toggled.connect(func(pressed): display.set_preference("show_fps", int(pressed)))
	box.add_child(counter)
	var refresh_label := note(box, "Current display: %d Hz. FPS limits do not change your monitor refresh rate." % roundi(display.refresh_rate()), 10)
	note(box, "G-SYNC / FreeSync: enable VRR on your monitor and in the graphics driver. Display minus 3 keeps the FPS cap below refresh.", 10)
	note(box, "V-Sync On can limit FPS to display refresh. VRR preset requires driver / monitor VRR. Adaptive support varies.", 10)
	var update_controls := func():
		for key in selectors:
			var selector: OptionButton = selectors[key]
			selector.select(selector.get_item_index(int(display.preferences[key]) + 2))
		counter.set_pressed_no_signal(display.preferences.show_fps == 1)
		refresh_label.text = "Current display: %d Hz. FPS limits do not change your monitor refresh rate." % roundi(display.refresh_rate())
	display.changed.connect(update_controls)
	outer.tree_exiting.connect(func():
		if display.changed.is_connected(update_controls): display.changed.disconnect(update_controls))
	return outer

static func controller_settings(parent: Node, rect: Rect2, back: Callable) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", VISUALS.panel_style())
	parent.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	box.name = "ControllerSettings"
	box.set_script(load("res://scripts/controller_settings_panel.gd"))
	box.setup(back)
	var bindings := button(box, "Reassign keyboard / mouse · Controller presets", func(): parent.get_node("/root/InputBindings").open())
	bindings.name = "ReassignBindings"
	box.move_child(bindings,1)
	return box

static func describe(tuning: Dictionary) -> String:
	var waves := "fewer Keepers per wave" if int(tuning.wave_extra) < 0 else ("an extra armed Keeper per wave" if int(tuning.wave_extra) > 0 else "waves as built")
	return "%d hearts · blanket recharges in %ds · %s" % [int(tuning.health), int(tuning.stealth_cooldown), waves]

# --- Beats tracker --------------------------------------------------------------------------

## Every beat the MP3 can hold: unlocked ones play on click, locked ones are greyed out with
## what earns them. Calm beats come from staying unseen, aggressive ones from Keepers taken down.
## Also includes an Artwork tab showing reactive paintings Miro has seen.
static func beats(parent: Node, rect: Rect2) -> VBoxContainer:
	var box := column(parent, rect, 3)
	box.name = "Beats"
	var progress = campaign(parent)
	var director = music(parent)

	# Build the full entry list: threshold beats + achievement beats + completion beats.
	var unlocked: Array = progress.unlocked_tracks()
	var threshold_entries: Array = progress.branch().get("mp3_unlocks", []).duplicate()

	# Achievement entries: load achievements.json and collect tracks not already in threshold list.
	var achievement_data: Array = []
	var achievements_raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/achievements.json"))
	if achievements_raw is Dictionary:
		achievement_data = achievements_raw.get("achievements", [])
	var threshold_tracks: Array = []
	for e in threshold_entries:
		threshold_tracks.append(e.track)
	var achievement_entries: Array = []
	for ach in achievement_data:
		var t: String = str(ach.get("track", ""))
		if t.is_empty() or not director.catalog.has(t):
			continue
		if threshold_tracks.has(t):
			continue  # Already shown via threshold list; skip duplicate
		achievement_entries.append({"track": t, "achievement_id": str(ach.id), "mood": "achievement"})

	var level_entries: Array = []
	for number in range(1, 6):
		for track in progress.level_music_tracks(number):
			level_entries.append({"track": track, "reach_floor": number})
	# Completion and secret tracks.
	var completion_entries: Array = [
		{"track": director.MENU_TRACK, "starting_theme": true, "requirement": "Starting menu theme"},
		{"track": director.MENU_COMPLETED_TRACK, "completion": true, "mood": "menu"},
		{"track": "hot_shit", "niro_completion": true, "mood": "combat"},
		{"track": "set_me_free", "forest_completion": true, "mood": "outro"},
		{"track": "foreva", "achievement_id": "foreva_peaceful", "requirement": "Find the Foreva note without killing a guard in this run"},
	]

	var all_entries: Array = threshold_entries.duplicate()
	all_entries.append_array(level_entries)
	all_entries.append_array(achievement_entries)
	all_entries.append_array(completion_entries)
	var unique_entries: Array = []
	var listed_tracks: Dictionary = {}
	for entry in all_entries:
		if not listed_tracks.has(entry.track):
			listed_tracks[entry.track] = true
			unique_entries.append(entry)
	all_entries = unique_entries
	# Preserve the original 41-track display order; append the new reward last.
	var display_order: Array = ["birthday_melody", "destroyed_lonely", "pinkghost", "dancehall64", "jazzyhall", "new_age_dancehall", "dancehall_lonesome", "dancehall", "drill2", "drill_shxt", "reaper", "ox", "yz33", "dope2", "swag", "bobblehead", "cyberpunk", "plane_drums", "sumcrazy", "hot_shit", "evilhall2", "driffannnn", "fell_from_heaven", "b6", "ready_3_go3", "project_dancehall_hard_af_2", "project_14", "ken_carson", "egyptian_beat_2", "space_dancehall_yf", "house_cyah_skate", "skillibeng_type_beat", "qwella1", "relapse_3", "spanish_guitarhall", "robot_attack", "trapdoor_bonus", "foreva", "shit_crashed", "lil_uzi2", "set_me_free", "all_achievements"]
	all_entries.sort_custom(func(a,b): return display_order.find(a.track) < display_order.find(b.track))

	var owned := 0
	for entry in all_entries:
		if beat_owned(progress, unlocked, entry):
			owned += 1

	# Two-tab layout: Beats / Artwork
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 4)
	box.add_child(tab_row)

	var tab_beats := Button.new()
	tab_beats.text = "BEATS %d / %d" % [owned, all_entries.size()]
	tab_beats.toggle_mode = true
	tab_beats.set_pressed_no_signal(true)
	tab_beats.add_theme_font_size_override("font_size", 11)
	tab_row.add_child(tab_beats)

	var tab_art := Button.new()
	tab_art.text = "ARTWORK"
	tab_art.toggle_mode = true
	tab_art.set_pressed_no_signal(false)
	tab_art.add_theme_font_size_override("font_size", 11)
	tab_row.add_child(tab_art)

	# Beats panel
	var beats_panel := VBoxContainer.new()
	beats_panel.name = "BeatsPanel"
	beats_panel.add_theme_constant_override("separation", 2)
	box.add_child(beats_panel)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 2)
	var beats_scroll := ScrollContainer.new()
	beats_scroll.name = "BeatsScroll"
	beats_scroll.custom_minimum_size = Vector2(0, 160)
	beats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	beats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	beats_panel.add_child(beats_scroll)
	beats_scroll.add_child(grid)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for entry in all_entries:
		var track: String = entry.track
		if not director.catalog.has(track):
			continue
		var have := beat_owned(progress, unlocked, entry)
		var item := Button.new()
		item.name = "Beat_" + track
		item.custom_minimum_size = Vector2(250, 18)
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.clip_text = true
		item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item.add_theme_font_size_override("font_size", 10)
		var display_name: String = str(director.catalog.get(track, {}).get("source", track)).get_basename()
		item.tooltip_text = display_name + " · " + requirement(entry, achievement_data)
		if have:
			item.text = "%s   · %s" % [display_name, requirement(entry, achievement_data)]
			item.add_theme_color_override("font_color", SAND)
			item.pressed.connect(func():
				director.review_override = true
				director.play_track(track))
		else:
			item.text = "LOCKED  %s   · %s" % [display_name, requirement(entry, achievement_data)]
			item.disabled = true
			item.modulate = Color(1, 1, 1, 0.45)
		grid.add_child(item)

	for achievement in achievement_data:
		if not str(achievement.get("track", "")).is_empty():continue
		var row := Label.new()
		row.name = "Achievement_" + str(achievement.id)
		row.text = ("UNLOCKED · " if progress.has_achievement(str(achievement.id)) else "LOCKED · ") + str(achievement.label)
		row.add_theme_font_size_override("font_size", 10)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.custom_minimum_size.x = 250
		grid.add_child(row)

	# Keep the completion reward last, including after non-musical achievements.
	var final_beat := grid.get_node_or_null("Beat_all_achievements")
	if final_beat != null:
		grid.remove_child(final_beat)
		if grid.get_child_count() % 2 != 0: grid.add_child(Control.new())
		grid.add_child(final_beat)

	note(beats_panel, "MP3: [V] previous · [B] next · [H] shuffle. Checkpoint music takes priority.", 9)

	# Artwork panel (hidden by default)
	var art_panel := ScrollContainer.new()
	art_panel.name = "ArtPanel"
	art_panel.visible = false
	art_panel.custom_minimum_size = Vector2(0, 160)
	art_panel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(art_panel)

	var art_grid := GridContainer.new()
	art_grid.columns = 3
	art_grid.add_theme_constant_override("h_separation", 6)
	art_grid.add_theme_constant_override("v_separation", 4)
	art_panel.add_child(art_grid)

	var art_rights_raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_rights.json"))
	var art_rights: Dictionary = art_rights_raw.get("works", {}) if art_rights_raw is Dictionary else {}
	var art_catalog_raw = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_catalog.json"))
	var art_works: Array = art_catalog_raw.get("works", []) if art_catalog_raw is Dictionary else []

	for work in art_works:
		var work_id: String = str(work.id)
		var seen: bool = progress.has_achievement("art_" + work_id)
		var cell := VBoxContainer.new()
		cell.custom_minimum_size = Vector2(178, 80)
		cell.add_theme_constant_override("separation", 2)
		art_grid.add_child(cell)

		var rights_entry: Dictionary = art_rights.get(work_id, {})
		var rights_ok: bool = rights_entry.get("status", "") == "verified"
		var asset_path: String = str(work.get("asset_path", ""))
		var can_show: bool = seen and rights_ok and not asset_path.is_empty() and ResourceLoader.exists(asset_path)

		if can_show:
			var thumb := TextureButton.new()
			thumb.name = "Artwork_" + work_id
			thumb.custom_minimum_size = Vector2(178, 60)
			thumb.ignore_texture_size = true
			thumb.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
			thumb.texture_normal = load(asset_path)
			thumb.tooltip_text = "Inspect " + str(work.title)
			thumb.pressed.connect(open_artwork.bind(parent, work, thumb.texture_normal))
			cell.add_child(thumb)
		else:
			var placeholder := ColorRect.new()
			placeholder.custom_minimum_size = Vector2(178, 60)
			placeholder.color = Color(0.18, 0.17, 0.26)
			cell.add_child(placeholder)

		var caption := Label.new()
		caption.text = ("%s — %s" % [str(work.get("title", "")), str(work.get("artist", ""))]) if seen else "??? — ???"
		caption.add_theme_font_size_override("font_size", 9)
		caption.add_theme_color_override("font_color", SAND if seen else DIM)
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.custom_minimum_size = Vector2(178, 0)
		cell.add_child(caption)

	# Tab switching
	tab_beats.pressed.connect(func():
		tab_beats.set_pressed_no_signal(true)
		tab_art.set_pressed_no_signal(false)
		beats_panel.visible = true
		art_panel.visible = false)
	tab_art.pressed.connect(func():
		tab_art.set_pressed_no_signal(true)
		tab_beats.set_pressed_no_signal(false)
		beats_panel.visible = false
		art_panel.visible = true)

	return box

static func open_artwork(parent: Node, work: Dictionary, texture: Texture2D) -> void:
	var viewer = preload("res://scripts/art_gallery_viewer.gd").new()
	parent.get_tree().root.add_child(viewer)
	viewer.open(work, texture)

static func beat_owned(progress: Node, unlocked: Array, entry: Dictionary) -> bool:
	if entry.get("starting_theme",false): return true
	if entry.get("completion", false):
		return progress.game_completed()
	if entry.get("niro_completion", false):
		return progress.has_achievement("defeat_niro")
	if entry.get("forest_completion", false):
		return unlocked.has("set_me_free")
	if entry.has("achievement_id"):
		return unlocked.has(entry.track)
	return unlocked.has(entry.track)

static func mood_word(entry: Dictionary) -> String:
	if entry.has("reach_floor"):
		return "level %d" % int(entry.reach_floor)
	if entry.get("mood", "") == "bonus":
		return "completion bonus"
	if entry.get("completion", false):
		return "menu theme"
	if entry.get("niro_completion", false):
		return "combat"
	if entry.get("forest_completion", false):
		return "outro"
	if entry.has("achievement_id"):
		return "achievement"
	return "stealth" if entry.has("stealth_points") else "combat"

static func requirement(entry: Dictionary, achievement_data: Array = []) -> String:
	if entry.has("reach_floor"):
		return "Reach Level %d" % int(entry.reach_floor)
	if entry.has("requirement"):
		return entry.requirement
	if entry.get("completion", false):
		return "finish the game"
	if entry.get("niro_completion", false):
		return "Defeat Niro & Blow Up Tower"
	if entry.get("forest_completion", false):
		return "reach the forest viewpoint"
	# Check achievement_data for a matching track label
	var track: String = str(entry.get("track", ""))
	for ach in achievement_data:
		if str(ach.get("track", "")) == track:
			return str(ach.get("label", track))
	if entry.has("kills"):
		return "take down %d Keepers" % int(entry.kills)
	if entry.has("stealth_points"):
		return "%d stealth points" % int(entry.stealth_points)
	return track
