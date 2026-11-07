extends "res://tools/test_intro.gd"

func run() -> void:
	level = load("res://scenes/levels/level_05.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	level.finish_dialogue()
	level.player.position = Vector2(650, 432)
	level.interact()
	check(not is_instance_valid(level.brother), "Cannot start boss before final sigil and offer")
	level.milestones["FinalSigil"] = true
	level.milestones["FinalOffer"] = true
	level.interact()
	var boss = level.brother
	check(is_instance_valid(boss), "Encounter creates boss")
	boss.receive_shank()
	check(boss.health == 6, "Telegraph is guarded")
	level.player.has_gun = true
	level.player.ammunition = 2
	level.player.facing = 1
	level.player.fire_gun()
	check(boss.health == 6, "Gun cannot bypass guarded boss")
	level.paused = true
	var timer: float = boss.phase_left
	await frames(70)
	check(is_equal_approx(timer, boss.phase_left), "Pause freezes boss")
	level.paused = false
	await frames(68)
	check(boss.current_phase == boss.Phase.RUSH, "First telegraph produces rush")
	await frames(42)
	check(boss.is_vulnerable, "Rush ends in recovery")
	boss.receive_shank()
	check(boss.health == 5, "Recovery permits damage")
	boss.receive_shank()
	check(boss.health == 5, "Damage immunity prevents repeated same-frame hits")
	await frames(96)
	check(boss.attack_number == 1, "Second attack alternates to projectile")
	await frames(68)
	check(boss.projectile_live and boss.is_vulnerable, "Throw launches projectile then exposes recovery")
	# Finish through normal damage API; traversal suite separately wins with real inputs.
	boss.set_physics_process(false)
	for hit in range(5):
		boss.invulnerability_left = 0
		boss.receive_shank()
	check(boss.is_dead and level.milestones.has("BrotherEncounter"), "Defeat ends encounter once")
	check(level.dialogue_event == "milestone" and level.pending_milestone == "DefeatExchange", "Defeat starts non-fatal defeat exchange")
	level.finish_dialogue()
	check(level.milestones.has("DefeatExchange"), "Skip preserves defeat exchange completion")
	check(not boss.projectile_live, "Defeat clears projectile")
	print("BROTHER_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
