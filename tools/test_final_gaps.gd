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
	level = null
	print("FINAL_GAPS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
