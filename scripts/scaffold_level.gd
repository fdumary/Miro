extends "res://scripts/intro_level.gd"
## Playable blockout controller. Milestones stand in for unfinished set pieces.
var definition: Dictionary
var milestones: Dictionary = {}
var pending_milestone: String = ""
var connected_cameras: Array[Node] = []
var hack_remaining := 0.0
var floor_alerts := 0
var watcher_reserves_called := false
const HAZARD_ROTATIONS := {"floor": 0.0, "ceiling": PI, "left": -PI / 2, "right": PI / 2}
var brother: Node
var cinematic: Control
## Level 5 only: guitar, waves and Niro's three retreats (scripts/foundation_flow.gd).
var flow: Node
## Branch reaction for this floor (Level 2 onward): MISSING or HUNTED, from committed floors.
var reputation := ""
var hunted := false
var disappointment_heard := false
var poster: Node2D

func _ready() -> void:
	definition = JSON.parse_string(FileAccess.get_file_as_string(get_meta("blueprint")))
	get_node("/root/Campaign").enter_floor(int(definition.number))
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_inputs()
	player.level = self
	player.position = $LevelPlan/PlayerSpawn.position
	# Camera and out-of-world limits follow the blueprint (Level 5 is deeper than the others).
	player.get_node("Camera2D").limit_right = int(definition.world_size[0])
	player.get_node("Camera2D").limit_bottom = int(definition.world_size[1])
	player.has_supplies = true
	player.c4_count = int(definition.get("demolition_charges", 1)) + 1 # One optional charge; story supports stay reserved.
	door_open = true
	brother_heard = true
	for guard in guards():
		guard.level = self
		guard.illness_started = true
	build_hud()
	apply_difficulty()
	setup_world_features(int(definition.number))
	player.controls.has_remote = get_node("/root/Campaign").remote_owned
	player.controls.remote_unlocked = get_node("/root/Campaign").remote_unlocked
	var authored: Dictionary = definition.get("features", {})
	if authored.has("cameras"):
		# Linked cameras go dark when the checkpoint terminal is reprogrammed; the rest keep sweeping.
		for entry in authored.cameras:
			var camera = load("res://scenes/security_camera.tscn").instantiate()
			camera.position = Vector2(entry.position[0], entry.position[1])
			camera.facing_angle = float(entry.get("facing", 1.57))
			camera.level = self
			add_child(camera)
			if entry.get("linked", false):
				connected_cameras.append(camera)
			elif int(definition.number) == 2 and world_features.practice_camera == null:
				# Level 2's camera is the practice one: the service port's remote hack turns it off.
				world_features.practice_camera = camera
	elif int(definition.number) == 3:
		for point in [Vector2(450, 180), Vector2(820, 370)]:
			var camera = load("res://scenes/security_camera.tscn").instantiate()
			camera.position = point
			camera.level = self
			add_child(camera)
			connected_cameras.append(camera)
	for entry in authored.get("hazards", []):
		var hazard := Area2D.new()
		hazard.set_script(preload("res://scripts/tower_hazard.gd"))
		hazard.level = self
		hazard.kind = str(entry.kind)
		hazard.position = Vector2(entry.position[0], entry.position[1])
		hazard.rotation = HAZARD_ROTATIONS.get(entry.get("mount", "floor"), 0.0)
		add_child(hazard)
	if int(definition.number) == 5:
		flow = Node.new()
		flow.set_script(load("res://scripts/foundation_flow.gd"))
		flow.name = "FoundationFlow"
		add_child(flow)
		flow.setup(self)
	# The floor's opening is Miro thinking it through: his thoughts are the game's cues.
	var opening: Array = [["MIRO", definition.opening, "thought"]]
	opening.append_array(setup_branch())
	start_dialogue(opening)
	var accents := {2: Color("c69fa5"), 3: Color("8bb5c9"), 4: Color("d8e3ea"), 5: Color("f2d3ab")}
	var report: String = get_node("/root/Campaign").branch()[reputation].report if int(definition.number) > 2 else ""
	show_card("floor", "%02d" % int(definition.number), str(definition.title).to_upper(), report, accents.get(int(definition.number), Color("c69fa5")))

