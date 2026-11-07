extends "res://tools/test_intro.gd"

func ending_setup() -> void:
	if is_instance_valid(level):
		level.queue_free()
		await frames(2)
	level = load("res://scenes/levels/level_05.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(2)
	level.finish_dialogue()
	level.player.position = level.areas.get_node("ForestViewpoint").position + Vector2(0, 6)
	level.sigil_placed = true
	level.milestones = {"FinalSigil": true, "FinalOffer": true, "BrotherEncounter": true, "DefeatExchange": true}
	level.interact()

func run() -> void:
	await ending_setup()
	check(is_instance_valid(level.cinematic) and level.controls_locked(), "Viewpoint starts cinematic and locks movement")
	level.paused = true
	var time: float = level.cinematic.elapsed
	await frames(90)
	check(is_equal_approx(level.cinematic.elapsed, time), "Pause freezes ending")
	level.paused = false
	var skip := InputEventAction.new()
	skip.action = "skip"
	skip.pressed = true
	Input.parse_input_event(skip)
	await frames(3)
	check(level.completed and not is_instance_valid(level.cinematic), "Tab skips and releases cinematic")
	var campaign = root.get_node("Campaign")
	check(campaign.boss_defeated and campaign.ending_complete and campaign.completed_sigils.has(5), "Skip commits ending and boss outcome")
	var skipped: Dictionary = campaign.narrative_milestones.duplicate()
	await ending_setup()
	check(not campaign.ending_complete and not campaign.completed_sigils.has(5), "Floor retry restores entry progress")
	await frames(940)
	check(level.completed and campaign.ending_complete, "Watching full sequence completes ending")
	check(skipped == campaign.narrative_milestones, "Watch and skip produce identical milestones")
	var count: int = level.milestones.size()
	level.interact()
	check(level.milestones.size() == count and not is_instance_valid(level.cinematic), "Ending cannot trigger twice")
	for number in range(1, 6):
		campaign.complete_floor(number, true, {"Story": true})
	check(campaign.completed_sigils.size() == 5, "Campaign tracks five distinct sigils")
	campaign.enter_floor(3)
	check(campaign.completed_sigils.size() == 2 and campaign.completed_sigils.has(1), "Retry restores earlier floors and clears later results")
	campaign.enter_floor(1)
	check(campaign.completed_sigils.is_empty() and campaign.narrative_milestones.is_empty(), "New run clears campaign")
	print("ENDING_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
