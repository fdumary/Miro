extends "res://tools/test_intro.gd"
## Level 4: a first wave runs past Miro (cloaked) and leaves; then hunting waves rush him.
func run() -> void:
	level = load("res://scenes/levels/level_04.tscn").instantiate()
	level.set_meta("hunt_waves_test", true)
	root.add_child(level)
	current_scene = level
	await frames(3)
	level.finish_dialogue()
	await frames(10)
	var hunt = level.get_node("HuntWaves")
	check(hunt.started and hunt.runners.size() >= 5, "Five Keepers run through at the start")
	check(level.player.is_concealed, "Miro starts cloaked")
	var runner = hunt.runners[0]
	var begin_x: float = runner.position.x
	var begin_time: float = runner.time
	check(runner.velocity.x == 150.0, "Scripted runners report movement for the Keeper walk sprite")
	await frames(60)
	check(runner.position.x > begin_x + 50, "The runners pass Miro")
	check(runner.time > begin_time + 0.5, "Scripted runners advance their walk animation clock")
	var pause_x: float = runner.position.x
	var pause_time: float = runner.time
	level.paused = true
	await frames(8)
	check(runner.position.x == pause_x and runner.time == pause_time, "Pausing freezes scripted movement and animation")
	level.paused = false
	check(runner.alert_state == IntroGuard.State.PATROL and level.player.is_concealed, "They do not notice him")
	hunt.clock = hunt.next_wave_at
	await frames(5)
	check(hunt.waves_sent == 1 and hunt.wave_guards.size() >= 5, "A hunting wave of five or more arrives")
	var hunting := 0
	for guard in hunt.wave_guards:
		if guard.pursuing or guard.alert_state != IntroGuard.State.PATROL:
			hunting += 1
	check(hunting == hunt.wave_guards.size(), "Wave Keepers are all hunting")
	print("HUNT_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