func _process(delta: float) -> void:
	super._process(delta)
	if not controls_locked() and definition.has("music_region"):
		var entry: Dictionary = definition.music_region.entry
		var in_region := player.position.x >= float(entry.get("minimum_x", -INF)) and player.position.y >= float(entry.get("minimum_y", -INF)) and player.position.y <= float(entry.get("maximum_y", INF))
		var ready_milestone := not entry.has("requires_milestone") or milestones.has(entry.requires_milestone)
		if in_region and ready_milestone and (not entry.get("requires_landing", true) or player.is_on_floor()):
			get_node("/root/MusicDirector").second_section(int(definition.number))
	if hack_remaining > 0 and not controls_locked():
		if player.is_dead or player.global_position.distance_to(areas.get_node("RemoteTerminal").global_position) >= 48:
			hack_remaining = 0
			notify("Reprogramming interrupted. Stay beside the terminal for one second.")
		else:
			hack_remaining = maxf(0, hack_remaining - delta)
			if hack_remaining == 0:
				for camera in connected_cameras:
					camera.disable()
				pending_milestone = "RemoteTerminal"
				start_dialogue([["MIRO", "The cameras went dark. The checkpoint is blind now.", "thought"]], "milestone")
	if completed:
		overlay_label.text = "%s\n\n%s\n\n%s\n\n[Backspace] Retry   [Enter] Descend" % [definition.title.to_upper(), definition.closing, floor_report()]
		if int(definition.number) == 5:
			overlay_label.text = "MIRO\n\nThe end.\n\n[Backspace] Replay final floor   [Enter] New run"

func _unhandled_input(event: InputEvent) -> void:
	if completed and event.is_action_pressed("advance") and not event.is_echo():
		get_node("/root/Campaign").complete_floor(int(definition.number), sigil_placed, milestones, floor_raw_stats())
		get_node("/root/Campaign").update_unlocks()
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/levels/level_%02d.tscn" % (int(definition.number) + 1) if definition.number < 5 else "res://scenes/intro.tscn")
		return
	super._unhandled_input(event)

## World reacts to how Miro has played so far; never changes objectives or the plot.
func setup_branch() -> Array:
	var campaign = get_node("/root/Campaign")
	var number := int(definition.number)
	reputation = campaign.reputation()
	hunted = reputation == "HUNTED"
	var data: Dictionary = campaign.branch()[reputation]
	world_features.thoughts[str(number)].insert(0, {"id": "branch", "text": data.thought})
	poster = Node2D.new()
	poster.set_script(load("res://scripts/wanted_poster.gd"))
	poster.wanted = hunted
	poster.position = $LevelPlan/PlayerSpawn.position + Vector2(70, -46)
	add_child(poster)
	if not world_features.conversation.is_empty():
		world_features.conversation = world_features.conversation.duplicate(true)
		for index in range(data.guard_line.size()):
			world_features.conversation.append({"id": "branch_%s_%d" % [reputation.to_lower(), index], "speaker": index % 2, "text": data.guard_line[index]})
	if hunted and number < 5:
		# More armed Keepers: one extra patrol by the stair gate, clear of the ladder landings.
		var extra = load("res://scenes/guard.tscn").instantiate()
		extra.name = "HuntedKeeper"
		var spot = definition.get("features", {}).get("hunted_guard")
		extra.position = Vector2(spot.position[0], spot.position[1]) if spot != null else Vector2(700, 656)
		extra.patrol_left = spot.patrol[0] if spot != null else 640.0
		extra.patrol_right = spot.patrol[1] if spot != null else 760.0
		extra.level = self
		extra.illness_started = true
		extra.weapon_kind = "pistol"
		world_features.assign_keeper(extra, world_features.roster.hunted[str(number)])
		$Guards.add_child(extra)
	var lines: Array = [["TOWER PA", data.pa]]
	if number < 5:
		lines.append(["THE VOICE" if number < 3 else "NIRO", data.remote_call])
	return lines

## Kills cost: Niro's disappointment over the remote (once per floor) on top of noise and bodies.
func on_keeper_killed(_guard) -> void:
	if disappointment_heard or int(definition.number) >= 5:
		return
	disappointment_heard = true
	var lines: Array = get_node("/root/Campaign").branch().kill_disappointment
	world_features.remote_say(lines[(int(definition.number) + player.casualty_count) % lines.size()], "NIRO" if int(definition.number) >= 3 else "THE VOICE")

func floor_report() -> String:
	var campaign = get_node("/root/Campaign")
	var raw := floor_raw_stats()
	var scored: Dictionary = campaign.score_floor(raw)
	var text := "%s   ·   Kills %d   ·   Seen %d" % [campaign.style_word(raw), raw.kills, raw.detections]
	var unlocks: Array = campaign.preview_unlocks(int(scored.stealth), int(raw.kills))
	if not unlocks.is_empty():
		text += "\nMP3 unlocked: " + ", ".join(unlocks)
	return text

