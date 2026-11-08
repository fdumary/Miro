extends Node
## Level 5 "The Foundation" encounter flow (Ethan, 7 Nov 2026):
## guitar pickup starts Shit Crashed and Miro is spotted; on each of three floors a wave
## enters on a bar line, then Niro appears, takes damage and retreats through a hatch;
## Robot Attack takes over for the third floor and the final fight on the deepest floor,
## where Niro is beaten but not killed.
## Hooks for cutscenes: the signals below fire at each story beat (see docs/CUTSCENE_HOOKS.md).
signal guitar_taken
signal wave_started(row: int)
signal wave_cleared(row: int)
signal niro_appeared(engagement: int)
signal niro_retreated(engagement: int)
signal final_fight_started

enum Step { OFFICE, WAVE_PENDING, WAVE, NIRO_PENDING, NIRO, DESCEND, FINAL_PENDING, FINAL, DONE }
var level: Node2D
var step := Step.OFFICE
var row := 0
var wave_guards: Array[Node] = []
var next_reinforcement := 0
var wait_left := 0.0
var niro_health := 12
var engagement := 0
## Niro's taunts over the remote while he is off screen, in authored order, on a bar line.
var taunt_index := 0
var taunt_wait := 0.0
const TAUNT_BARS := 6
const ROW_FLOOR_Y := [236.0, 432.0, 656.0, 852.0]
## Never wait more than one bar for a beat-synced event, and hold it at most this long without music.
const MAX_WAIT := 2.2

func setup(owner_level: Node2D) -> void:
	level = owner_level
	var config: Dictionary = level.definition.get("niro", {})
	niro_health = roundi(int(config.get("health", 12)) * float(campaign().tuning().niro_health))

func music() -> Node:
	return get_node("/root/MusicDirector")

func campaign() -> Node:
	return get_node("/root/Campaign")

func row_of(y: float) -> int:
	if y < 340:
		return 0
	if y < 560:
		return 1
	if y < 760:
		return 2
	return 3

func bar_wait() -> float:
	return minf(MAX_WAIT, music().seconds_to_next_bar()) if not music().track_id.is_empty() else 0.4

func on_guitar() -> void:
	if step != Step.OFFICE:
		return
	level.player.controls.collect_guitar()
	music().guitar_section()
	get_node("/root/SoundFX").play_sound("gate", -12)
	level.notify("An alarm. They know exactly where you are. [6] Guitar: click to strum.", 7)
	guitar_taken.emit()
	level.show_card("alarm", "", "", "", Color.RED, 2.4)
	request_wave(0)

func request_wave(index: int) -> void:
	row = index
	step = Step.WAVE_PENDING
	wait_left = bar_wait()

func spawn_wave() -> void:
	var waves: Array = level.definition.get("waves", [])
	if row >= waves.size():
		step = Step.NIRO_PENDING
		wait_left = bar_wait()
		return
	var wave: Dictionary = waves[row]
	var points: Array = wave.spawn.duplicate()
	var weapons: Array = wave.weapons.duplicate()
	# HUNTED: one extra armed Keeper per wave.
	if campaign().reputation() == "HUNTED":
		points.append([points[0][0] + 60, points[0][1]])
		weapons.append("smg")
	# Difficulty: Easy drops a Keeper from each wave (never below one), Hard adds an armed one.
	var extra := int(campaign().tuning().wave_extra)
	if extra < 0:
		points = points.slice(0, maxi(1, points.size() + extra))
	for added in range(maxi(0, extra)):
		points.append([points[0][0] - 60 - added * 40, points[0][1]])
		weapons.append("smg")
	wave_guards.clear()
	for index in range(points.size()):
		var point := Vector2(points[index][0], points[index][1])
		# Never drop a Keeper on top of Miro.
		if absf(point.x - level.player.position.x) < 90:
			point.x = clampf(point.x + (160 if point.x >= level.player.position.x else -160), 80, 1040)
		wave_guards.append(spawn_guard(point, weapons[index % weapons.size()]))
	step = Step.WAVE
	wave_started.emit(row)
	level.notify("Keepers are coming down the stairs.", 4)

func spawn_guard(point: Vector2, weapon: String) -> Node:
	var guard = load("res://scenes/guard.tscn").instantiate()
	guard.position = point
	guard.patrol_left = point.x - 80
	guard.patrol_right = point.x + 80
	guard.level = level
	guard.illness_started = true
	guard.wave_guard = true
	guard.weapon_kind = weapon
	level.world_features.name_keeper(guard, 5, next_reinforcement)
	next_reinforcement += 1
	level.get_node("Guards").add_child(guard)
	# Discovery is forced in The Foundation: every wave arrives already hunting Miro.
	guard.alert_state = IntroGuard.State.SEARCH
	guard.last_known_position = level.player.global_position
	guard.search_left = 30.0
	guard.facing = signf(level.player.position.x - point.x)
	return guard

func wave_clear() -> bool:
	return wave_guards.all(func(guard): return not is_instance_valid(guard) or guard.is_dead or guard.asleep)

func spawn_niro() -> void:
	engagement += 1
	var boss = load("res://scenes/brother_boss.tscn").instantiate()
	boss.engagement = engagement if engagement <= 3 else 4
	boss.start_health = niro_health
	boss.level = level
	var side := 1.0 if level.player.position.x < 560 else -1.0
	boss.position = Vector2(clampf(level.player.position.x + side * 150, 90, 1030), ROW_FLOOR_Y[mini(row, 3)] - 4)
	boss.retreated.connect(_on_niro_gone)
	level.add_child(boss)
	level.brother = boss
	step = Step.NIRO if engagement <= 3 else Step.FINAL
	niro_appeared.emit(engagement)
	if engagement == 1:
		level.show_card("name", "", "NIRO", "", Color("c69fa5"), 3.0)
	var lines := appearance_lines(engagement)
	if not lines.is_empty():
		level.start_dialogue(lines, "niro_%d" % engagement)

