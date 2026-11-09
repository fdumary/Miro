extends "res://tools/test_intro.gd"
## Last gaps: the guitar deflects shots, hunting Keepers climb after Miro, extra Keepers on 3-4.
func run() -> void:
	level = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	level.finish_dialogue()
	check(level.has_node("Guards/EntryClerk") and level.has_node("Guards/DeepKeeper"), "Level 3 has its extra Keepers")
	check(level.get_node("Guards/EntryClerk").guard_name == "Sable", "Extra Keeper is named and voiced")
	# Guitar deflection.
	for guard in level.guards():
		guard.set_physics_process(false)
		guard.position = Vector2(-500, -500)
	var player = level.player
	player.controls.has_guitar = true
	player.controls.select_item("guitar")
	player.position = Vector2(400, 236)
	var shooter = level.get_node("Guards/EntryClerk")
	shooter.position = Vector2(520, 236)
	var bullet := Node2D.new()
	bullet.set_script(load("res://scripts/weapon_projectile.gd"))
	bullet.level = level
	bullet.shooter = shooter
	bullet.enemy = true
	bullet.direction = Vector2(-1, 0)
	bullet.speed = 280.0
	bullet.remaining = 260.0
	bullet.position = Vector2(470, 232)
	level.add_child(bullet)
	var health_before: int = player.health
	await frames(40)
	check(player.health == health_before, "The guitar takes the hit without damage")
	check(not is_instance_valid(bullet) or not bullet.enemy, "The round is turned back")
	# Ladder following.
	var ladder = level.areas.get_node("FifthLadder")
	player.set_physics_process(false)
	player.global_position = ladder.global_position + Vector2(0, -60)
	player.climbing = true
	var climber = level.get_node("Guards/DeepKeeper")
	climber.set_physics_process(true)
	climber.global_position = ladder.global_position + Vector2(0, 70)
	climber.alert_state = IntroGuard.State.ALERT
	climber.pursuing = true
	var start_y: float = climber.global_position.y
	await frames(50)
	check(climber.global_position.y < start_y - 20.0, "A hunting Keeper climbs the ladder after Miro")
	player.climbing = false
	# A searching Keeper walks to the ladder and climbs down to where he last saw Miro.
	var searcher = level.get_node("Guards/VaultWestKeeper")
	searcher.set_physics_process(true)
	searcher.global_position = Vector2(1480, 1048)
	searcher.alert_state = IntroGuard.State.SEARCH
	searcher.pursuing = false
	searcher.search_left = 30.0
	searcher.last_known_position = Vector2(1500, 1244)
	var before_y: float = searcher.global_position.y
	searcher.set_physics_process(false)
	for step in range(300):
		searcher.ladder_search(1.0 / 60.0)
		await frames(1)
	check(searcher.global_position.y > before_y + 25.0 and absf(searcher.global_position.x - 1540.0) < 6.0, "A searching Keeper takes the ladder down to the floor he last saw Miro")
	# The checkpoint hack opens the gate even if another scene starts at the same moment.
	level.queue_free()
	await frames(2)
	level = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(10)
	level.finish_dialogue()
	for stray in level.guards():
		stray.set_physics_process(false)
	level.player.global_position = level.areas.get_node("RemoteTerminal").global_position + Vector2(0, 8)
	# Miro has already shot one of the linked watchers dead.
	for watcher in level.connected_cameras:
		if is_instance_valid(watcher):
			watcher.take_turret_hit(2)
			break
	level.world_features.open_terminal()
	level.world_features.submit_password("root")
	await frames(30)
	level.start_dialogue([["TOWER PA", "Something interrupts."]])
	await frames(20)
	level.finish_dialogue()
	await frames(90)
	check(level.milestones.has("RemoteTerminal") and level.get_node("Gates/CheckpointGate").is_open, "The hack opens the checkpoint gate even when another scene interrupts")
	level = null
	print("FINAL_GAPS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
