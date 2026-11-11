extends "res://tools/test_intro.gd"
class SavedCampaign:
	extends "res://scripts/campaign.gd"
	var forced_difficulty := "medium"
	func difficulty() -> String:
		return forced_difficulty
	func can_persist() -> bool:
		return true
	func progress_path() -> String:
		return "res://tmp/launch-checklist.cfg"

func press(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await frames(2)
	event = InputEventJoypadButton.new()
	event.button_index = button
	Input.parse_input_event(event)
	await frames(2)
func load_floor(number: int) -> void:
	if is_instance_valid(level):
		level.queue_free()
		await frames(3)
	level = load("res://scenes/intro.tscn" if number == 1 else "res://scenes/levels/level_%02d.tscn" % number).instantiate()
	root.add_child(level)
	current_scene = level
	await frames(8)
	level.finish_dialogue()
	for guard in level.guards():
		guard.set_physics_process(false)
	level.player.health = 100
func type_on_pad(text: String) -> void:
	var keyboard = root.get_node("ControllerSettings").keyboard
	for character in text:
		var found := false
		for button in keyboard.letter_buttons:
			if button.get_meta("character") == character:
				button.pressed.emit()
				found = true
				break
		if not found:
			keyboard.append(character)
	await press(JOY_BUTTON_START)
	await frames(3)
func run() -> void:
	var campaign = root.get_node("Campaign")
	var settings = root.get_node("ControllerSettings")
	var music = root.get_node("MusicDirector")
	print("CONTROLLER_HARDWARE: ", settings.device_status())
	# Disk persistence is exercised against a temporary file, never the player's profile.
	var path := "res://tmp/launch-checklist.cfg"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var saved := SavedCampaign.new()
	root.add_child(saved)
	saved.on_keeper_killed("Judas", true)
	saved.on_keeper_strangled("Judas", true)
	saved.unlock_achievement("art_A01")
	saved.add_track_unlock("foreva,spanish_guitarhall")
	for number in range(1, 6):
		saved.complete_floor(number, true, {"BrotherEncounter": true, "ForestViewpoint": true} if number == 5 else {}, {"kills": 0, "detections": 0})
	for id in ["ghost_1", "ghost_2", "ghost_3", "ghost_4", "ghost_full"]:
		check(saved.has_achievement(id), "Peaceful completion awards " + id)
	saved.free()
	var reloaded := SavedCampaign.new()
	root.add_child(reloaded)
	check(reloaded.has_achievement("art_A01") and reloaded.has_achievement("ghost_full"), "Gallery discovery and achievements persist after relaunch")
	check(reloaded.kill_count == 1 and reloaded.strangle_count == 1 and reloaded.named_killed.has("Judas"), "Cumulative achievement counters persist after relaunch")
	check(reloaded.unlocked_tracks().has("foreva") and reloaded.unlocked_tracks().has("spanish_guitarhall") and reloaded.unlocked_tracks().has("dancehall_lonesome"), "Secret and earned music remains on MP3 after relaunch")
	reloaded.free()
	DirAccess.remove_absolute(path)
	var super_run := SavedCampaign.new()
	root.add_child(super_run)
	super_run.forced_difficulty = "super_hard"
	for number in range(1, 6):
		super_run.enter_floor(number)
		super_run.complete_floor(number, true, {"BrotherEncounter": true, "ForestViewpoint": true} if number == 5 else {}, {"kills": 0})
	check(super_run.has_achievement("complete_super_hard") and super_run.unlocked_tracks().has("robot_attack"), "A complete five-floor Super Hard run grants Robot Attack")
	super_run.free()
	DirAccess.remove_absolute(path)
	var mixed_run := SavedCampaign.new()
	root.add_child(mixed_run)
	for number in range(1, 6):
		mixed_run.forced_difficulty = "medium" if number == 3 else "super_hard"
		mixed_run.enter_floor(number)
		mixed_run.forced_difficulty = "super_hard"
		mixed_run.complete_floor(number, true, {"BrotherEncounter": true, "ForestViewpoint": true} if number == 5 else {}, {"kills": 0})
	check(not mixed_run.has_achievement("complete_super_hard") and not mixed_run.unlocked_tracks().has("robot_attack"), "Switching difficulty after a Medium floor cannot grant Robot Attack")
	mixed_run.free()
	DirAccess.remove_absolute(path)
	var legacy := ConfigFile.new()
	legacy.set_value("levels", "highest", 3)
	legacy.save(path)
	var migrated := SavedCampaign.new()
	root.add_child(migrated)
	await frames(3)
	for number in range(1, 4):
		for track in migrated.level_music_tracks(number):
			check(migrated.unlocked_tracks().has(track), "Existing saves receive reached-floor music: " + str(track))
	check(not migrated.unlocked_tracks().has("plane_drums"), "Legacy save migration does not unlock an unreached floor")
	migrated.free()
	DirAccess.remove_absolute(path)
	for number in range(1, 6):
		await load_floor(number)
		var player = level.player
		var controls = player.controls
		var expected_tracks: Array = campaign.level_music_tracks(number)
		check(expected_tracks.size() == (1 if number in [1, 5] else 2), "Floor %d has the correct basic music reward count" % number)
		for track in expected_tracks:
			check(campaign.unlocked_tracks().has(track), "Reaching floor %d unlocks %s on the MP3" % [number, track])
		player.has_supplies = true
		player.position = Vector2(400 if number == 5 else 100, 236)
		player.guns.assign(["pistol", "smg"])
		player.has_gun = true
		controls.has_remote = true
		controls.remote_unlocked = true
		controls.sync_slots()
		for binding in [["pad_use", JOY_AXIS_TRIGGER_RIGHT], ["pad_focus", JOY_AXIS_TRIGGER_LEFT], ["move_right", JOY_AXIS_LEFT_X], ["climb_down", JOY_AXIS_LEFT_Y]]:
			var bound := false
			for event in InputMap.action_get_events(binding[0]):
				if event is InputEventJoypadMotion and event.axis == binding[1]:
					bound = true
			check(bound, "Floor %d: controller axis assigned for %s" % [number, binding[0]])
		await frames(4)
		level.finish_dialogue()
		# Exercise jumping at a clear floor point, away from relocated paintings and other interactions.
		if number != 5:
			var free_spot := false
			for x in [400.0, 600.0, 800.0, 100.0]:
				player.position = Vector2(x, 236)
				var lore = level.get_node("InnerConflict").usable_prop()
				if lore == null and not "[E]" in level.context_hint() and level.has_floor_below(player.position + Vector2(0, 12)):
					free_spot = true
					break
			check(free_spot, "Floor %d: controller movement fixture is clear of interactions" % number)
			player.velocity = Vector2.ZERO
			await frames(4)
		await press(JOY_BUTTON_A)
		check(player.velocity.y < 0, "Floor %d: Cross/A jumps away from interactions" % number)
		await press(JOY_BUTTON_B)
		check(player.dodge_left > 0, "Floor %d: Circle/B dashes" % number)
		await press(JOY_BUTTON_LEFT_STICK)
		check(player.pad_crouch, "Floor %d: L3 toggles crouch" % number)
		await press(JOY_BUTTON_LEFT_STICK)
		if number == 5:
			controls.has_guitar = true
		controls.sync_slots()
		controls.select_item("c4")
		await press(JOY_BUTTON_Y)
		check(controls.active == ("guitar" if number == 5 else "pistol"), "Floor %d: Triangle/Y cycles available weapons" % number)
		var selected: String = controls.active
		controls.melee_left=0
		await press(JOY_BUTTON_RIGHT_SHOULDER)
		check(controls.melee_left > 0 and controls.active == selected, "Floor %d: R1/RB performs melee without switching" % number)
		await press(JOY_BUTTON_LEFT_SHOULDER)
		check(controls.active == selected, "Floor %d: L1/LB blanket preserves selected weapon" % number)
		await press(JOY_BUTTON_TOUCHPAD)
		check(controls.inventory_open, "Floor %d: Touchpad opens inventory" % number)
		check(not "[Esc]" in controls.panel.get_child(0).get_children().back().text, "Floor %d: Inventory close prompt follows controller mode" % number)
		await press(JOY_BUTTON_B)
		check(not controls.inventory_open, "Floor %d: Circle/B closes inventory" % number)
		controls.show_console(false)
		await frames(2)
		await press(JOY_BUTTON_A)
		check(settings.keyboard.body.visible, "Floor %d: Cross/A opens terminal keys" % number)
		await type_on_pad("ls")
		check("readme.txt" in controls.output.text and not settings.keyboard.body.visible, "Floor %d: Controller keys submit the actual command" % number)
		check(controls.console_icon.texture != null, "Floor %d: Console retains its icon" % number)
		await press(JOY_BUTTON_B)
		check(not controls.remote_open, "Floor %d: Circle/B closes the console" % number)
		await press(JOY_BUTTON_START)
		check(level.paused and level.pause_menu.shade.visible, "Floor %d: Options/Menu opens pause" % number)
		check(not "[Esc]" in level.pause_menu.menu.get_node("Resume").text, "Floor %d: Pause names the controller button" % number)
		await press(JOY_BUTTON_A)
		check(not level.paused and not paused, "Floor %d: Cross/A resumes from pause" % number)
	# Every runtime track is exercised through the in-game MP3 cycle.
	var controls = level.player.controls
	campaign.session_unlocks = music.catalog.keys()
	controls.has_remote = true
	controls.remote_unlocked = true
	music.review_override = false
	for track in campaign.session_unlocks:
		check(music.catalog[track].title == str(music.catalog[track].source).get_basename(), "Beat label is exact source filename without extension: " + str(track))
		controls.next_beat()
		check(music.track_id == track and music.voices[music.active].stream != null and music.voices[music.active].stream.get_length() > 0, "MP3 decodes and selects: " + str(track))
	controls.next_beat()
	check(not music.review_override, "MP3 returns to the floor soundtrack after all tracks")
	# Inspect the in-world painting, then open that exact work from the gallery.
	await load_floor(1)
	var director = level.get_node("InnerConflict")
	director.assign_frame(true)
	director.open_prop(director.frame)
	var work_id: String = director.frame.art_id
	await frames(3)
	check(campaign.has_achievement("art_" + work_id) and director.viewer.visible, "In-world inspection grants the painting and shows its close-up")
	level.queue_free()
	await frames(3)
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.show_screen("beats")
	await frames(5)
	var beats = menu.page.find_child("Beats", true, false)
	var thumb = beats.find_child("Artwork_" + work_id, true, false)
	check(thumb != null, "The inspected painting appears as a gallery button")
	thumb.pressed.emit()
	await frames(3)
	var viewer = root.get_node("GalleryArtworkViewer")
	check(viewer.art_id == work_id and viewer.picture.texture != null, "Gallery opens the original painting at full resolution")
	await press(JOY_BUTTON_B)
	check(not is_instance_valid(root.get_node_or_null("GalleryArtworkViewer")), "Circle/B closes gallery close-up")
	# Static menu hints also update when the last input device changes.
	settings.using_controller = false
	check("[Esc]" in menu.page.find_child("Back", true, false).text, "Keyboard restores keyboard Back prompt")
	settings.using_controller = true
	check(not "[Esc]" in menu.page.find_child("Back", true, false).text, "Controller restores controller Back prompt")
	check("[L1] replace" in settings.controller_text("[Z] replace / [X] replace / [Esc] cancel", true), "Weapon replacement hint matches L1/R1 bindings")
	for ps in [true, false]:
		var text: String = settings.controller_text("[Q, left click] [C] Dodge Space Jump [N / Esc] [T]", ps)
		check(not "[Q" in text and not "[C]" in text and not "Space" in text and not "Esc" in text, "All compound tool prompts translate for " + ("PlayStation" if ps else "Xbox"))
	menu.queue_free()
	await frames(3)
	# Actual MP3 security hack: browsing the terminal must not grant the hack reward.
	await load_floor(2)
	controls = level.player.controls
	campaign.achievements_earned.erase("mp3_hack")
	campaign.mp3_hack_unlocked = false
	controls.has_remote = true
	controls.remote_unlocked = true
	level.player.global_position = level.world_features.access_point
	controls.show_console(false, true)
	controls.run_command("ls")
	check(not campaign.has_achievement("mp3_hack"), "Reading files is not counted as an MP3 security hack")
	controls.run_command("login root")
	controls.run_command("cameras off")
	check(campaign.has_achievement("mp3_hack") and campaign.unlocked_tracks().has("house_cyah_skate"), "Successful MP3 camera hack grants its achievement and beat")
	controls.close_panels()
	# A real password field can be completed with the controller keyboard.
	await load_floor(3)
	level.world_features.open_terminal()
	await press(JOY_BUTTON_A)
	check(settings.keyboard.body.visible, "Controller can enter a checkpoint password")
	await type_on_pad("root")
	check(level.world_features.terminal_authenticated, "Controller password submission authenticates the checkpoint")
	# Terminal keys disappear safely when their owning floor is replaced.
	level.player.controls.show_console(true)
	settings.keyboard.open(level.player.controls.command)
	level.queue_free()
	await frames(4)
	check(not settings.keyboard.body.visible, "Controller keys close safely when a level is removed")
	var credits: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	var roles := {}
	for block in credits.blocks:
		roles[block.heading] = block.lines
	check(roles.get("Lead Software Engineer") == ["Ethan Risden"] and roles.get("Level Design") == ["Ethan Risden"], "Engineering and Level Design name Ethan Risden")
	check(roles.get("Creative Director") == ["Ethan Risden"] and roles.get("Creative Lead") == ["Julia S."], "Creative roles retain requested names")
	check(not roles.has("Music composition, production, mixing and mastering") and roles.has("Music composed and produced by RXLA"), "RXLA tracklist credit appears once without a duplicate music block")
	check(roles.has("Loop credits") and roles.get("Playtesting") == ["Francesca Dumary"], "Loop maker and playtesting attributions remain")
	print("LAUNCH_CHECKLIST_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