func appearance_lines(index: int) -> Array:
	var lines: Array = []
	if index == 1:
		for station in level.definition.stations:
			if station.id == "FinalOffer":
				lines = station.lines.duplicate(true)
	elif index == 4:
		for station in level.definition.stations:
			if station.id == "BrotherEncounter":
				lines = station.lines.duplicate(true)
		lines.insert(0, ["NIRO", campaign().branch_line("boss_prefight")])
	else:
		lines = level.definition.get("niro", {}).get("appear_lines", {}).get(str(index), []).duplicate(true)
	return lines

func on_dialogue_finished(event: String) -> void:
	if event == "niro_1":
		level.milestones["FinalOffer"] = true
		final_station_redraw("FinalOffer")

func niro_retreating(index: int) -> void:
	var line: String = level.definition.get("niro", {}).get("retreat_lines", {}).get(str(index), "")
	if not line.is_empty():
		level.world_features.remote_say(line, "NIRO", level.brother)

func _on_niro_gone(index: int) -> void:
	if is_instance_valid(level.brother):
		niro_health = level.brother.health
	level.milestones["NiroRetreat%d" % index] = true
	for gate in level.get_node("Gates").get_children():
		if gate.unlock_milestone == "NiroRetreat%d" % index:
			gate.unlock()
	step = Step.DESCEND
	niro_retreated.emit(index)
	# Give him a couple of bars to get out of sight before the first taunt.
	taunt_wait = maxf(taunt_wait, music().seconds_per_bar() * 2)
	level.notify("A hatch opens below. He went down.", 5)

func niro_calls_guard(point: Vector2) -> void:
	var side := -1.0 if level.player.position.x < point.x else 1.0
	var guard = spawn_guard(Vector2(clampf(point.x - side * 220, 80, 1040), ROW_FLOOR_Y[mini(row, 3)]), "pistol")
	wave_guards.append(guard)
	level.notify("Niro calls a Keeper in.", 2.5)

func final_station_redraw(id: String) -> void:
	var node = level.areas.get_node_or_null(NodePath(id))
	if node:
		node.activated = true
		node.queue_redraw()

func niro_on_screen() -> bool:
	if not is_instance_valid(level.brother) or level.brother.is_dead:
		return false
	var view := level.get_viewport_rect()
	var point: Vector2 = level.brother.get_global_transform_with_canvas().origin
	return view.grow(-12).has_point(point)

## After the reveal he never really leaves: when he's out of sight, his voice comes through the remote.
func update_taunts(delta: float) -> void:
	var taunts: Array = level.definition.get("niro", {}).get("taunts", [])
	if taunts.is_empty() or engagement < 1 or step == Step.DONE or niro_on_screen():
		return
	if level.world_features.remote_busy():
		return
	taunt_wait -= delta
	if taunt_wait > 0:
		return
	# Land the line on a bar line, like everything else down here.
	if music().bpm() > 0 and music().seconds_to_next_bar() > 0.08:
		return
	var line: String = taunts[taunt_index % taunts.size()]
	taunt_index += 1
	level.world_features.remote_say(line)
	taunt_wait = music().seconds_per_bar() * TAUNT_BARS if music().bpm() > 0 else 12.0

func _process(delta: float) -> void:
	if not is_instance_valid(level) or level.controls_locked() or level.player.is_dead:
		return
	update_taunts(delta)
	match step:
		Step.WAVE_PENDING:
			wait_left -= delta
			if wait_left <= 0:
				spawn_wave()
		Step.WAVE:
			if wave_clear():
				wave_cleared.emit(row)
				step = Step.NIRO_PENDING
				wait_left = bar_wait()
		Step.NIRO_PENDING:
			wait_left -= delta
			if wait_left <= 0:
				spawn_niro()
		Step.DESCEND:
			var current := row_of(level.player.position.y)
			if current > row and level.player.is_on_floor():
				if current == 2:
					# Second half of the level: Robot Attack leads into the final fight.
					music().second_section(5)
				if current >= 3:
					row = 3
					step = Step.FINAL_PENDING
					wait_left = bar_wait()
					final_fight_started.emit()
				else:
					request_wave(current)
		Step.FINAL_PENDING:
			wait_left -= delta
			if wait_left <= 0:
				spawn_niro()

func objective() -> String:
	match step:
		Step.OFFICE:
			return ""
		Step.WAVE_PENDING, Step.WAVE:
			return "05 / THE FOUNDATION\nSurvive the Keepers. Strum [6] to put them to sleep."
		Step.NIRO_PENDING, Step.NIRO:
			return "05 / THE FOUNDATION\nFace Niro. Hit him while he recovers."
		Step.DESCEND:
			return "05 / THE FOUNDATION\nFollow him down through the open hatch."
		Step.FINAL_PENDING, Step.FINAL:
			return "05 / THE FOUNDATION\nThe deepest floor. Face Niro."
	return ""

func hint_step() -> String:
	match step:
		Step.WAVE_PENDING, Step.WAVE:
			return "wave"
		Step.NIRO_PENDING, Step.NIRO:
			return "niro"
		Step.DESCEND:
			return "descend"
		Step.FINAL_PENDING, Step.FINAL:
			return "final"
	return ""

func niro_fight_hint() -> String:
	return "[1] Shank or [6] strum during RECOVER • [C] Dodge • Space Jump"
