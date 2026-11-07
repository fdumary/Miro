extends Node
## Session progress; floor results commit only when descending, so retries restore entry state.
var case_anchors: Dictionary = {}
var inventory_layout: Array[String] = ["shank", "c4", "gun_1", "gun_2", "remote"]
var remote_owned := false
var remote_unlocked := false
var current_floor := 1
var completed_sigils: Dictionary = {}
var narrative_milestones: Dictionary = {}
var boss_defeated := false
var ending_complete := false
var launch_consumed := false

func launch_floor() -> int:
	if launch_consumed:
		return 1
	launch_consumed = true
	if OS.has_feature("qa") and "--verify-playthrough" in OS.get_cmdline_user_args():
		var runner = load("res://tools/export_playthrough.gd").new()
		get_tree().root.call_deferred("add_child", runner)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--level="):
			return clampi(argument.trim_prefix("--level=").to_int(), 1, 5)
	return 1

func enter_floor(number: int) -> void:
	if number == 1:
		remote_owned = false
		remote_unlocked = false
	if number == 1 and current_floor != 1:
		case_anchors.clear()
	current_floor = number
	print("FLOOR_READY: ", number)
	for floor_number in completed_sigils.keys():
		if int(floor_number) >= number:
			completed_sigils.erase(floor_number)
	for key in narrative_milestones.keys():
		if int(str(key).get_slice(":", 0)) >= number:
			narrative_milestones.erase(key)
	boss_defeated = false
	ending_complete = false

func complete_floor(number: int, sigil: bool, milestones: Dictionary) -> void:
	if sigil:
		completed_sigils[number] = true
	for key in milestones:
		narrative_milestones["%d:%s" % [number, key]] = milestones[key]
	if number == 5:
		boss_defeated = milestones.has("BrotherEncounter")
		ending_complete = milestones.has("ForestViewpoint")
