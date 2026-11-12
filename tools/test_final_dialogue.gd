extends "res://tools/test_intro.gd"
## Exercise the same cutscene and spatial speaker that the player sees/hears.

func run() -> void:
	var campaign: Node = root.get_node("Campaign")
	var radio: Node = root.get_node("RemoteRadio")
	var scenes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/interludes.json")).scenes
	for floor_done in range(1, 5):
		var authored: Dictionary = scenes[str(floor_done)]
		campaign.floor_stats.clear()
		# Return to the same floor after an aggressive clear and clear it quietly.
		for kills: int in [3, 0]:
			campaign.enter_floor(floor_done)
			campaign.complete_floor(floor_done, true, {}, {"kills": kills, "detections": int(kills > 0)})
			var cine := preload("res://scripts/interlude_cinematic.gd").new()
			cine.floor_done = floor_done
			root.add_child(cine)
			var expected: String = authored.hunted_first if kills else authored.lines[0][1]
			cine._process(cine.starts[0] + 0.01)
			check(cine.data.lines[0][1] == expected and radio.last_text == expected and radio.voice.stream.resource_path == radio.clip_path(expected), "Interlude %d: opening, subtitle and remote clip agree after %d kills" % [floor_done, kills])
			for i in range(1, cine.data.lines.size()):
				var line: Array = cine.data.lines[i]
				check(line == authored.lines[i] and radio.has_clip(line[1], "miro" if line[0] == "MIRO" else "niro"), "Shared interlude line %d:%d has correct recording" % [floor_done, i])
			cine.finish()
			await process_frame

	await fresh()
	level.finish_dialogue()
	var world: Node = level.world_features
	var player: Node2D = level.player
	player.set_physics_process(false)
	player.in_hiding_spot = true
	world.conversation_done = true
	world.casual_scenes.clear()
	world.mutter_wait = 1000
	world.voice.stop()
	world.line_left = 0
	world.recent_guard_lines.clear()
	world.pending_search_speakers.clear()
	var speakers: Array = level.guards().slice(0, 2)
	for guard in level.guards():
		guard.set_physics_process(false)
	for guard in speakers:
		guard.position = player.position + Vector2(30 * (1 + speakers.find(guard)), 0)
		guard.alert_state = IntroGuard.State.ALERT
		guard.lost_barked = false
		guard._physics_process(1.0 / 60.0)
	check(world.pending_search_speakers.size() == 2, "Two nearby guards losing Miro enqueue separate lines")
	var capture := AudioEffectCapture.new()
	var voice_bus := AudioServer.get_bus_index("Voice")
	AudioServer.add_bus_effect(voice_bus, capture)
	for guard in speakers:
		await frames(2)
		var path: String = world.keeper_clip_path(guard.guard_name, "lost")
		check(world.voice_speaker == guard and world.voice.stream.resource_path == path and world.subtitle.text.ends_with(world.roster.keepers[guard.guard_name].lost), "Search bark matches %s's voice and subtitle" % guard.guard_name)
		if DisplayServer.get_name() != "headless":
			capture.clear_buffer()
			var audible := false
			for i in range(120):
				await process_frame
				for sample: Vector2 in capture.get_buffer(capture.get_frames_available()):
					if sample.length_squared() > 0.000001:
						audible = true
						break
				if audible:
					break
			check(audible, "Voice bus carries audible search audio for %s" % guard.guard_name)
		world.voice.stop()
		world.line_left = 0
	AudioServer.remove_bus_effect(voice_bus, AudioServer.get_bus_effect_count(voice_bus) - 1)
	level.queue_free()
	await frames(3)
	print("FINAL_DIALOGUE_RESULT: ", checks - failures.size(), "/", checks)
	quit(0 if failures.is_empty() else 1)
