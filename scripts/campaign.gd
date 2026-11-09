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
## The last storey checkpoint on the floor being played: {floor, storey, position, milestones, sigil}.
## Retrying (Backspace) restores it; entering a floor from elsewhere or finishing it clears it.
var checkpoint := {}
# Records the run origin for snapshots; ending completion is saved for resumed runs too.
var played_from_start := false
## Committed per-floor results: {floor: {kills, detections, stealth, offense}}. Written only by
## complete_floor(), so a retry restores the state at floor entry.
var floor_stats: Dictionary = {}
var branch_data: Dictionary = {}
## Which start-menu screen to open next (the pause menu's "Level select" sets "levels").
var menu_screen := ""

var difficulty_tuning = {
	"easy": {
		"health": 5,
		"blanket_cooldown": 6.0,
		"blanket_duration": 7.0,
		"suspicion_rate": 1.5,
		"sight_range": 140,
		"attack_speed": 1.0,
		"niro_health": 1.0,
		"drop_rate": 1.2
	},
	"medium": {
		"health": 3,
		"blanket_cooldown": 8.0,
		"blanket_duration": 5.0,
		"suspicion_rate": 2.5,
		"sight_range": 165,
		"attack_speed": 1.0,
		"niro_health": 1.2,
		"drop_rate": 1.0
	},
	"hard": {
		"health": 2,
		"blanket_cooldown": 10.0,
		"blanket_duration": 4.0,
		"suspicion_rate": 3.5,
		"sight_range": 180,
		"attack_speed": 1.2,
		"niro_health": 1.5,
		"drop_rate": 0.8
	},
	"super_hard": {
		"health": 1,
		"blanket_cooldown": 12.0,
		"blanket_duration": 3.0,
		"suspicion_rate": 5.0,
		"sight_range": 200,
		"attack_speed": 1.5,
		"niro_health": 2.0,
		"drop_rate": 0.5
	}
}

func launch_floor() -> int:
	if launch_consumed:
		return 1
	launch_consumed = true
	if OS.has_feature("qa") and "--verify-playthrough" in OS.get_cmdline_user_args():
		var runner = load("res://tools/export_playthrough.gd").new()
		get_tree().root.call_deferred("add_child", runner)
	for argument in OS.get_cmdline_user_args():
		if dev_mode() and argument.begins_with("--level="):
			return clampi(argument.trim_prefix("--level=").to_int(), 1, 5)
	return 1

func enter_floor(number: int) -> void:
	if int(checkpoint.get("floor", 0)) != number:
		checkpoint.clear()
	if number == 1:
		carried_kit = {}
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
	save_floor_snapshot(number)

## Level select resumes a floor from the state the player had when they first reached it:
## MP3 ownership and unlock, inventory order, earlier floors' results (which pick the
## MISSING/HUNTED branch), story milestones and Miro's play-style profile. Snapshots live in
## memory for the session and, in player mode, in user://progress.cfg so they survive a relaunch.
var floor_snapshots: Dictionary = {}

func save_floor_snapshot(number: int) -> void:
	if number <= 1:
		return
	var behavior = get_node_or_null("/root/PlayerBehavior")
	var committed: Dictionary = {}
	var choices: Dictionary = {}
	if behavior != null:
		for key in behavior.committed:
			if int(key) < number:
				committed[key] = behavior.committed[key]
		for id in behavior.choices:
			if int(str(id).get_slice("_", 0).trim_prefix("l")) < number:
				choices[id] = behavior.choices[id]
	var snapshot := {
		"remote_owned": remote_owned,
		"remote_unlocked": remote_unlocked,
		"inventory_layout": Array(inventory_layout.duplicate()),
		"floor_stats": floor_stats.duplicate(true),
		"completed_sigils": completed_sigils.duplicate(),
		"narrative_milestones": narrative_milestones.duplicate(),
		"played_from_start": played_from_start,
		"behavior_committed": committed,
		"behavior_choices": choices,
		"behavior_last_selected": behavior.last_selected if behavior != null else "neutral",
	}
	floor_snapshots[number] = snapshot
	if not can_persist():
		return
	var progress := ConfigFile.new()
	progress.load(progress_path())
	progress.set_value("snapshots", "floor_%d" % number, snapshot)
	progress.save(progress_path())

