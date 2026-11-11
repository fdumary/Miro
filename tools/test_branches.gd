extends "res://tools/test_intro.gd"
## MISSING vs HUNTED: the world reacts, the plot does not. Retry-safe scoring and MP3 unlock preview.

func floor_scene(number: int) -> void:
	if is_instance_valid(level):
		level.queue_free()
		await frames(2)
	level = load("res://scenes/levels/level_%02d.tscn" % number).instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)

func run() -> void:
	var campaign = root.get_node("Campaign")
	campaign.enter_floor(1)
	check(campaign.reputation() == "MISSING", "A new run starts as MISSING")
	campaign.complete_floor(1, true, {}, {"kills": 0, "detections": 0, "stealth_bonus": 1})
	check(campaign.floor_stats[1].stealth == 3 and campaign.style_word({"kills": 0, "detections": 0}) == "GHOST", "Unseen pickpocket floor scores 3 stealth and reads GHOST")
	await floor_scene(2)
	var opening := str(level.dialogue)
	check("unaccounted for" in opening and "face" in opening, "MISSING floor opens with the search PA and Niro's remote call")
	check(not level.hunted and not level.has_node("Guards/HuntedKeeper") and not level.poster.wanted, "MISSING floor: normal patrols and a MISSING poster")
	check(level.world_features.thoughts["2"][0].text.begins_with("If nobody sees me"), "MISSING entry thought")
	check(level.world_features.conversation.any(func(line): return "on our shift" in line.text), "MISSING guards suspect each other")
	check(not "birthday melody" in level.floor_report(), "Stealth points do not advertise the strangle-only achievement reward")
	# Retry-safe: kills only count once a floor is completed.
	campaign.enter_floor(2)
	campaign.complete_floor(2, true, {}, {"kills": 3, "detections": 2})
	check(campaign.reputation() == "HUNTED", "Three committed kills make Miro HUNTED")
	await floor_scene(3)
	opening = str(level.dialogue)
	check("Lethal force" in opening and "wore their uniform" in opening, "HUNTED floor 3 opens with the lethal-force PA and the voice's own line (no repeats of floor 2's)")
	check(level.hunted and level.has_node("Guards/HuntedKeeper") and level.poster.wanted, "HUNTED floor adds an armed Keeper and a WANTED poster")
	check(level.objective().contains("checkpoint"), "Objectives are the same on both branches")
	level.finish_dialogue()
	var keeper = level.get_node("Guards/HuntedKeeper")
	keeper.die()
	var bubble = level.world_features.remote_bubble
	check(level.world_features.remote_busy() and bubble.tag == "NIRO · remote" and not bubble.text_label.text.is_empty(), "A kill brings Niro's disappointment over the remote, in a remote bubble")
	level.world_features.remote_left = 0
	level.get_node("Guards/OfficeKeeper").die()
	check(not level.world_features.remote_busy() and level.disappointment_heard, "Niro's disappointment is heard once per floor")
	campaign.enter_floor(2)
	check(campaign.reputation() == "MISSING", "Retrying an earlier floor restores its entry reputation")
	print("BRANCHES_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
