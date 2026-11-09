extends "res://tools/test_intro.gd"

func run() -> void:
	await fresh()
	level.finish_dialogue()
	var player: IntroPlayer = level.player
	var controls = player.controls
	var settings = root.get_node("ControllerSettings")
	player.position = Vector2(120, 656)
	await frames(4)
	Input.action_press("move_right", 0.25)
	await frames(4)
	check(player.facing == 1.0, "Gentle right-stick movement does not shrink Miro")
	Input.action_release("move_right")
	Input.action_press("move_left", 0.4)
	await frames(4)
	check(player.facing == -1.0, "Gentle left movement mirrors at full sprite width")
	Input.action_release("move_left")
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 0.8
	settings._input(motion)
	await frames(2)
	check(controls.pad_prompts and not level.hint_icon.visible, "Controller mode hides keyboard hint icons")
	check(not "Space" in level.hint_label.text and not "Esc" in level.hint_label.text, "HUD stops showing keyboard movement prompts")
	check("Cross" in settings.prompt("[E] Strangle") and "Triangle" in settings.prompt("BLANKET READY [Q + click]"), "Interaction and blanket hints name controller buttons")
	level.start_dialogue([["MIRO", "Controller prompt review."]])
	await frames(2)
	check("Cross" in level.dialogue_panel.prompt_label.text and "Share" in level.dialogue_panel.prompt_label.text, "Dialogue shows controller continue and skip")
	level.finish_dialogue()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_A
	key.pressed = true
	settings._input(key)
	check(not controls.pad_prompts and settings.prompt("[E]") == "[E]", "Keyboard input restores keyboard prompts")
	motion.axis_value = 0.01
	settings._input(motion)
	check(not controls.pad_prompts, "Stick drift does not steal keyboard prompt mode")
	check("RT" in settings.controller_text("[Q + click] Left click", false) and "Y" in settings.controller_text("[Q + click]", false), "Xbox-style buttons use RT and Y")
	player.guns.assign(["pistol"])
	player.has_gun = true
	player.ammunition = 8
	controls.select_item("pistol")
	Input.action_press("pad_focus")
	controls._physics_process(0.016)
	check(controls.focus, "L2 engages gun focus")
	Input.action_release("pad_focus")
	controls._physics_process(0.016)
	check(not controls.focus, "Releasing L2 exits focus")
	controls.set_physics_process(false)
	controls.update_pad_aim(Vector2(-0.5, -0.7))
	var aim := player.weapon_aim_direction()
	check(aim.x < 0 and aim.y < 0 and is_equal_approx(aim.length(), 1.0), "Right stick produces normalized diagonal aim")
	check(player.focus_reticle_position().is_equal_approx(Vector2(0, -4) + aim * 96), "Controller reticle follows right stick rather than mouse position")
	controls.update_pad_aim(Vector2.ZERO)
	check(player.weapon_aim_direction().is_equal_approx(aim), "Stick at rest retains last aim")
	player.attack_cooldown = 0
	player.fire_gun()
	var bullets: Array = level.get_children().filter(func(child): return child.get_script() == load("res://scripts/weapon_projectile.gd"))
	check(not bullets.is_empty() and bullets[-1].direction.is_equal_approx(aim), "Bullet travels along the same direction as controller gun and reticle")
	level = null
	print("CONTROLLER_PROMPTS_AIM_RESULT: %d/%d passed" % [checks - failures.size(), checks])
	quit(0 if failures.is_empty() else 1)

