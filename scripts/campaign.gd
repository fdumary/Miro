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
# True only when this run began at Level 1, so review launches never unlock the completed menu.
var played_from_start := false
## Committed per-floor results: {floor: {kills, detections, stealth, offense}}. Written only by
## complete_floor(), so a retry restores the state at floor entry.
var floor_stats: Dictionary = {}
var branch_data: Dictionary = {}

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
		played_from_start = true
		remote_owned = false
		remote_unlocked = false
	if number == 1 and current_floor != 1:
		case_anchors.clear()
	current_floor = number
	print("FLOOR_READY: ", number)
	for floor_number in completed_sigils.keys():
		if int(floor_number) >= number:
			completed_sigils.erase(floor_number)
	for floor_number in floor_stats.keys():
		if int(floor_number) >= number:
			floor_stats.erase(floor_number)
	for key in narrative_milestones.keys():
		if int(str(key).get_slice(":", 0)) >= number:
			narrative_milestones.erase(key)
	boss_defeated = false
	ending_complete = false

func game_completed() -> bool:
	var progress := ConfigFile.new()
	progress.load("user://progress.cfg")
	return bool(progress.get_value("game", "completed", false))

## Test and QA runs never write the player's save (completed menu, MP3 unlocks).
func can_persist() -> bool:
	return not OS.has_feature("qa") and not "--script" in OS.get_cmdline_args()

func mark_game_completed() -> void:
	if not can_persist():
		return
	var progress := ConfigFile.new()
	progress.load("user://progress.cfg")
	progress.set_value("game", "completed", true)
	progress.save("user://progress.cfg")

func total(key: String) -> int:
	var sum := 0
	for floor_number in floor_stats:
		sum += int(floor_stats[floor_number].get(key, 0))
	return sum

## MISSING (stealth) or HUNTED (offense), from committed floors only. Level 1 is neutral.
func reputation() -> String:
	if floor_stats.is_empty():
		return "MISSING"
	return "HUNTED" if total("kills") >= 3 or total("offense") > total("stealth") else "MISSING"

func branch() -> Dictionary:
	if branch_data.is_empty():
		branch_data = JSON.parse_string(FileAccess.get_file_as_string("res://data/branch_reactions.json"))
	return branch_data

func branch_line(key: String):
	return branch()[reputation()].get(key, "")

## Style word for the end-of-floor report: GHOST (unseen, no kills), SEEN or HUNTED.
static func style_word(stats: Dictionary) -> String:
	if int(stats.get("kills", 0)) == 0 and int(stats.get("detections", 0)) == 0:
		return "GHOST"
	return "HUNTED" if int(stats.get("kills", 0)) > 0 else "SEEN"

## Scores one floor's raw counts. Unseen floor +2 stealth, plus any unseen bonuses; +1 offense per kill and loud breach.
static func score_floor(raw: Dictionary) -> Dictionary:
	var stats := raw.duplicate()
	var stealth := int(raw.get("stealth_bonus", 0))
	if int(raw.get("detections", 0)) == 0:
		stealth += 2
	stats["stealth"] = stealth
	stats["offense"] = int(raw.get("kills", 0)) + int(raw.get("loud", 0))
	return stats

## MP3 unlocks earned by stealth are saved to disk and never lost.
func unlocked_tracks() -> Array:
	var progress := ConfigFile.new()
	progress.load("user://progress.cfg")
	return progress.get_value("mp3", "unlocked", [])

## Tracks that finishing the current floor would unlock (shown on the floor report).
func preview_unlocks(floor_stealth: int) -> Array:
	var names: Array = []
	var points := total("stealth") + floor_stealth
	var unlocked := unlocked_tracks()
	for entry in branch().get("mp3_unlocks", []):
		if points >= int(entry.stealth_points) and not unlocked.has(entry.track):
			names.append(entry.track.replace("_", " "))
	return names

func update_unlocks() -> Array:
	var earned: Array = []
	var points := total("stealth")
	var unlocked := unlocked_tracks()
	for entry in branch().get("mp3_unlocks", []):
		if points >= int(entry.stealth_points) and not unlocked.has(entry.track):
			unlocked.append(entry.track)
			earned.append(entry.track)
	if not earned.is_empty() and can_persist():
		var progress := ConfigFile.new()
		progress.load("user://progress.cfg")
		progress.set_value("mp3", "unlocked", unlocked)
		progress.save("user://progress.cfg")
	return earned

func complete_floor(number: int, sigil: bool, milestones: Dictionary, raw_stats: Dictionary = {}) -> void:
	floor_stats[number] = score_floor(raw_stats)
	if sigil:
		completed_sigils[number] = true
	for key in milestones:
		narrative_milestones["%d:%s" % [number, key]] = milestones[key]
	if number == 5:
		boss_defeated = milestones.has("BrotherEncounter")
		ending_complete = milestones.has("ForestViewpoint")
