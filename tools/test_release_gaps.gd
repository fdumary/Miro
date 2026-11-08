extends "res://tools/test_intro.gd"
## Release gaps from the November 7 handoff: Level 5 sigil gating, controller login on the
## Level 3 checkpoint, and level select resuming a floor with the run state it was reached with.

func floor_scene(number: int) -> void:
	if is_instance_valid(level):
		level.queue_free()
		await frames(2)
	level = load("res://scenes/levels/level_%02d.tscn" % number).instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	level.finish_dialogue()

func run() -> void:
	var campaign = root.get_node("Campaign")
	var behavior = root.get_node("PlayerBehavior")

	# Level 5: the alarm (guitar) and the ending both wait for the final sigil.
	await floor_scene(5)
	check("Place the final sigil" in level.objective(), "Level 5 opens on the final sigil objective")
	level.player.position = level.areas.get_node("Guitar").position
	level.interact()
	check(level.dialogue.is_empty() and not level.player.controls.has_guitar, "Guitar is locked until the sigil is placed")
	level.player.position = level.areas.get_node("ForestViewpoint").position + Vector2(0, 6)
	level.milestones = {"FinalOffer": true, "BrotherEncounter": true, "DefeatExchange": true}
	level.interact()
	check(not is_instance_valid(level.cinematic), "Ending cannot start without the final sigil")
	level.milestones["FinalSigil"] = true
	level.sigil_placed = true
	level.interact()
	check(is_instance_valid(level.cinematic), "Ending starts once the sigil is placed")

	# Level 3 checkpoint login without a keyboard.
	await floor_scene(3)
	var world = level.world_features
	world.password_known = false
	world.open_terminal()
	check(not world.password_use.visible, "Known-password button hides until the password is known")
	world.password_slip.pressed.emit()
	check(world.password_known and world.password_use.visible, "Maintenance slip reveals the password button")
	world.password_use.pressed.emit()
	check(world.terminal_authenticated and not world.modal_open() and level.hack_remaining > 0, "Password button logs in and starts the hack")
	world.open_terminal()
	var cancel := InputEventAction.new()
	cancel.action = "ui_cancel"
	cancel.pressed = true
	Input.parse_input_event(cancel)
	await frames(2)
	check(not world.modal_open(), "Cancel (B / Esc) closes the login")
	for action in ["ui_accept", "ui_up", "ui_down", "ui_cancel"]:
		var has_pad := InputMap.action_get_events(action).any(func(event): return event is InputEventJoypadButton)
		check(has_pad, "%s has a controller binding" % action)

	# Terminal: a small pretend file system with readable records.
	var console = level.player.controls
	await frames(2)
	console.show_console(true)
	console.run_command("ls")
	check("readme.txt" in console.output.text, "ls lists the floor's files")
	console.run_command("cat readme.txt")
	check("TOWER RECORDS" in console.output.text, "cat reads a file")
	console.run_command("cat missing.txt")
	check("No such file" in console.output.text, "cat reports a missing file")
	console.run_command("pwd")
	check("floor03" in console.output.text, "pwd shows the floor")
	console.run_command("whoami")
	check(console.output.text == "guest", "whoami is guest until you log in")

	# Level select: a snapshot taken at floor entry comes back after a "relaunch".
	campaign.remote_owned = true
	campaign.remote_unlocked = true
	campaign.played_from_start = true
	campaign.floor_stats = {1: {"kills": 3, "detections": 2, "stealth": 0, "offense": 3}, 2: {"kills": 1, "detections": 1, "stealth": 0, "offense": 1}}
	campaign.narrative_milestones = {"1:BrotherVoice": true, "2:ServicePort": true}
	campaign.inventory_layout.assign(["remote", "shank", "c4", "gun_1", "gun_2"])
	behavior.committed = {1: {"defiant": 6}, 2: {"defiant": 2}}
	behavior.choices = {"l1_cell": 1, "l2_port": 0}
	await floor_scene(3)
	var reputation: String = campaign.reputation()
	check(campaign.floor_snapshots.has(3), "Entering a floor records its snapshot")
	campaign.remote_owned = false
	campaign.remote_unlocked = false
	campaign.played_from_start = false
	campaign.floor_stats = {}
	campaign.narrative_milestones = {}
	campaign.inventory_layout.assign(["shank", "c4", "gun_1", "gun_2", "remote"])
	behavior.committed = {}
	behavior.choices = {}
	check(campaign.restore_floor_snapshot(3), "Snapshot restores")
	check(campaign.remote_owned and campaign.remote_unlocked, "MP3 ownership and unlock come back")
	check(campaign.floor_stats.has(1) and campaign.floor_stats.has(2) and campaign.reputation() == reputation, "Earlier floors and the story branch come back")
	check(campaign.narrative_milestones.has("2:ServicePort"), "Story milestones come back")
	check(campaign.inventory_layout[0] == "remote", "Inventory order comes back")
	check(campaign.played_from_start, "A run begun at Level 1 can still finish the game")
	check(behavior.committed.has(1) and behavior.choices.has("l2_port"), "Play-style profile comes back")
	await floor_scene(3)
	check(level.player.controls.has_remote and level.player.controls.remote_unlocked, "The restored floor hands Miro the MP3")
	campaign.floor_snapshots.erase(4)
	check(not campaign.restore_floor_snapshot(4) and not campaign.remote_owned and campaign.floor_stats.is_empty(), "A floor with no snapshot starts fresh")

	print("RELEASE_GAPS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
