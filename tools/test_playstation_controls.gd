extends "res://tools/test_intro.gd"

func press(button: int) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event = InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = false
	Input.parse_input_event(event)
	await frames(1)

func run() -> void:
	await fresh()
	level.finish_dialogue()
	var player: IntroPlayer = level.player
	await frames(5)
	await press(JOY_BUTTON_A)
	check(player.has_supplies, "Cross interacts with the bed instead of jumping")
	level.finish_dialogue()
	for guard in level.guards():guard.set_physics_process(false);guard.position=Vector2(-500,-500)
	var safe_spot := false
	for x in range(340, 1040, 28):
		player.position = Vector2(x, 656)
		player.velocity = Vector2.ZERO
		await frames(6)
		if player.is_on_floor() and not "[E]" in level.context_hint() and level.get_node("InnerConflict").usable_prop()==null:
			safe_spot = true
			break
	check(safe_spot, "Controller jumping fixture has no nearby interaction")
	await press(JOY_BUTTON_A)
	check(player.velocity.y < 0 and player.jumps_used == 1, "Cross jumps without a nearby prompt")
	await press(JOY_BUTTON_A)
	check(player.jumps_used == 2, "Cross also triggers the air jump")
	await frames(55)
	await press(JOY_BUTTON_LEFT_STICK)
	check(player.crouching, "L3 toggles crouch on")
	await press(JOY_BUTTON_LEFT_STICK)
	check(not player.crouching, "L3 toggles crouch off")
	player.stealth_cooldown_left=0
	player.position=Vector2(180,236)
	await frames(3)
	await press(JOY_BUTTON_LEFT_SHOULDER)
	check(player.is_concealed, "L1 immediately activates blanket")
	player.guns.assign(["pistol"])
	player.has_gun = true
	player.ammunition = 0
	player.controls.select_item("pistol")
	await frames(2)
	await press(JOY_BUTTON_X)
	check(player.controls.reload_left > 0, "Square reloads")
	await press(JOY_BUTTON_B)
	check(player.dodge_left > 0, "Circle dodges")
	await press(JOY_BUTTON_TOUCHPAD)
	check(player.controls.inventory_open, "Touchpad opens inventory")
	await press(JOY_BUTTON_B)
	check(not player.controls.inventory_open, "Circle closes inventory")
	print("PLAYSTATION_RESULT: %d/%d passed" % [checks - failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