func floor_snapshot(number: int) -> Dictionary:
	if floor_snapshots.has(number):
		return floor_snapshots[number]
	if not can_persist():
		return {}
	var progress := ConfigFile.new()
	progress.load(progress_path())
	var saved = progress.get_value("snapshots", "floor_%d" % number, {})
	return saved if saved is Dictionary else {}

## Puts the run back the way it was when the player first entered `number`. A floor with no
## snapshot (an older save, or a dev jump) starts fresh: no MP3, neutral branch.
func restore_floor_snapshot(number: int) -> bool:
	var snapshot := floor_snapshot(number)
	remote_owned = bool(snapshot.get("remote_owned", false))
	remote_unlocked = bool(snapshot.get("remote_unlocked", false))
	if snapshot.has("inventory_layout"):
		inventory_layout.assign(snapshot.inventory_layout)
	floor_stats = Dictionary(snapshot.get("floor_stats", {})).duplicate(true)
	completed_sigils = Dictionary(snapshot.get("completed_sigils", {})).duplicate()
	narrative_milestones = Dictionary(snapshot.get("narrative_milestones", {})).duplicate()
	played_from_start = bool(snapshot.get("played_from_start", false))
	var behavior = get_node_or_null("/root/PlayerBehavior")
	if behavior != null:
		behavior.committed = Dictionary(snapshot.get("behavior_committed", {})).duplicate(true)
		behavior.choices = Dictionary(snapshot.get("behavior_choices", {})).duplicate()
		behavior.last_selected = str(snapshot.get("behavior_last_selected", "neutral"))
	return not snapshot.is_empty()

func progress_path() -> String:
	return "user://progress.cfg"

func game_completed() -> bool:
	var progress := ConfigFile.new()
	progress.load(progress_path())
	return bool(progress.get_value("game", "completed", false))

## Editor/dev reviews, tests and QA exports never write the player's progress.
func can_persist() -> bool:
	return not dev_mode() and not OS.has_feature("qa") and not "--script" in OS.get_cmdline_args()

func mark_game_completed() -> void:
	if not can_persist():
		return
	var progress := ConfigFile.new()
	progress.load(progress_path())
	progress.set_value("game", "completed", true)
	progress.save(progress_path())

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

## Achievements (easter eggs): saved in progress.cfg, kept in memory for test runs.
var achievements_earned: Dictionary = {}

func has_achievement(id: String) -> bool:
	if not can_persist():
		return achievements_earned.has(id)
	var progress := ConfigFile.new()
	progress.load(progress_path())
	return Array(progress.get_value("achievements", "earned", [])).has(id)

## True the first time only.
func unlock_achievement(id: String) -> bool:
	if has_achievement(id):
		return false
	achievements_earned[id] = true
	if can_persist():
		var progress := ConfigFile.new()
		progress.load(progress_path())
		var earned: Array = Array(progress.get_value("achievements", "earned", []))
		earned.append(id)
		progress.set_value("achievements", "earned", earned)
		progress.save(progress_path())
	return true

## A secret beat (the Foreva note) goes onto the MP3 for good.
func add_track_unlock(track: String) -> void:
	var tracks := stored_unlocks()
	if tracks.has(track):
		return
	tracks.append(track)
	if can_persist():
		var progress := ConfigFile.new()
		progress.load(progress_path())
		progress.set_value("mp3", "unlocked", tracks)
		progress.save(progress_path())
	else:
		session_unlocks = tracks

## Hot Shit is the final boss track: Level 5's second half, never a stealth or kill unlock.
func unlocked_tracks() -> Array:
	var tracks := stored_unlocks()
	tracks.erase("hot_shit")
	return tracks

func stored_unlocks() -> Array:
	if not can_persist():
		return session_unlocks.duplicate()
	var progress := ConfigFile.new()
	progress.load(progress_path())
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

## Beats earned when the last floor ended; the next floor announces them once.
var fresh_unlocks: Array = []
## What Miro is carrying when a floor ends: guns, ammo, C4, tonics. The next floor hands it back.
var carried_kit: Dictionary = {}
var carried_from := 0

