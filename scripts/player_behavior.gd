extends Node
## Miro's inner conflict, as a descriptive play-style profile (docs/INNER_CONFLICT.md, artspec.md §4).
## Five leanings, never a morality meter and never a change to the plot:
##   quiet side: ghost (unseen), blackhat (turns the tower's eyes), seeker (reads, looks, asks)
##   loud side:  defiant (fights when he could hide), survivor (gets caught and lives anyway)
## Scores come from real play (stealth, kills, cameras, near misses, reading) and from Miro's
## two-option replies (data/dialogue_choices.json). A floor's score only counts once that floor
## is completed (Campaign.floor_stats), so a retry restores the entry state like the rest of the run.
## The autoload attaches scripts/inner_conflict.gd to each level scene; the levels need no hooks.

signal behavior_changed

const BRANCHES := ["ghost", "blackhat", "defiant", "survivor", "seeker"]
const QUIET := ["ghost", "blackhat", "seeker"]

## {floor: {branch: points}} for completed floors only.
var committed: Dictionary = {}
## The floor being played and what it has earned so far (lost on retry).
var pending_floor := 0
var pending_scores: Dictionary = {}
var pending_events: Dictionary = {}
var pending_caps: Dictionary = {}
var pending_log: Array[String] = []
## Choices Miro made this run: {choice_id: option index}. Committed with the floor.
var choices: Dictionary = {}
var pending_choices: Dictionary = {}
## The last non-neutral branch an art checkpoint picked, kept on ties (artspec §4.3 step 4).
var last_selected := "neutral"
var tracked_scene: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var campaign = get_node_or_null("/root/Campaign")
	if campaign == null:
		return
	# A floor counts once Campaign commits it (descending, or the ending on Level 5).
	if pending_floor > 0 and not committed.has(pending_floor) and campaign.floor_stats.has(pending_floor):
		commit_floor(pending_floor, campaign.floor_stats[pending_floor])
	var scene := get_tree().current_scene
	if scene != tracked_scene and is_instance_valid(scene) and scene.has_method("start_dialogue") and scene.get("player") != null:
		tracked_scene = scene
		begin_floor(int(campaign.current_floor))
		var director := Node.new()
		director.set_script(load("res://scripts/inner_conflict.gd"))
		director.name = "InnerConflict"
		scene.add_child(director)

## Entering (or retrying) a floor drops anything earned on it or below it, like Campaign.enter_floor.
func begin_floor(number: int) -> void:
	for floor_number in committed.keys():
		if int(floor_number) >= number:
			committed.erase(floor_number)
	for id in choices.keys():
		if int(str(id).get_slice("_", 0).trim_prefix("l")) >= number:
			choices.erase(id)
	if number <= 1:
		committed.clear()
		choices.clear()
		last_selected = "neutral"
	pending_floor = number
	pending_scores = {}
	pending_events = {}
	pending_caps = {}
	pending_log = []
	pending_choices = {}
	behavior_changed.emit()

## Adds points for one unique event. Returns false when the event already scored or its cap is full.
func record(event_id: String, branch: String, points: int, cap_key := "", cap := 0) -> bool:
	if pending_events.has(event_id) or not branch in BRANCHES or points == 0:
		return false
	if cap > 0:
		var used := int(pending_caps.get(cap_key, 0))
		if used >= cap:
			return false
		pending_caps[cap_key] = used + 1
	pending_events[event_id] = true
	pending_scores[branch] = int(pending_scores.get(branch, 0)) + points
	var reason := "%s +%d (%s)" % [branch, points, event_id]
	pending_log.append(reason)
	if OS.is_debug_build():
		print("INNER_CONFLICT: ", reason)
	behavior_changed.emit()
	return true

## A two-option reply. Each option names the leanings it feeds (data/dialogue_choices.json).
func record_choice(choice_id: String, option_index: int, lean: Dictionary) -> void:
	pending_choices[choice_id] = option_index
	for branch in lean:
		record("choice:%s:%s" % [choice_id, branch], str(branch), int(lean[branch]), "choice_" + str(branch), 2)

## Folds the floor's committed raw stats in (artspec §4.2), then the live events.
func commit_floor(number: int, stats: Dictionary) -> void:
	if int(stats.get("detections", 0)) == 0:
		record("floor_unseen", "ghost", 3)
	for index in range(int(stats.get("stealth_bonus", 0))):
		record("unseen_bonus_%d" % index, "ghost", 1, "unseen_bonus", 3)
	for index in range(int(stats.get("kills", 0))):
		record("kill_%d" % index, "defiant", 2, "kill", 2)
	if int(stats.get("loud", 0)) > 0:
		record("loud_breach", "defiant", 2)
	committed[number] = pending_scores.duplicate()
	for id in pending_choices:
		choices[id] = pending_choices[id]
	behavior_changed.emit()

func totals(include_pending := false) -> Dictionary:
	var result := {}
	for branch in BRANCHES:
		result[branch] = 0
	for floor_number in committed:
		for branch in committed[floor_number]:
			result[branch] += int(committed[floor_number][branch])
	if include_pending and not committed.has(pending_floor):
		for branch in pending_scores:
			result[branch] += int(pending_scores[branch])
	return result

## Art checkpoint (artspec §4.3): a unique leader wins; a tie keeps the previous pick if it is
## tied for first, otherwise neutral. No signal at all is neutral.
func select_branch(include_pending := false) -> String:
	var scores := totals(include_pending)
	var best := 0
	for branch in BRANCHES:
		best = maxi(best, int(scores[branch]))
	if best == 0:
		return "neutral"
	var leaders: Array = BRANCHES.filter(func(branch): return int(scores[branch]) == best)
	var pick := "neutral"
	if leaders.size() == 1:
		pick = leaders[0]
	elif last_selected in leaders:
		pick = last_selected
	if pick != "neutral":
		last_selected = pick
	return pick

## The two sides of Miro: "quiet" (hide, watch, ask) or "loud" (fight, endure). Used to pick
## Bible verses in guard chatter; "torn" when they are level.
func side(include_pending := true) -> String:
	var scores := totals(include_pending)
	var quiet := 0
	var loud := 0
	for branch in BRANCHES:
		if branch in QUIET:
			quiet += int(scores[branch])
		else:
			loud += int(scores[branch])
	if quiet == loud:
		return "torn"
	return "quiet" if quiet > loud else "loud"

## One line of original copy for an ending panel (artspec §6). Optional; cutscenes may use it.
func ending_line() -> String:
	var lines := {"ghost": "They never saw him leave.", "blackhat": "He learned who was watching.", "defiant": "He would not kneel.", "survivor": "He remained.", "seeker": "He left with questions.", "neutral": "The walls kept their secrets."}
	return lines[select_branch(true)]

func debug_text() -> String:
	var scores := totals(true)
	var parts: Array[String] = []
	for branch in BRANCHES:
		parts.append("%s %d" % [branch, int(scores[branch])])
	return "INNER CONFLICT  " + "  ".join(parts) + "\nleaning: %s · side: %s" % [select_branch_preview(), side()]

## Same rule as select_branch, without moving the tie memory.
func select_branch_preview() -> String:
	var keep := last_selected
	var pick := select_branch(true)
	last_selected = keep
	return pick
