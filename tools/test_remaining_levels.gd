extends "res://tools/test_intro.gd"

const RouteRunner = preload("res://tools/route_runner.gd")

## Levels 2-4 are authored layouts (tools/level_layouts.py): each is played start to finish by
## following its route with real inputs (walk, jump, crouch-crawl, ladders, every objective).
## Level 5 has its own encounter flow, covered end to end by test_brother.gd.
func run() -> void:
	var only := OS.get_cmdline_user_args()
	for number in range(2, 5):
		if not only.is_empty() and str(number) not in only:
			continue
		if is_instance_valid(level):
			level.queue_free()
			await frames(2)
		level = load("res://scenes/levels/level_%02d.tscn" % number).instantiate()
		root.add_child(level)
		current_scene = level
		await frames(3)
		check(not level.dialogue.is_empty() and level.dialogue[0][0] == "MIRO" and level.dialogue[0].size() > 2, "Level %d opens on Miro's thought, not a title speaker" % number)
		level.finish_dialogue()
		var definition: Dictionary = level.definition
		check(definition.sources.size() >= 5, "Level %d has per-document references" % number)
		for source in definition.sources:
			check(FileAccess.file_exists("res://" + source.path), "Source exists: " + source.path)
		check(definition.storeys.size() == 6 and definition.world_size[1] > 1000, "Level %d has two sub-floors of three storeys" % number)
		for station in definition.stations:
			check(definition.hints.has(station.id) and definition.hints[station.id].size() == 3, "Level %d has three Z hints for %s" % [number, station.id])
		level.player.health = 99
		var runner = RouteRunner.new(self)
		var failed: Array[String] = await runner.follow(level)
		check(failed.is_empty(), "Level %d authored route completes %s" % [number, ", ".join(failed)])
		for station in definition.stations:
			check(level.milestones.has(station.id), "Complete " + station.id)
		check(level.sigil_placed, "Level %d requires its own sigil" % number)
		check(root.get_node("MusicDirector").section_id == "floor_%d_second" % number, "Level %d second song plays in the lower sub-floor" % number)
		check(level.completed and not level.player.is_dead, "Level %d traversed alive" % number)
	print("REMAINING_LEVELS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)

func fight_brother() -> void:
	var boss = level.brother
	for tick in range(2400):
		if boss.is_dead or level.player.is_dead:
			break
		var offset: float = boss.position.x - level.player.position.x
		Input.action_release("move_left")
		Input.action_release("move_right")
		if boss.is_vulnerable:
			if absf(offset) > 32:
				Input.action_press("move_right" if offset > 0 else "move_left")
			level.player.facing = signf(offset)
			level.player.shank()
		else:
			if absf(offset) < 75:
				Input.action_press("move_left" if offset > 0 else "move_right")
			if boss.current_phase == boss.Phase.RUSH and absf(offset) < 80:
				Input.action_press("jump")
		if boss.projectile_live and boss.projectile.distance_to(level.player.position) < 100:
			Input.action_press("jump")
		await frames(1)
		Input.action_release("jump")
	Input.action_release("move_left")
	Input.action_release("move_right")
	check(boss.is_dead and not level.player.is_dead, "Defeat brother using movement and shank")