func update_unlocks() -> Array:
	var earned: Array = []
	var unlocked := unlocked_tracks()
	for entry in branch().get("mp3_unlocks", []):
		if earns(entry, total("stealth"), total("kills")) and not unlocked.has(entry.track):
			unlocked.append(entry.track)
			earned.append(entry.track)
	if not earned.is_empty():
		fresh_unlocks = earned.duplicate()
	if earned.is_empty():
		return earned
	if can_persist():
		var progress := ConfigFile.new()
		progress.load(progress_path())
		progress.set_value("mp3", "unlocked", unlocked)
		progress.save(progress_path())
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
	progress.load(progress_path())
	return clampi(int(progress.get_value("levels", "highest", 1)), 1, 5)

## Cleared floors get a check on level select (real progress, also in dev).
func level_completed(number: int) -> bool:
	if number >= 5:
		return game_completed() or (not can_persist() and session_level > 5)
	if not can_persist():
		return session_level > number
	var progress := ConfigFile.new()
	progress.load(progress_path())
	return int(progress.get_value("levels", "highest", 1)) > number

func level_unlocked(number: int) -> bool:
	return number <= highest_level()

func unlock_level(number: int) -> void:
	session_level = maxi(session_level, clampi(number, 1, 5))
	if not can_persist():
		return
	var progress := ConfigFile.new()
	progress.load(progress_path())
	if int(progress.get_value("levels", "highest", 1)) < number:
		progress.set_value("levels", "highest", clampi(number, 1, 5))
		progress.save(progress_path())

## Difficulty (Settings): Miro's health, blanket recharge, Level 5 wave size and how sharp
## the Keepers are. Medium is the authored balance; tests always run on Medium unless asked.
const DIFFICULTIES := {
	"easy": {"label": "Easy", "health": 10, "stealth_cooldown": 5.0, "stealth_duration": 6.0, "wave_extra": -1, "suspicion": 0.65, "sight": 140.0, "windup": 0.9, "attack_gap": 2.8, "chase": 66.0, "niro_health": 0.8},
	"medium": {"label": "Medium", "health": 6, "stealth_cooldown": 8.0, "stealth_duration": 5.0, "wave_extra": 0, "suspicion": 1.0, "sight": 165.0, "windup": 0.65, "attack_gap": 2.1, "chase": 78.0, "niro_health": 1.0},
	"hard": {"label": "Hard", "health": 4, "stealth_cooldown": 11.0, "stealth_duration": 4.0, "wave_extra": 1, "suspicion": 1.4, "sight": 190.0, "windup": 0.5, "attack_gap": 1.6, "chase": 88.0, "niro_health": 1.3},
	"super_hard": {"label": "Super Hard", "health": 2, "stealth_cooldown": 12.0, "stealth_duration": 3.0, "wave_extra": 2, "suspicion": 2.0, "sight": 210.0, "windup": 0.4, "attack_gap": 1.2, "chase": 95.0, "niro_health": 2.0},
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

## Checkpoints survive closing the game (player mode): picking the floor from level select
## resumes from its last storey.
func save_checkpoint() -> void:
	if not can_persist():
		return
	var progress := ConfigFile.new()
	progress.load(progress_path())
	progress.set_value("checkpoint", "data", checkpoint.duplicate(true))
	progress.save(progress_path())

func saved_checkpoint(number: int) -> Dictionary:
	if int(checkpoint.get("floor", 0)) == number:
		return checkpoint
	if not can_persist():
		return {}
	var progress := ConfigFile.new()
	progress.load(progress_path())
	var data = progress.get_value("checkpoint", "data", {})
	return data if data is Dictionary and int(data.get("floor", 0)) == number else {}

func complete_floor(number: int, sigil: bool, milestones: Dictionary, raw_stats: Dictionary = {}) -> void:
	checkpoint.clear()
	save_checkpoint()
	floor_stats[number] = score_floor(raw_stats)
	unlock_level(number + 1)
	if sigil:
		completed_sigils[number] = true
	for key in milestones:
		narrative_milestones["%d:%s" % [number, key]] = milestones[key]
	if number == 5:
		boss_defeated = milestones.has("BrotherEncounter")
		ending_complete = milestones.has("ForestViewpoint")
		if ending_complete:
			mark_game_completed()
