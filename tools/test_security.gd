extends "res://tools/test_intro.gd"

func run() -> void:
	level = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	level.finish_dialogue()
	var camera = level.connected_cameras[0]
	camera.set_physics_process(false)
	camera.position = Vector2(300, 180)
	camera.sweep_time = 0
	level.player.position = Vector2(300, 232)
	check(camera.detects_player(), "Camera detects exposed player inside cone")
	level.player.is_concealed = true
	check(not camera.detects_player(), "Blanket concealment blocks detection")
	level.player.is_concealed = false
	level.player.position = Vector2(100, 180)
	check(not camera.detects_player(), "Outside cone is safe")
	level.player.position = Vector2(300, 280)
	check(not camera.detects_player(), "Stone floor occludes camera")
	level.player.position = Vector2(300, 232)
	level.camera_alert(level.player.position)
	check(level.floor_alerts == 1, "Detection raises floor alert")
	for guard in level.guards():
		check(guard.alert_state == IntroGuard.State.SEARCH, "Floor alert reaches every guard")
		guard.set_physics_process(false)
	level.interact()
	check(level.world_features.modal_open(), "Terminal requests a password")
	level.world_features.submit_password("wrong")
	check(level.hack_remaining == 0, "Wrong password cannot start hack")
	level.world_features.submit_password("root")
	await frames(25)
	check(camera.is_active and not level.milestones.has("RemoteTerminal"), "Hack cannot finish early")
	level.paused = true
	var remaining: float = level.hack_remaining
	await frames(70)
	check(is_equal_approx(remaining, level.hack_remaining), "Pause freezes hack timer")
	level.paused = false
	level.player.position = Vector2(100, 232)
	await frames(2)
	check(level.hack_remaining == 0 and camera.is_active, "Leaving terminal cancels hack")
	level.player.position = Vector2(300, 232)
	level.interact()
	await frames(65)
	for linked in level.connected_cameras:
		check(not linked.is_active, "Completed hack disables linked camera")
	level.finish_dialogue()
	check(level.milestones.has("RemoteTerminal"), "Skipping completion dialogue preserves hack")
	check(not camera.detects_player(), "Disabled camera cannot detect")
	level.queue_free()
	await frames(2)
	level = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(2)
	check(level.connected_cameras[0].is_active and level.milestones.is_empty(), "Reload restores checkpoint")
	print("SECURITY_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