func counts_detection() -> bool:
	# In The Foundation discovery is forced after the guitar; only earlier sightings count.
	return flow == null or flow.step == flow.Step.OFFICE

func objective() -> String:
	if flow != null and not flow.objective().is_empty():
		var text: String = flow.objective()
		if not milestones.has("FinalSigil"):
			text += " · final sigil not yet placed"
		return text
	for station in definition.stations:
		if flow != null and station.id in ["FinalOffer", "BrotherEncounter"] and not milestones.has(station.id):
			continue
		if not milestones.has(station.id) and station.requires.all(func(required): return milestones.has(required)):
			return "%02d / %s\n%s" % [int(definition.number), definition.title.to_upper(), station.objective]
	return "%s\nReach the stair gate. [E]" % definition.title

## Z hints come from the blueprint ("hints", keyed by station id, "exit", or L5's flow step).
func hint_key() -> String:
	if flow != null and not flow.objective().is_empty():
		return "flow_" + flow.hint_step()
	for station in definition.stations:
		if flow != null and station.id in ["FinalOffer", "BrotherEncounter"] and not milestones.has(station.id):
			continue
		if not milestones.has(station.id):
			return station.id
	return "exit"

func hint_lines(key: String) -> Array:
	return definition.get("hints", {}).get(key, [])

func station_nearby() -> Dictionary:
	var nearest: Dictionary = {}
	var distance := 48.0
	for station in definition.stations:
		var node := areas.get_node(NodePath(station.id)) as Node2D
		var candidate := node.global_position.distance_to(player.global_position)
		if candidate < distance:
			nearest = station
			distance = candidate
	return nearest

func context_hint() -> String:
	if world_features and not world_features.hint().is_empty():
		return world_features.hint()
	if is_instance_valid(brother) and not brother.is_dead:
		return flow.niro_fight_hint() if flow != null else "[1] select shank, click during RECOVER • [C] Dodge • Space Jump"
	if hack_remaining > 0:
		return "Reprogramming… %d%% • stay within reach" % int((1 - hack_remaining) * 100)
	if controls_locked() or player.is_dead:
		return ""
	var station := station_nearby()
	if not station.is_empty():
		return "Completed: " + station.title if milestones.has(station.id) else "[E] " + station.title
	var guard = closest_guard()
	if guard and (guard.is_dead or guard.asleep) and not guard.gun_taken:
		return "[E] Search sleeping Keeper" if guard.asleep else "[E] Search fallen Keeper"
	if nearby("exit", 65):
		return "[E] Descend once this floor's objectives are complete"
	if player.is_concealed:
		return "Move carefully • touching a Keeper breaks stealth"
	if ladder_at(player.global_position):
		return "[W / S] Climb"
	if stuck():
		return "Not sure where to go? [Z] Think it through"
	return "A/D Move   Space Jump   C Dash   1–5 Select   Q Blanket   Esc Controls"

func interact() -> void:
	if controls_locked() or player.is_dead:
		return
	if player.controls.recover_charge():
		return
	if world_features and world_features.try_interact():
		return
	var station := station_nearby()
	if not station.is_empty():
		if milestones.has(station.id):
			notify("Already complete: " + station.title)
			return
		for required in station.requires:
			if not milestones.has(required):
				notify("First: " + station_title(str(required)))
				return
		if flow != null and station.id in ["FinalOffer", "BrotherEncounter", "DefeatExchange"]:
			notify("Niro will come to you.")
			return
		pending_milestone = station.id
		if station.id == "ForestViewpoint":
			pending_milestone = ""
			cinematic = load("res://scenes/ending_cinematic.tscn").instantiate()
			cinematic.level = self
			cinematic.finished.connect(finish_ending)
			hud.add_child(cinematic)
			return
		if station.id == "RemoteTerminal":
			pending_milestone = ""
			if not world_features.terminal_authenticated:
				world_features.open_terminal()
			elif hack_remaining <= 0:
				hack_remaining = 1.0
			return
		start_dialogue(station.lines, "milestone")
		return
	var guard = closest_guard()
	if guard and (guard.is_dead or guard.asleep) and not guard.gun_taken:
		player.loot_weapon(guard)
		return
	if nearby("exit", 65):
		if definition.stations.all(func(entry): return milestones.has(entry.id)) and sigil_placed:
			completed = true
			player.velocity = Vector2.ZERO
		else:
			notify("Follow the remaining objective before descending.")

