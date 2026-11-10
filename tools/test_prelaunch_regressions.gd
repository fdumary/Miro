extends "res://tools/test_intro.gd"
## Release integration checks for the November 9 achievement and gallery changes.
func run() -> void:
	var campaign = root.get_node("Campaign")
	var music = root.get_node("MusicDirector")
	await fresh()
	level.finish_dialogue()
	for guard in level.guards():
		guard.set_physics_process(false)
	level.get_node("Guards/CorruptKeeper").take_damage(16, true)
	check(campaign.has_achievement("kill_1") and campaign.unlocked_tracks().has("drill2"), "Floor 1 kill immediately grants its achievement and beat")
	for i in range(9):
		campaign.on_keeper_killed("test_guard", false)
	check(campaign.has_achievement("kill_10") and campaign.unlocked_tracks().has("evilhall2"), "Ten kills on one floor grant Evilhall before descending")
	for i in range(101):
		campaign.on_keeper_killed("test_guard", true)
		campaign.on_keeper_strangled("test_guard", true)
	check(not campaign.has_achievement("kill_named") and not campaign.has_achievement("strangle_named"), "Repeated identities cannot complete the named roster")
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/guard_roster.json"))
	for guard_name in roster.keepers:
		campaign.on_keeper_killed(guard_name, true)
		campaign.on_keeper_strangled(guard_name, true)
	check(campaign.has_achievement("kill_named") and campaign.has_achievement("strangle_named"), "Every actual roster identity completes both named achievements")
	check(campaign.unlocked_tracks().has("driffannnn") and campaign.unlocked_tracks().has("b6"), "Strangle milestones retain their new music rewards")
	for command in ["ls", "cat notes.txt", "pwd", "whoami", "cd ..", "login root", "scan", "turrets off"]:
		campaign.on_terminal_command(command)
	check(campaign.has_achievement("terminal_all") and campaign.unlocked_tracks().has("space_dancehall_yf"), "Parameterized commands count toward all-command achievement")
	check(not campaign.terminal_commands_run.has("login root"), "Terminal tracking stores command identities without password arguments")
	var targets: Dictionary = campaign.security_targets()
	check(not targets.is_empty() and targets.size() < 100, "All-security target derives from the authored devices")
	var ids: Array = targets.keys()
	for i in range(ids.size() - 1):
		var parts: PackedStringArray = str(ids[i]).split(":")
		campaign.current_floor = int(parts[0])
		campaign.on_security_disabled(parts[1], Vector2(float(parts[2]), float(parts[3])))
	var count_before: int = campaign.security_disabled_count
	var first: PackedStringArray = str(ids[0]).split(":")
	campaign.current_floor = int(first[0])
	campaign.on_security_disabled(first[1], Vector2(float(first[2]), float(first[3])))
	check(campaign.security_disabled_count == count_before, "Repeated disables cannot inflate security progress")
	check(not campaign.has_achievement("hack_all"), "One remaining security device keeps all-security locked")
	var last: PackedStringArray = str(ids.back()).split(":")
	campaign.current_floor = int(last[0])
	campaign.on_security_disabled(last[1], Vector2(float(last[2]), float(last[3])))
	check(campaign.has_achievement("hack_all") and campaign.unlocked_tracks().has("ken_carson"), "Disabling every authored device grants Ken Carson")
	var watcher = load("res://scenes/security_camera.tscn").instantiate()
	watcher.level = level
	level.add_child(watcher)
	watcher.set_physics_process(false)
	watcher.take_turret_hit(16)
	check(campaign.has_achievement("destroy_mosswatcher") and campaign.unlocked_tracks().has("relapse_3"), "C4 overkill on an actual mosswatcher grants its reward")
	watcher.queue_free()
	var turret := Area2D.new()
	turret.set_script(load("res://scripts/tower_hazard.gd"))
	turret.level = level
	turret.kind = "turret"
	level.add_child(turret)
	turret.set_physics_process(false)
	turret.take_turret_hit(16)
	check(campaign.has_achievement("destroy_turret") and campaign.unlocked_tracks().has("qwella1"), "C4 overkill on a turret grants its reward")
	turret.queue_free()
	level.queue_free()
	await frames(2)
	campaign.session_unlocks = []
	campaign.achievements_earned.clear()
	campaign.unlock_achievement("art_A01")
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(4)
	check(music.voices[music.active].stream != null and (DisplayServer.get_name() == "headless" or music.voices[music.active].playing), "Start menu loads music and plays it when audio is enabled")
	menu.show_screen("beats")
	await frames(6)
	var beats = menu.page.find_child("Beats", true, false)
	var scroll = beats.find_child("BeatsScroll", true, false)
	check(scroll != null and scroll.get_global_rect().end.x <= 640 and scroll.get_global_rect().end.y < 320, "Beats list stays within the game viewport and above Back")
	var entries: Dictionary = {}
	for button in beats.find_children("Beat_*", "Button", true, false):
		check(not entries.has(str(button.name)), "Beat appears once: " + str(button.name))
		entries[str(button.name)] = true
	check(entries.size() >= 25, "Expanded achievement music catalog remains visible")
	check(beats.find_child("Beat_reaper", true, false).disabled, "Reaper starts locked")
	check("evilhall2" in beats.find_child("Beat_evilhall2", true, false).text, "Beat labels preserve source filenames")
	scroll.scroll_vertical = 10000
	await frames(3)
	check(scroll.scroll_vertical > 0, "All beat rows can be reached by scrolling")
	var art = beats.find_child("ArtPanel", true, false)
	for button in beats.find_children("*", "Button", true, false):
		if button.text == "ARTWORK":
			button.pressed.emit()
	await frames(4)
	check(art.visible and not beats.find_child("BeatsPanel", true, false).visible, "Artwork tab switches panels")
	check(art.get_global_rect().end.x <= 640 and art.get_global_rect().end.y < 320, "Artwork panel fits the game viewport")
	var art_grid = art.get_child(0)
	var shown := 0
	for cell in art_grid.get_children():
		for child in cell.get_children():
			if child is TextureButton:
				shown += 1
				print("THUMB_DEBUG ", child.texture_normal.resource_path)
	check(shown == 1, "Only the inspected artwork exposes a thumbnail")
	campaign.add_track_unlock("hot_shit")
	check(campaign.unlocked_tracks().has("hot_shit") and music.SECOND[5] == "hot_shit", "Earned Hot Shit stays unlocked and Level 5 keeps its combat cue")
	var credits: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	var headings: Array = []
	for block in credits.blocks:
		headings.append(block.heading)
	var icon_index: int = headings.find("App icon artwork")
	check(icon_index == headings.find("Character sprites, animations and tile art") + 1 and credits.blocks[icon_index].lines == ["Lindsey-Anne Rattray"], "Icon credit appears directly after character art")
	print("PRELAUNCH_REGRESSIONS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
