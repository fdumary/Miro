extends "res://tools/test_intro.gd"
class SavedCampaign:
	extends "res://scripts/campaign.gd"
	func can_persist() -> bool:
		return true
	func progress_path() -> String:
		return "res://tmp/kit-checkpoint-regression.cfg"
func load_floor() -> void:
	if is_instance_valid(level):
		level.queue_free()
		await frames(3)
	level = load("res://scenes/levels/level_02.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(10)
	level.finish_dialogue()
	for guard in level.guards():
		guard.set_physics_process(false)
func run() -> void:
	var campaign = root.get_node("Campaign")
	var path := "res://tmp/kit-checkpoint-regression.cfg"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var writer := SavedCampaign.new()
	root.add_child(writer)
	writer.carried_kit = {"has_supplies": true, "has_gun": true, "guns": ["pistol", "smg"], "gun_ammo": {"pistol": 5, "smg": 14}, "equipped_gun": "pistol", "ammunition": 5, "reserves": {"pistol": 12, "smg": 48}, "health": 4, "c4_count": 2}
	writer.carried_from = 1
	writer.remote_owned = true
	writer.remote_unlocked = true
	writer.case_anchors[2] = 1
	writer.save_floor_snapshot(2)
	writer.free()
	var reader := SavedCampaign.new()
	root.add_child(reader)
	check(reader.restore_floor_snapshot(2), "Floor entry snapshot reloads from disk")
	check(reader.carried_kit.guns == ["pistol", "smg"] and reader.carried_kit.ammunition == 5 and reader.carried_kit.reserves.pistol == 12, "Gun, magazine and reserve ammo survive a new campaign instance")
	check(reader.carried_from == 1 and reader.case_anchors.get(2) == 1, "Carry source and case placement survive relaunch")
	campaign.floor_snapshots[2] = reader.floor_snapshot(2).duplicate(true)
	campaign.restore_floor_snapshot(2)
	campaign.checkpoint.clear()
	reader.free()
	await load_floor()
	check(level.player.guns == ["pistol", "smg"] and level.player.ammunition == 5, "Entering a restored floor applies the carried guns and magazine")
	check(level.player.controls.reserves.pistol == 12 and level.player.controls.reserves.smg == 48, "Entering a restored floor keeps exact reserve ammunition")
	var cases: Array = level.world_features.props.filter(func(prop): return prop.kind == "case")
	check(not cases.is_empty(), "Authored ammunition cases spawn")
	var cache = cases[0]
	level.player.global_position = cache.global_position
	level.player.health = 3
	level.world_features.try_interact()
	check(cache.used, "Taking ammo consumes the authored case")
	var victim = level.guards()[0]
	victim.take_damage(16, true)
	victim.gun_taken = true
	var victim_name := str(victim.name)
	var looted = level.guards()[1]
	looted.gun_taken = true
	var looted_name := str(looted.name)
	level.player.controls.has_remote = true
	level.player.controls.remote_unlocked = true
	level.player.controls.layout.assign(["remote", "c4", "gun_1", "gun_2", "shank"])
	var magazine: int = level.player.ammunition
	var reserves: Dictionary = level.player.controls.reserves.duplicate()
	var point: Vector2 = level.player.global_position
	var checkpoint := {"floor": 2, "storey": 1, "position": point, "milestones": {}, "sigil": false, "player": level.player_snapshot(), "dead": level.dead_guards(), "used_cases": level.used_ammo_cases(), "looted_guards": level.looted_guard_names()}
	var saver := SavedCampaign.new()
	root.add_child(saver)
	saver.checkpoint = checkpoint.duplicate(true)
	saver.save_checkpoint()
	saver.free()
	var reopened := SavedCampaign.new()
	root.add_child(reopened)
	campaign.checkpoint = reopened.saved_checkpoint(2).duplicate(true)
	campaign.checkpoint["retry"] = true
	reopened.free()
	await load_floor()
	check(level.player.guns == ["pistol", "smg"] and level.player.ammunition == magazine and level.player.controls.reserves == reserves, "Disk checkpoint restores exact weapons and ammunition")
	check(level.player.controls.has_remote and level.player.controls.remote_unlocked, "Disk checkpoint retains MP3 ownership and unlock")
	check(level.player.controls.layout[0] == "remote", "Disk checkpoint restores inventory order")
	check(level.get_node("Guards/" + victim_name).is_dead and level.get_node("Guards/" + victim_name).gun_taken, "Dead and looted authored guard remains dead and looted")
	check(level.get_node("Guards/" + looted_name).gun_taken, "Looted living guard does not produce a second gun or ammo pickup")
	var restored_cases: Array = level.world_features.props.filter(func(prop): return prop.kind == "case")
	check(restored_cases[0].used, "Consumed ammo case stays consumed after reopening")
	campaign.checkpoint = checkpoint.duplicate(true)
	campaign.checkpoint["retry"] = true
	await load_floor()
	check(level.player.ammunition == magazine and level.player.controls.reserves == reserves, "Repeated retry does not duplicate magazine or reserve ammo")
	check(level.world_features.props.filter(func(prop): return prop.kind == "case")[0].used, "Repeated retry does not refill the consumed case")
	DirAccess.remove_absolute(path)
	print("SAVE_LOOT_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
