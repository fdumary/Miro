extends "res://tools/test_intro.gd"

func run() -> void:
	for number in [3, 4]:
		if is_instance_valid(level):
			level.queue_free()
			await frames(2)
		level = load("res://scenes/levels/level_%02d.tscn" % number).instantiate()
		root.add_child(level)
		current_scene = level
		await frames(3)
		level.finish_dialogue()
		for guard in level.guards():
			guard.set_physics_process(false)
		var gate = level.get_node("Gates").get_child(0)
		check(not gate.is_open and not level.clear_sight(Vector2(480, 100), Vector2(550, 100)), "Floor %d seal physically blocks passage" % number)
		if number == 4:
			level.player.position = Vector2(430, 232)
			level.interact()
			check(level.dialogue.is_empty() and not gate.is_open, "Ward release requires the records")
		level.player.position = Vector2(300, 232)
		level.interact()
		if number == 3:
			level.world_features.submit_password("root")
			await frames(65)
		level.finish_dialogue()
		if number == 4:
			level.player.position = Vector2(430, 232)
			level.interact()
			level.finish_dialogue()
		await frames(2)
		check(gate.is_open and level.clear_sight(Vector2(480, 100), Vector2(550, 100)), "Floor %d release clears collision" % number)
		level.player.position = Vector2(490, 150)
		check(await move_to(550, 300, false), "Player crosses opened seal")
	# Later-floor loot uses the same limited ammunition/noise rules as the intro.
	var guard = level.guards()[0]
	guard.position = Vector2(900, 430)
	guard.die()
	level.player.position = Vector2(900, 430)
	level.interact()
	check(level.player.has_gun and level.player.ammunition == 2, "Fallen Keeper provides a weapon and two rounds")
	level.interact()
	check(level.player.ammunition == 2, "Loot cannot be duplicated")
	# Once a corpse is empty, E may enter an adjacent hiding prop. Exit before firing.
	if level.player.in_hiding_spot:
		level.interact()
	level.player.fire_gun()
	check(level.player.ammunition == 1, "Shot consumes one round")
	print("GATES_LOOT_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