## A station id as the player reads it ("FinalSigil" -> "Place the final sigil").
func station_title(id: String) -> String:
	for entry in definition.stations:
		if entry.id == id:
			return str(entry.title)
	return id.replace("_", " ")

func finish_dialogue() -> void:
	var event := dialogue_event
	var finished_milestone := pending_milestone if event == "milestone" else ""
	if dialogue_event == "milestone" and not pending_milestone.is_empty():
		milestones[pending_milestone] = true
		if has_node("Gates"):
			for gate in $Gates.get_children():
				if gate.unlock_milestone == pending_milestone:
					gate.unlock()
		var node = areas.get_node(NodePath(pending_milestone))
		node.activated = true
		node.queue_redraw()
		if node.kind == "sigil":
			get_node("/root/SoundFX").play_sound("sigil", -16)
			sigil_placed = true
			var charge_count := 1
			for station in definition.stations:
				if station.id == pending_milestone:
					charge_count = int(station.get("charge_count", 1))
			player.c4_count = maxi(0, player.c4_count - charge_count)
			make_noise(node.global_position, 220)
		pending_milestone = ""
	dialogue = []
	dialogue_index = 0
	dialogue_event = ""
	if flow != null:
		if finished_milestone == "Guitar":
			flow.on_guitar()
		elif event.begins_with("niro_"):
			flow.on_dialogue_finished(event)

func can_melee_reach(from: Vector2, to: Vector2) -> bool:
	return clear_sight(from, to)

func plant_c4() -> void:
	notify("This floor's charge is reserved for its sigil support. [E]")

func camera_alert(point: Vector2) -> void:
	floor_alerts += 1
	var called := spawn_watcher_reserves(point)
	for guard in guards():
		if not guard.is_dead:
			guard.investigate(point)
	notify("WATCHER ALERT • Reinforcements incoming." if called else "WATCHER ALERT • Keepers are searching your last seen position.")

## One reserve squad per floor. Repeated sweeps redirect the squad without spawning endlessly.
func spawn_watcher_reserves(point: Vector2) -> bool:
	var reserves: Array = world_features.roster.watcher_reserves.get(str(int(definition.number)), [])
	if watcher_reserves_called or reserves.is_empty():
		return false
	watcher_reserves_called = true
	var slots: Array[Vector2] = []
	for offset in [-156, 156, -100, 100]:
		var above := point + Vector2(offset, -24)
		if not clear_sight(point, above):
			continue
		var query := PhysicsRayQueryParameters2D.create(above, above + Vector2(0, 82), 1)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.normal.y < -0.9:
			slots.append(hit.position - Vector2(0, 16))
	var entry: Vector2 = $LevelPlan/PlayerSpawn.global_position
	for index in range(reserves.size()):
		var location := slots[index] if index < slots.size() else entry + Vector2(index * 18, 0)
		var guard = preload("res://scenes/guard.tscn").instantiate()
		guard.name = "WatcherReserve%d" % (index + 1)
		world_features.assign_keeper(guard, reserves[index])
		guard.position = $Guards.to_local(location)
		guard.patrol_left = guard.position.x - 60.0
		guard.patrol_right = guard.position.x + 60.0
		guard.level = self
		guard.illness_started = true
		guard.weapon_kind = "pistol"
		$Guards.add_child(guard)

	return true

func niro_retreating(engagement: int) -> void:
	if flow != null:
		flow.niro_retreating(engagement)

func niro_calls_guard(point: Vector2) -> void:
	if flow != null:
		flow.niro_calls_guard(point)

func brother_defeated() -> void:
	if flow != null:
		flow.step = flow.Step.DONE
	get_node("/root/MusicDirector").silence()
	milestones["BrotherEncounter"] = true
	areas.get_node("BrotherEncounter").activated = true
	areas.get_node("BrotherEncounter").queue_redraw()
	for station in definition.stations:
		if station.id == "DefeatExchange":
			pending_milestone = "DefeatExchange"
			start_dialogue(station.lines, "milestone")

func controls_locked() -> bool:
	return is_instance_valid(cinematic) or super.controls_locked()

func finish_ending() -> void:
	milestones["ForestViewpoint"] = true
	completed = true
	get_node("/root/Campaign").complete_floor(5, sigil_placed, milestones, floor_raw_stats())
	if get_node("/root/Campaign").played_from_start:
		get_node("/root/Campaign").mark_game_completed()
