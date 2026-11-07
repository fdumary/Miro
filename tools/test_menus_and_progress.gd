extends "res://tools/test_intro.gd"
## Start menu, level select, pause menu, difficulty, MP3 beats (unlocks and [B] next) and the
## Keeper roster (Judas, personalities, the off-duty huddle). Run with -- --player so level
## select shows the player view (editor and QA builds open every floor).

func load_level(path: String) -> void:
	if is_instance_valid(level):
		level.queue_free()
		await frames(2)
	level = load(path).instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	level.finish_dialogue()

func run() -> void:
	var campaign = root.get_node("Campaign")
	var music = root.get_node("MusicDirector")
	check(not campaign.dev_mode(), "--player shows the player's level select")
	check(campaign.difficulty() == "medium", "Tests default to Medium")

	# Level progress: reached floors open, the rest locked; clearing a floor opens the next.
	campaign.session_level = 1
	check(campaign.level_unlocked(1) and not campaign.level_unlocked(2), "A new player starts with only Level 1 open")
	campaign.complete_floor(1, true, {}, {"kills": 0, "detections": 0})
	check(campaign.level_unlocked(2) and not campaign.level_unlocked(3), "Clearing Level 1 opens Level 2 only")
	check(campaign.level_completed(1) and not campaign.level_completed(2), "Level 1 shows a check, Level 2 doesn't")

	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await frames(3)
	check(menu.get_child(0).name == "Backdrop", "Start screen keeps a Backdrop first child")
	check(music.track_id == music.MENU_TRACK or music.track_id == music.MENU_COMPLETED_TRACK, "Start screen plays Drill Shxt (LIL UZI2 after completion)")
	check(menu.screen == "title" and menu.page.find_child("Play", true, false) != null, "Title screen opens with Play")
	menu.page.find_child("Play", true, false).pressed.emit()
	await frames(2)
	check(menu.screen == "levels", "Play opens level select")
	var cards: Array = menu.page.find_child("LevelSelect", true, false).get_child(1).get_children()
	check(cards.size() == 5, "Level select shows five floors")
	check(not cards[0].disabled and not cards[1].disabled and cards[2].disabled and cards[4].disabled, "Floors 3-5 are locked, 1-2 open")
	check(cards[0].completed and not cards[1].completed, "Cleared floor carries a check")
	menu.show_screen("beats")
	await frames(2)
	var beats: Node = menu.page.find_child("Beats", true, false)
	var locked := beats.find_child("Beat_reaper", true, false)
	check(locked != null and locked.disabled, "Locked beats are greyed out on the tracker")
	menu.show_screen("settings")
	await frames(2)
	menu.page.find_child("Difficulty_hard", true, false).pressed.emit()
	check(campaign.difficulty() == "hard", "Settings switch difficulty")
	menu.queue_free()
	await frames(2)

	# Difficulty: Hard means fewer hearts, longer blanket recharge, sharper Keepers.
	await load_level("res://scenes/levels/level_02.tscn")
	check(level.player.health == 2 and level.player.stealth_cooldown == 11.0, "Hard: 2 hearts and an 11 s blanket recharge")
	var keeper = level.guards()[0]
	check(keeper.sight > 165.0 and keeper.attack_gap < 2.1, "Hard: Keepers see further and shoot sooner")
	campaign.set_difficulty("easy")
	await load_level("res://scenes/levels/level_02.tscn")
	check(level.player.health == 5 and level.player.stealth_cooldown == 5.0, "Easy: 5 hearts and a 5 s blanket recharge")
	campaign.set_difficulty("medium")

	# Pause menu.
	level.paused = true
	paused = true
	await frames(2)
	check(level.pause_menu.shade.visible and not level.overlay.visible, "Esc opens the pause menu")
	level.pause_menu.resume_game()
	await frames(2)
	check(not level.paused and not paused and not level.pause_menu.shade.visible, "Resume closes it")

	# Keepers: unique names, personalities, the huddle over John 3:16.
	var names := {}
	for guard in level.guards():
		check(not names.has(guard.guard_name), "Unique Keeper name " + guard.guard_name)
		names[guard.guard_name] = true
		check(guard.personality in ["serious", "goofy", "stern", "funny", "stupid"], "%s has a personality (%s)" % [guard.guard_name, guard.personality])
	var huddle: Array = level.guards().filter(func(guard): return guard.distracted)
	check(huddle.size() == 3, "Three off-duty Keepers huddle on Level 2")
	level.player.position = huddle[0].position + Vector2(-200, 0)
	var heard := false
	for tick in range(240):
		await frames(1)
		if "John 3:16" in level.world_features.subtitle.text or "For God so loved" in level.world_features.subtitle.text:
			heard = true
			break
	check(heard, "One of them reads John 3:16")
	check(huddle.all(func(guard): return guard.alert_state == IntroGuard.State.PATROL), "Absorbed huddle doesn't notice Miro from a distance")

	# Beats: calm for stealth, aggressive for kills; [B] steps through them on the MP3.
	campaign.floor_stats.clear()
	campaign.session_unlocks = []
	campaign.floor_stats[2] = campaign.score_floor({"kills": 3, "detections": 1})
	campaign.floor_stats[3] = campaign.score_floor({"kills": 0, "detections": 0, "stealth_bonus": 1})
	var earned: Array = campaign.update_unlocks()
	check(earned.has("drill2") and earned.has("drill_shxt") and not earned.has("reaper"), "3 kills unlock Drill 2 and Drill Shxt, not Reaper")
	check(earned.has("birthday_melody") and earned.has("destroyed_lonely") and not earned.has("pinkghost"), "3 stealth points unlock the first calm beats")
	level.player.controls.has_remote = true
	level.player.controls.remote_unlocked = true
	var floor_track: String = music.track_id
	level.player.controls.next_beat()
	check(music.track_id == campaign.unlocked_tracks()[0], "[B] plays the first unlocked beat")
	for step in range(campaign.unlocked_tracks().size()):
		level.player.controls.next_beat()
	check(music.track_id == floor_track and not music.review_override, "[B] past the last beat returns to the floor's music")
	check(music.SECOND[5] == "hot_shit", "Hot Shit plays in the final level's second half")

	# Judas.
	await load_level("res://scenes/intro.tscn")
	check(level.get_node("Guards/CorruptKeeper").guard_name == "Judas", "The first Keeper is Judas")

	# Crates: stand on top, or hide inside with E.
	await frames(6)
	var crates: Array = level.world_features.props.filter(func(prop): return prop.kind == "crate")
	check(crates.size() == 3, "Level 1 has three crates")
	level.door_open = true
	level.player.position = crates[0].position + Vector2(0, -30)
	await frames(30)
	check(level.player.is_on_floor() and level.player.position.y < crates[0].position.y - 10, "Miro can stand on a crate")
	level.player.position = crates[1].position + Vector2(-20, 0)
	await frames(30)
	level.interact()
	await frames(2)
	check(level.player.in_hiding_spot, "Miro can hide inside a crate [E]")
	print("MENUS_PROGRESS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
