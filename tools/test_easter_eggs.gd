extends "res://tools/test_intro.gd"
## Four wall-note easter eggs: each exists on its floor, opens a picture, grants its achievement;
## the Foreva note also puts the FOREVA beat on the MP3.
func run() -> void:
	var campaign = root.get_node("Campaign")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/easter_eggs.json"))
	for entry in data.eggs:
		if is_instance_valid(level):
			level.queue_free()
			await frames(2)
		level = load("res://scenes/levels/level_%02d.tscn" % int(entry.floor)).instantiate()
		root.add_child(level)
		current_scene = level
		await frames(10)
		level.finish_dialogue()
		var world = level.world_features
		var found = null
		for prop in world.props:
			if prop.kind == "egg" and prop.egg.id == entry.id:
				found = prop
		check(found != null, "%s note exists on floor %d" % [entry.id, int(entry.floor)])
		if found == null:
			continue
		check(ResourceLoader.exists(str(entry.image)), "%s picture is in the project" % entry.id)
		level.player.global_position = found.global_position + Vector2(0, 2)
		for guard in level.guards():
			guard.set_physics_process(false)
		check(world.try_interact() and is_instance_valid(world.egg_view), "%s note opens its picture" % entry.id)
		check(campaign.has_achievement(str(entry.id)), "%s grants its achievement" % entry.id)
		check(world.try_interact() and not is_instance_valid(world.egg_view), "E closes the picture")
		if entry.has("unlock_track"):
			for unlocked_id in str(entry.unlock_track).split(","):
				check(campaign.unlocked_tracks().has(unlocked_id.strip_edges()), "%s is on the MP3" % unlocked_id.strip_edges())
	check(JSON.parse_string(FileAccess.get_file_as_string("res://data/music/runtime_catalog.json")).tracks.has("foreva"), "Foreva is in the runtime catalog")
	print("EASTER_EGGS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
