extends "res://tools/test_intro.gd"
func run() -> void:
	var expected: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tmp/voice-expected.json"))
	for clip in expected:
		var stream = load("res://assets/audio/voice/%s.mp3" % clip)
		check(stream is AudioStream and stream.get_length() > 0, "Voice clip decodes: " + str(clip))
	await fresh()
	level.finish_dialogue()
	var player = level.player
	player.has_supplies = true
	for guard in level.guards():
		guard.set_physics_process(false)
		guard.position = Vector2(-500, -500)
	player.position = Vector2(350, 236)
	Input.action_press("move_right")
	await frames(6)
	var normal_speed: float = absf(player.velocity.x)
	Input.action_press("slow_walk")
	await frames(6)
	var quiet_speed: float = absf(player.velocity.x)
	Input.action_release("move_right")
	Input.action_release("slow_walk")
	check(normal_speed > quiet_speed and quiet_speed > 0 and quiet_speed < player.movement_speed * 0.9, "Shift quiet-walk is slower and below the footstep hearing threshold")
	player.set_physics_process(false)
	player.position = Vector2(350, 236)
	var guard = level.guards()[0]
	guard.position = Vector2(410, 236)
	guard.facing = 1
	guard.distracted = false
	guard.conversation_hold = false
	guard.heard_time = 0
	player.velocity.x = normal_speed
	var heard := false
	for tick in range(40):
		heard = guard.hears_player() or heard
		await frames(1)
	check(heard, "A nearby guard can hear sustained normal movement from behind")
	guard.heard_time = 0
	player.velocity.x = quiet_speed
	heard = false
	for tick in range(40):
		heard = guard.hears_player() or heard
		await frames(1)
	check(not heard, "Shift quiet-walking does not trigger the full-speed footstep cue")
	guard.facing = -1
	check(guard.detect_player(), "Quiet walking still allows ordinary line-of-sight detection")
	var world = level.world_features
	world.conversation_done = true
	world.actors.clear()
	world.casual_scenes.clear()
	world.mutter_wait = 1000
	world.speak(guard, "idle_1", world.roster.keepers[guard.guard_name].idle[0])
	check(world.voice.stream != null and world.line_left >= world.voice.stream.get_length() + 0.3, "Guard dialogue timing includes the complete clip plus a small gap")
	world.voice.play()
	await frames(1)
	var path: String = world.voice.stream.resource_path
	var distant = level.guards()[1]
	distant.position = Vector2(1000, 236)
	world.bark(distant, "alert")
	check(world.voice.stream.resource_path == path and world.voice_speaker == guard, "A distant guard does not cut off the current line")
	var time_left: float = world.line_left
	level.paused = true
	paused = true
	await frames(5)
	check(is_equal_approx(world.line_left, time_left), "Pause preserves dialogue timing")
	paused = false
	level.paused = false
	guard.is_dead = true
	await frames(2)
	check(not world.voice.playing and world.subtitle.text.is_empty(), "A dead speaker stops cleanly rather than leaving stale speech")
	world.voice.stop()
	world.voice.stream = null
	# The dummy audio mixer runs on wall time even during accelerated fixed-fps checks.
	OS.delay_msec(120)
	level.queue_free()
	level = null
	await frames(8)
	print("QUIET_WALK_VOICE_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
