extends "res://tools/test_intro.gd"
## Exercise the actual actors, including HUNTED patrols and the largest reinforcement roster.

func open_floor(number: int) -> void:
	if is_instance_valid(level):
		level.queue_free()
		await frames(2)
	var path := "res://scenes/intro.tscn" if number == 1 else "res://scenes/levels/level_%02d.tscn" % number
	level = load(path).instantiate()
	root.add_child(level)
	current_scene = level
	await frames(2)

func run() -> void:
	var cast: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/voice_cast.json")).voices
	var names := {}
	var personalities := {}
	var voices := {}
	var campaign = root.get_node("Campaign")
	for floor in range(1, 6):
		if floor > 1:
			campaign.enter_floor(floor - 1)
			campaign.complete_floor(floor - 1, true, {}, {"kills": 4, "detections": 1})
		await open_floor(floor)
		var world = level.world_features
		if floor in [2, 3, 4]:
			check(level.has_node("Guards/HuntedKeeper"), "Hunted reinforcement joins floor %d" % floor)
			var actors: Array = world.actors.map(func(actor): return actor.guard_name)
			check(actors == world.roster.conversation_cast[str(floor)], "Conversation cast matches floor %d" % floor)
			for line in world.conversation:
				check(ResourceLoader.exists(world.keeper_clip_path(actors[line.speaker], line.id)), "Voiced %s on floor %d" % [line.id, floor])
		if floor in [2, 3]:
			level.spawn_watcher_reserves(level.player.global_position)
		if floor == 5:
			# Three Hard + HUNTED waves yield fourteen guards; the two final Niro encounters can call four more.
			for index in range(18):
				var guard = level.flow.spawn_guard(Vector2(800, 236), "pistol")
				guard.set_physics_process(false)
		for guard in level.guards():
			var keeper_name: String = guard.guard_name
			var voice: String = cast.get(keeper_name.to_lower(), {}).get("voice_id", "")
			check(not names.has(keeper_name) and not personalities.has(guard.personality)
				and not voice.is_empty() and not voices.has(voice), "%s has a unique name, personality and voice" % keeper_name)
			names[keeper_name] = true
			personalities[guard.personality] = true
			voices[voice] = true
			for line_id in ["alert", "body", "idle_1", "idle_2"]:
				check(ResourceLoader.exists(world.keeper_clip_path(keeper_name, line_id)), "%s has %s audio" % [keeper_name, line_id])
	check(names.size() == level.world_features.roster.keepers.size(), "All authored Keepers can appear in game")
	print("KEEPER_CAST_RESULT: %d/%d passed" % [checks - failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
