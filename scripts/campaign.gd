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
## Which start-menu screen to open next (the pause menu's "Level select" sets "levels").
var menu_screen := ""

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
	unlock_level(number)
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

## MP3 unlocks are saved to disk and never lost. Calm beats come from stealth points
## (unseen floors, quiet thefts); the aggressive ones from Keepers killed across the run.
## Test runs keep their unlocks in memory only.
var session_unlocks: Array = []

func unlocked_tracks() -> Array:
	if not can_persist():
		return session_unlocks.duplicate()
	var progress := ConfigFile.new()
	progress.load("user://progress.cfg")
	return progress.get_value("mp3", "unlocked", [])

## "stealth_points" or "kills" and the threshold for one mp3_unlocks entry.
static func unlock_rule(entry: Dictionary) -> Array:
	if entry.has("kills"):
		return ["kills", int(entry.kills)]
	return ["stealth", int(entry.get("stealth_points", 0))]

func earns(entry: Dictionary, stealth: int, kills: int) -> bool:
	var rule := unlock_rule(entry)
	return (kills if rule[0] == "kills" else stealth) >= int(rule[1])

## Tracks that finishing the current floor would unlock (shown on the floor report).
func preview_unlocks(floor_stealth: int, floor_kills := 0) -> Array:
	var names: Array = []
	var unlocked := unlocked_tracks()
	for entry in branch().get("mp3_unlocks", []):
		if earns(entry, total("stealth") + floor_stealth, total("kills") + floor_kills) and not unlocked.has(entry.track):
			names.append(entry.track.replace("_", " "))
	return names

func update_unlocks() -> Array:
	var earned: Array = []
	var unlocked := unlocked_tracks()
	for entry in branch().get("mp3_unlocks", []):
		if earns(entry, total("stealth"), total("kills")) and not unlocked.has(entry.track):
			unlocked.append(entry.track)
			earned.append(entry.track)
	if earned.is_empty():
		return earned
	if can_persist():
		var progress := ConfigFile.new()
		progress.load("user://progress.cfg")
		progress.set_value("mp3", "unlocked", unlocked)
		progress.save("user://progress.cfg")
	else:
		session_unlocks = unlocked
	return earned

## Level select: a player sees only the levels they have reached. Developers (editor runs,
## QA builds, or --dev) see all five; --player forces the player view for testing.
var session_level := 1

func dev_mode() -> bool:
	var args := OS.get_cmdline_user_args()
	if "--player" in args:
		return false
	return "--dev" in args or OS.has_feature("editor") or OS.has_feature("qa")

func highest_level() -> int:
	if dev_mode():
		return 5
	if not can_persist():
		return session_level
	var progress := ConfigFile.new()
	progress.load("user://progress.cfg")
	return clampi(int(progress.get_value("levels", "highest", 1)), 1, 5)

## Cleared floors get a check on level select (real progress, also in dev).
func level_completed(number: int) -> bool:
	if number >= 5:
		return game_completed() or (not can_persist() and session_level > 5)
	if not can_persist():
		return session_level > number
	var progress := ConfigFile.new()
	progress.load("user://progress.cfg")
	return int(progress.get_value("levels", "highest", 1)) > number

func level_unlocked(number: int) -> bool:
	return number <= highest_level()

func unlock_level(number: int) -> void:
	session_level = maxi(session_level, clampi(number, 1, 5))
	if not can_persist():
		return
	var progress := ConfigFile.new()
	progress.load("user://progress.cfg")
	if int(progress.get_value("levels", "highest", 1)) < number:
		progress.set_value("levels", "highest", clampi(number, 1, 5))
		progress.save("user://progress.cfg")

## Difficulty (Settings): Miro's health, blanket recharge, Level 5 wave size and how sharp
## the Keepers are. Medium is the authored balance; tests always run on Medium unless asked.
const DIFFICULTIES := {
	"easy": {"label": "Easy", "health": 5, "stealth_cooldown": 5.0, "stealth_duration": 6.0, "wave_extra": -1, "suspicion": 0.65, "sight": 140.0, "windup": 0.9, "attack_gap": 2.8, "chase": 66.0, "niro_health": 0.8},
	"medium": {"label": "Medium", "health": 3, "stealth_cooldown": 8.0, "stealth_duration": 5.0, "wave_extra": 0, "suspicion": 1.0, "sight": 165.0, "windup": 0.65, "attack_gap": 2.1, "chase": 78.0, "niro_health": 1.0},
	"hard": {"label": "Hard", "health": 2, "stealth_cooldown": 11.0, "stealth_duration": 4.0, "wave_extra": 1, "suspicion": 1.4, "sight": 190.0, "windup": 0.5, "attack_gap": 1.6, "chase": 88.0, "niro_health": 1.3},
}
var difficulty_override := ""

func difficulty() -> String:
	if not difficulty_override.is_empty():
		return difficulty_override
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--difficulty="):
			var chosen := argument.trim_prefix("--difficulty=")
			if DIFFICULTIES.has(chosen):
				return chosen
	if "--script" in OS.get_cmdline_args():
		return "medium"
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	var saved := str(config.get_value("game", "difficulty", "medium"))
	return saved if DIFFICULTIES.has(saved) else "medium"

func set_difficulty(id: String) -> void:
	if not DIFFICULTIES.has(id):
		return
	if not can_persist():
		difficulty_override = id
		return
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("game", "difficulty", id)
	config.save("user://settings.cfg")

func tuning() -> Dictionary:
	return DIFFICULTIES[difficulty()]

func complete_floor(number: int, sigil: bool, milestones: Dictionary, raw_stats: Dictionary = {}) -> void:
	floor_stats[number] = score_floor(raw_stats)
	unlock_level(number + 1)
	if sigil:
		completed_sigils[number] = true
	for key in milestones:
		narrative_milestones["%d:%s" % [number, key]] = milestones[key]
	if number == 5:
		boss_defeated = milestones.has("BrotherEncounter")
		ending_complete = milestones.has("ForestViewpoint")
