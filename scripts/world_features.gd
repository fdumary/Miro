extends Node2D
## Small additive props, finite overheard scenes and offline spatial guard speech.
var level: Node2D
var floor_number := 1
var props: Array[Node2D] = []
var actors: Array[Node] = []
var conversation: Array = []
var conversation_index := -1
var conversation_done := false
var conversation_started := false
var line_left := 0.0
var retry_left := 0.0
var last_line: Dictionary = {}
var voice: AudioStreamPlayer2D
var voice_speaker: Node2D
var subtitle: Label
var speech_bubble: Control
var thought_bubble: Control
## Niro (or the voice) talking through Miro's remote: a tagged bubble over Miro, radio audio.
var remote_bubble: Control
var remote_left := 0.0
var thoughts: Dictionary
var thought_seen: Dictionary = {}
var thought_left := 0.0
var password_panel: PanelContainer
var password_input: LineEdit
var password_status: Label
var password_known := false
## Controller-friendly login: once the password is known, one button enters it.
var password_use: Button
var password_slip: Button
var terminal_authenticated := false
var config: Dictionary
var case_anchor_index := -1
var access_point := Vector2.ZERO
var practice_camera: Node
var early_authenticated := false
var trapdoors: Array[Node2D] = []
## Miro's inner voice plays on the Thought bus (long, spacey reverb). Drop clips at
## res://assets/audio/voice/thought_<floor>_<id>.mp3 to voice a thought.
var thought_voice: AudioStreamPlayer
## Individual Keeper profiles and authored casting (data/guard_roster.json).
var roster: Dictionary = {}
## Extra overheard scenes after the main conversation: huddles and add_casual_lines().
## Each: {actors, lines, index, started, done}. Only one voice speaks at a time.
var casual_scenes: Array = []
var mutter_wait := 6.0
var muttered: Dictionary = {}
const MUTTER_RANGE := 190.0
const MUTTER_GAP := 14.0

func setup(owner_level: Node2D, number: int) -> void:
	level = owner_level
	floor_number = number
	config = JSON.parse_string(FileAccess.get_file_as_string("res://data/guard_dialogue.json"))
	voice = AudioStreamPlayer2D.new()
	voice.bus = "Voice"
	voice.process_mode = Node.PROCESS_MODE_PAUSABLE
	voice.max_distance = 300
	voice.attenuation = 1.5
	add_child(voice)
	thought_voice = AudioStreamPlayer.new()
	thought_voice.bus = "Thought" if AudioServer.get_bus_index("Thought") >= 0 else "Voice"
	thought_voice.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(thought_voice)
	speech_bubble = Control.new()
	speech_bubble.set_script(preload("res://scripts/character_bubble.gd"))
	level.hud.add_child(speech_bubble)
	subtitle = speech_bubble.text_label
	speech_bubble.visible = false
	thought_bubble = Control.new()
	thought_bubble.set_script(preload("res://scripts/character_bubble.gd"))
	thought_bubble.thought = true
	thought_bubble.actor = level.player
	level.hud.add_child(thought_bubble)
	thought_bubble.visible = false
	remote_bubble = Control.new()
	remote_bubble.set_script(preload("res://scripts/character_bubble.gd"))
	remote_bubble.actor = level.player
	level.hud.add_child(remote_bubble)
	remote_bubble.visible = false
	thoughts = JSON.parse_string(FileAccess.get_file_as_string("res://data/inner_dialogue.json"))
	roster = JSON.parse_string(FileAccess.get_file_as_string("res://data/guard_roster.json"))
	var keepers: Array[Node] = level.guards()
	for index in range(keepers.size()):
		name_keeper(keepers[index], number, index)
		if number > 1 and not keepers[index].has_method("begin_recovery"):
			keepers[index].weapon_kind = ["pistol", "smg"][index % 2]
	var authored: Dictionary = level.definition.get("features", {}) if level.get("definition") != null else {}
	if config.conversations.has(str(number)) and not keepers.is_empty():
		var first = keepers[0]
		var spot = authored.get("conversation")
		if spot != null:
			for keeper in keepers:
				if keeper.name == spot.guard:
					first = keeper
			first.position = Vector2(spot.position[0], spot.position[1])
		elif number == 3:
			first.position = Vector2(330, 236)
		var partner = load("res://scenes/guard.tscn").instantiate()
		partner.name = "ConversationKeeper"
		partner.position = first.position + Vector2(50, 0)
		partner.patrol_left = partner.position.x
		partner.patrol_right = partner.position.x + 100
		partner.level = level
		partner.illness_started = true
		var cast: Array = roster.conversation_cast[str(number)]
		assert(first.guard_name == cast[0], "Keeper conversation cast must match the authored scene")
		assign_keeper(partner, cast[1])
		level.get_node("Guards").add_child(partner)
		actors = [first, partner]
		conversation = config.conversations[str(number)]
		first.facing = 1
		partner.facing = -1
		# Hold a conversation-ready pose; detection and damage still work.
		first.conversation_hold = true
		partner.conversation_hold = true
	for huddle in authored.get("huddles", []):
		spawn_huddle(huddle)
	setup_trapdoors()
	place_props_after_physics()
	build_password_panel()
	if not authored.get("ports", []).is_empty():
		var port: Array = authored.ports[0]
		access_point = Vector2(port[0], port[1])
		spawn_prop(access_point, "access", "SERVICE PORT")
	elif number in [1, 2]:
		access_point = Vector2(500, 432) if number == 1 else Vector2(440, 432)
		spawn_prop(access_point, "access", "SERVICE PORT")
		if number == 2:
			practice_camera = load("res://scenes/security_camera.tscn").instantiate()
			practice_camera.level = level
			practice_camera.position = Vector2(720, 370)
			level.add_child(practice_camera)

func place_props_after_physics() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	add_props()

func add_props() -> void:
	var authored: Dictionary = level.definition.get("features", {}) if level.get("definition") != null else {}
	if authored.has("cases"):
		# Authored layouts place every case and hiding spot by hand (tools/level_layouts.py).
		for point in authored.cases:
			spawn_prop(Vector2(point[0], point[1]), "case", "Ammunition case")
		for hide in authored.hides:
			if hide.title == "CRATE":
				spawn_crate(Vector2(hide.position[0], hide.position[1] + 16))
			else:
				spawn_prop(Vector2(hide.position[0], hide.position[1]), "hide", hide.title)
		return
	if floor_number == 1:
		for point in LEVEL_ONE_CRATES:
			spawn_crate(point)
	# Authored flat-floor anchors only: no random world-coordinate placements.
	var anchors := [Vector2(910, 236), Vector2(750, 432), Vector2(550, 656)]
	if floor_number == 1:
		anchors = [Vector2(580, 236), Vector2(900, 432), Vector2(780, 656)]
	var valid: Array[Vector2] = []
	# Supply case: a small ammunition cache (suppressors were cut on 7 Nov).
	for point in anchors:
		if not level.has_floor_below(point + Vector2(0, 13)):
			continue
		var near_station := false
		for node in level.areas.get_children():
			if node.global_position.distance_to(point) < 70 or (node.kind == "ladder" and Rect2(node.global_position - node.area_size / 2, node.area_size).grow(30).has_point(point)):
				near_station = true
		if not near_station and placement_clear(point):
			valid.append(point)
	if not valid.is_empty():
		var campaign = get_node("/root/Campaign")
		if not campaign.case_anchors.has(floor_number):
			campaign.case_anchors[floor_number] = 0
		case_anchor_index = int(campaign.case_anchors[floor_number]) % valid.size()
		spawn_prop(valid[case_anchor_index], "case", "Ammunition case")
	# Enclosed wall recesses; no platform or collision geometry is removed.
	for entry in [[Vector2(900, 432), "VENT"], [Vector2(420, 656), "CRAWLSPACE"]]:
		var point: Vector2 = entry[0]
		var clear: bool = not level.areas.get_children().any(func(area): return area.global_position.distance_to(point) < 70) and not props.any(func(prop): return prop.global_position.distance_to(point) < 70)
		if clear and placement_clear(point) and level.has_floor_below(point + Vector2(0, 13)):
			spawn_prop(point, "hide", entry[1])

## Crates: stand on top (one-way, so they never block a walk or a patrol), or press E beside
## one to hide inside. `point` is on the floor; it is lifted onto any tile it would overlap.
const LEVEL_ONE_CRATES := [Vector2(477, 252), Vector2(968, 448), Vector2(530, 672)]

func spawn_crate(point: Vector2) -> void:
	var tiles := level.get_node_or_null("StoneFloors") as TileMapLayer
	if tiles:
		for step in range(8):
			var blocked := false
			for offset in [-12.0, 0.0, 12.0]:
				blocked = blocked or tiles.get_cell_source_id(tiles.local_to_map(tiles.to_local(point + Vector2(offset, -1)))) >= 0
			if not blocked:
				break
			point.y -= tiles.tile_set.tile_size.y
	var center := point - Vector2(0, 13.5)
	# The prop sits where every other hiding spot does (16 px above the floor).
	spawn_prop(point - Vector2(0, 16), "crate", "CRATE")
	var body := StaticBody2D.new()
	body.name = "Crate%d" % props.size()
	body.position = center
	# Own physics layer (6): Miro lands on it, but sight lines and Keepers ignore it.
	body.collision_layer = 0
	body.set_collision_layer_value(6, true)
	body.collision_mask = 0
	level.player.set_collision_mask_value(6, true)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(28, 27)
	shape.shape = box
	shape.one_way_collision = true
	body.add_child(shape)
	add_child(body)

func spawn_prop(point: Vector2, kind: String, title: String) -> void:
	var prop := Node2D.new()
	prop.set_script(load("res://scripts/review_prop.gd"))
	prop.position = point
	prop.kind = kind
	prop.title = title
	add_child(prop)
	props.append(prop)

func reachable(point: Vector2, distance := 36.0) -> bool:
	return level.player.global_position.distance_to(point) <= distance and level.clear_sight(level.player.global_position + Vector2(0, -8), point + Vector2(0, -8))

func security_terminal() -> Node2D:
	var nearest: Node2D
	var distance := 48.0
	var terminals := get_tree().get_nodes_in_group("security_terminals")
	var checkpoint: Node2D = level.areas.get_node_or_null("RemoteTerminal")
	if checkpoint != null:
		terminals.append(checkpoint)
	for terminal in terminals:
		if not level.is_ancestor_of(terminal):
			continue
		var gap: float = level.player.global_position.distance_to(terminal.global_position)
		if gap <= distance and reachable(terminal.global_position, distance):
			nearest = terminal
			distance = gap
	return nearest

func disable_turrets() -> int:
	var count := 0
	for turret in get_tree().get_nodes_in_group("tower_turrets"):
		if level.is_ancestor_of(turret) and not turret.disabled:
			turret.disable()
			count += 1
	return count

func story_distance() -> float:
	var closest := 48.0
	for area in level.areas.get_children():
		if area.kind in ["bed", "door", "sigil", "exit", "brother", "note"]:
			closest = minf(closest, level.player.global_position.distance_to(area.global_position))
	return closest

func nearby_prop():
	var best = null
	var distance := minf(36, story_distance())
	for prop in props:
		var candidate: float = level.player.global_position.distance_to(prop.global_position)
		if candidate < distance and reachable(prop.global_position) and not (prop.kind == "case" and prop.used):
			best = prop
			distance = candidate
	return best

func nearby_trapdoor():
	var best = null
	var distance := minf(38, story_distance())
	var prop = nearby_prop()
	if prop != null:
		distance = minf(distance, level.player.global_position.distance_to(prop.global_position))
	for trap in trapdoors:
		var handle: Vector2 = trap.global_position + Vector2(0, -28)
		var candidate: float = level.player.global_position.distance_to(handle)
		if absf(level.player.global_position.x - handle.x) <= 16 and candidate < distance and reachable(handle, 38):
			best = trap
			distance = candidate
	return best

func setup_trapdoors() -> void:
	var floor: TileMapLayer = level.get_node("StoneFloors")
	for cell in floor.get_used_cells():
		if floor.get_cell_source_id(cell) != 2:
			continue
		var point := floor.to_global(floor.map_to_local(cell))
		# Do not put an opening through an authored ladder corridor.
		var clear := true
		for area in level.areas.get_children():
			if area.kind == "ladder" and Rect2(area.global_position - area.area_size / 2, area.area_size).grow(18).intersects(Rect2(point - Vector2(14, 14), Vector2(28, 28))):
				clear = false
		if not clear:
			continue
		var trap := StaticBody2D.new()
		trap.set_script(preload("res://scripts/trapdoor.gd"))
		trap.level = level
		var gates = level.get_node_or_null("Gates")
		# Authored layouts never put a hatch where it could drop you past a locked gate.
		if level.get("definition") != null and level.definition.has("features"):
			gates = null
		if gates != null:
			for gate in gates.get_children():
				if point.x < gate.global_position.x:
					trap.route_gate = gate
		trap.position = level.to_local(point)
		level.add_child(trap)
		trapdoors.append(trap)
		floor.erase_cell(cell)

func nearest_loot():
	var best = null
	var distance := 45.0
	for guard in level.guards():
		var candidate: float = guard.global_position.distance_to(level.player.global_position)
		if (guard.is_dead or guard.asleep) and not guard.gun_taken and candidate < distance and level.can_melee_reach(level.player.global_position, guard.global_position):
			best = guard
			distance = candidate
	return best

func loot_takes_priority() -> bool:
	var guard = nearest_loot()
	if guard == null:
		return false
	var distance: float = guard.global_position.distance_to(level.player.global_position)
	var prop = nearby_prop()
	return distance <= story_distance() and (prop == null or distance <= prop.global_position.distance_to(level.player.global_position))

func hint() -> String:
	if level.controls_locked():
		return ""
	if level.player.controls.nearest_charge() != null:
		return "[E] Recover C4"
	if level.player.in_hiding_spot:
		return "[E] Leave hiding spot • movement and attacks disabled inside"
	if loot_takes_priority():
		return ""
	var trap = nearby_trapdoor()
	if trap != null:
		if not trap.available():
			return "Trapdoor locked · open checkpoint / ward seal first"
		return "Trapdoor open · closes when clear" if trap.is_open else "[E] Open trapdoor · 5 seconds"
	var prop = nearby_prop()
	if prop and prop.kind == "access":
		return "[E] Service port · select remote to connect"
	if prop:
		return "[E] Take ammunition" if prop.kind == "case" else "[E] Hide in " + prop.title.to_lower()
	return ""

func try_interact() -> bool:
	if level.player.in_hiding_spot:
		level.player.in_hiding_spot = false
		return true
	if loot_takes_priority():
		if floor_number > 1:
			level.player.loot_weapon(nearest_loot())
			return true
		return false
	var trap = nearby_trapdoor()
	if trap != null:
		trap.activate()
		return true
	var prop = nearby_prop()
	if prop == null:
		return false
	if prop.kind == "access":
		level.player.controls.open_remote()
		return true
	if prop.kind == "case":
		if level.player.controls.collect_ammo_case():
			prop.used = true
			prop.queue_redraw()
	else:
		if level.player.detection_state == "SPOTTED" or level.guards().any(func(guard): return guard.detect_player()):
			level.notify("Break sight before entering a hiding spot.")
			return true
		level.player.end_stealth()
		level.player.in_hiding_spot = true
		level.player.velocity = Vector2.ZERO
		level.notify("Hidden in " + prop.title.to_lower() + ". [E] Leave")
	return true

func _process(delta: float) -> void:
	queue_redraw()
	update_bubbles(delta)
	if not is_instance_valid(level) or level.paused:
		return
	if is_instance_valid(voice_speaker):
		voice.global_position = voice_speaker.global_position
		if voice_speaker.is_dead:
			voice.stop()
			subtitle.text = ""
		elif not last_line.is_empty():
			subtitle.visible = voice_speaker.global_position.distance_to(level.player.global_position) < 230 and not level.controls_locked()
			if subtitle.visible and last_line.has("clue"):
				password_known = true
	if level.controls_locked():
		voice.stream_paused = true
		return
	voice.stream_paused = false
	if level.player.is_dead:
		abort_conversation()
		return
	line_left = maxf(0, line_left - delta)
	if line_left == 0:
		subtitle.text = ""
		last_line = {}
	if conversation_done or actors.is_empty() or not conversation_started:
		update_casual(delta)
	if conversation_done or actors.is_empty():
		return
	if actors.any(func(actor): return actor.is_dead or actor.alert_state != IntroGuard.State.PATROL):
		abort_conversation()
		retry_left = 8
		return
	retry_left = maxf(0, retry_left - delta)
	if retry_left > 0:
		return
	if not conversation_started:
		if level.player.global_position.distance_to(actors[0].global_position) > 250:
			return
		conversation_started = true
		conversation_index = -1
		for actor in actors:
			actor.conversation_hold = true
	if line_left <= 0:
		conversation_index += 1
		if conversation_index >= conversation.size():
			conversation_done = true
			for actor in actors:
				actor.conversation_hold = false
				actor.facing = 1
				actor.turn_away_left = 5.0
			return
		var line: Dictionary = conversation[conversation_index]
		speak(actors[int(line.speaker)], line.id, line.text, line)

## The floor roster is in authored spawn order. Level 5 uses a running reinforcement index.
func name_keeper(keeper: Node, number: int, index: int) -> void:
	var entries: Array = roster.floors.get(str(number), [])
	if index < entries.size():
		assign_keeper(keeper, entries[index])

func assign_keeper(keeper: Node, keeper_name: String) -> void:
	keeper.guard_name = keeper_name
	keeper.personality = roster.keepers[keeper_name].personality

## Off-duty Keepers in a tight group (features.huddles): they stand still, face in, and play
## their scene when Miro comes near. Too absorbed to see him unless he walks into them.
func spawn_huddle(huddle: Dictionary) -> void:
	var scene: Dictionary = roster.get("huddles", {}).get(huddle.scene, {})
	if scene.is_empty():
		return
	var members: Array = []
	var origin := Vector2(huddle.position[0], huddle.position[1])
	var count: int = scene.keepers.size()
	for index in range(count):
		var keeper = load("res://scenes/guard.tscn").instantiate()
		keeper.name = "Huddle%s%d" % [str(huddle.scene).capitalize().replace(" ", ""), index]
		keeper.position = origin + Vector2((index - (count - 1) / 2.0) * 30.0, 0)
		keeper.patrol_left = keeper.position.x
		keeper.patrol_right = keeper.position.x
		keeper.level = level
		keeper.illness_started = true
		keeper.weapon_kind = "pistol"
		assign_keeper(keeper, scene.keepers[index])
		level.get_node("Guards").add_child(keeper)
		keeper.facing = 1.0 if index == 0 else -1.0
		keeper.conversation_hold = true
		keeper.distracted = true
		members.append(keeper)
	var lines: Array = []
	for index in range(scene.lines.size()):
		var line: Dictionary = scene.lines[index].duplicate()
		line["id"] = "%s_%d" % [huddle.scene, index + 1]
		lines.append(line)
	add_casual_lines(lines, members, true)

## Adds an overheard scene that plays after (never over) the main conversation.
## `lines` are {speaker, text[, id]}; speaker indexes `actors` (default: the first two patrol Keepers).
func add_casual_lines(lines: Array, scene_actors: Array = [], hold := false) -> void:
	if scene_actors.is_empty():
		for keeper in level.guards():
			if not actors.has(keeper) and scene_actors.size() < 2:
				scene_actors.append(keeper)
	if scene_actors.is_empty():
		return
	casual_scenes.append({"actors": scene_actors, "lines": lines, "index": -1, "started": false, "done": false, "hold": hold})

func main_conversation_busy() -> bool:
	return conversation_started and not conversation_done

## One casual scene or patrol mutter at a time, only while no one else is speaking.
func update_casual(delta: float) -> void:
	if line_left > 0 or voice.playing or main_conversation_busy():
		return
	for scene in casual_scenes:
		if scene.done:
			continue
		var cast: Array = scene.actors
		if cast.any(func(actor): return not is_instance_valid(actor) or actor.is_dead or actor.alert_state != IntroGuard.State.PATROL):
			scene.done = true
			for actor in cast:
				if is_instance_valid(actor):
					actor.conversation_hold = false
					actor.distracted = false
			continue
		if not scene.started:
			if level.player.global_position.distance_to(cast[0].global_position) > 260:
				continue
			scene.started = true
			for actor in cast:
				actor.conversation_hold = true
		scene.index += 1
		if scene.index >= scene.lines.size():
			scene.done = true
			if not scene.hold:
				for actor in cast:
					actor.conversation_hold = false
			continue
		var line: Dictionary = scene.lines[scene.index]
		var speaker: Node2D = cast[int(line.speaker) % cast.size()]
		speak(speaker, str(line.get("id", "casual_%d" % scene.index)), str(line.text), line)
		return
	update_mutters(delta)

## A patrolling Keeper close to Miro mutters something mundane, once each, never near an
## unfinished overheard scene (so it can't talk over a clue).
func update_mutters(delta: float) -> void:
	mutter_wait = maxf(0, mutter_wait - delta)
	if mutter_wait > 0:
		return
	if not conversation_done and not actors.is_empty() and level.player.global_position.distance_to(actors[0].global_position) < 320:
		return
	for scene in casual_scenes:
		if not scene.done and level.player.global_position.distance_to(scene.actors[0].global_position) < 320:
			return
	var profiles: Dictionary = roster.keepers
	for keeper in level.guards():
		if keeper.get("personality") == null:
			continue
		if keeper.is_dead or keeper.asleep or keeper.alert_state != IntroGuard.State.PATROL or muttered.has(keeper.get_instance_id()) or actors.has(keeper):
			continue
		if keeper.distracted or not profiles.has(keeper.guard_name):
			continue
		var gap: Vector2 = keeper.global_position - level.player.global_position
		if gap.length() > MUTTER_RANGE or absf(gap.y) > 40:
			continue
		var idle: Array = profiles[keeper.guard_name].idle
		var choice := muttered.size() % idle.size()
		muttered[keeper.get_instance_id()] = true
		mutter_wait = MUTTER_GAP
		speak(keeper, "idle_%d" % (choice + 1), idle[choice])
		return

func speak(actor: Node2D, id: String, text: String, extra: Dictionary = {}) -> void:
	voice.stop()
	voice_speaker = actor
	speech_bubble.actor = actor
	voice.global_position = actor.global_position
	var path := keeper_clip_path(actor.guard_name, id)
	var duration := maxf(2.5, text.length() * 0.055)
	voice.stream = load(path) if ResourceLoader.exists(path) else null
	if voice.stream:
		duration = voice.stream.get_length()
		if DisplayServer.get_name() != "headless":
			voice.play()
	line_left = duration + 0.35
	subtitle.text = "%s: %s" % [actor.guard_name, text]
	last_line = extra.duplicate()
	if last_line.is_empty():
		last_line = {"bark": true}

## All spatial dialogue uses the actor's own voice, even when several floors share a line.
func keeper_clip_path(keeper_name: String, line_id: String) -> String:
	return "res://assets/audio/voice/%s_%s.mp3" % [keeper_name.to_lower(), line_id]

func bark(actor: Node2D, kind: String) -> void:
	abort_conversation()
	if voice.playing:
		return
	var profile: Dictionary = roster.keepers.get(actor.guard_name, {})
	var text: String = profile.get(kind, config.barks[kind].text)
	speak(actor, kind, text)

func abort_conversation() -> void:
	if conversation_started and not conversation_done:
		conversation_started = false
		conversation_done = true
		conversation_index = -1
		voice.stop()
		line_left = 0
		last_line = {}
		subtitle.text = ""
	for actor in actors:
		actor.conversation_hold = false

func voice_audible() -> bool:
	return line_left > 0 and is_instance_valid(voice_speaker) and not voice_speaker.is_dead and voice_speaker.global_position.distance_to(level.player.global_position) < 230

func update_bubbles(delta: float) -> void:
	if not is_instance_valid(level):
		return
	speech_bubble.visible = voice_audible() and not level.controls_locked() and not level.player.is_dead
	speech_bubble.follow_actor()
	thought_bubble.visible = false
	remote_bubble.visible = false
	if level.controls_locked() or level.player.is_dead:
		return
	if remote_left > 0:
		remote_left = maxf(0, remote_left - delta)
		remote_bubble.visible = remote_left > 0
		remote_bubble.follow_actor()
		return
	if speech_bubble.visible:
		return
	if thought_left > 0:
		thought_left = maxf(0, thought_left - delta)
		thought_bubble.visible = thought_left > 0
		thought_bubble.follow_actor()
		return
	for entry in thoughts.get(str(floor_number), []):
		if thought_seen.has(entry.id):
			continue
		var ready := true
		if entry.has("milestone"):
			ready = floor_number > 1 and level.milestones.has(entry.milestone)
		if entry.has("minimum_y"):
			ready = ready and level.player.position.y >= entry.minimum_y
		if ready:
			thought_seen[entry.id] = true
			think(entry.text, "thought_%d_%s" % [floor_number, entry.id])
			break

func think(text: String, clip := "") -> void:
	if text.is_empty():
		return
	thought_bubble.text_label.text = text
	thought_left = maxf(4, text.length() * 0.07)
	var path := "res://assets/audio/voice/%s.mp3" % clip
	if not clip.is_empty() and ResourceLoader.exists(path) and DisplayServer.get_name() != "headless":
		thought_voice.stream = load(path)
		thought_voice.play()

## A line over the remote: shown above Miro, heard through the bitcrushed radio bus.
## With an actor (Niro in the room) the line hangs over him instead and is not radioed.
func remote_say(text: String, speaker := "NIRO", actor: Node2D = null) -> void:
	if text.is_empty():
		return
	remote_bubble.actor = actor if is_instance_valid(actor) else level.player
	remote_bubble.tag = speaker if is_instance_valid(actor) else speaker + " · remote"
	remote_bubble.text_label.text = text
	if is_instance_valid(actor):
		remote_left = maxf(2.5, text.length() * 0.06) + 0.8
	else:
		remote_left = get_node("/root/RemoteRadio").say(text) + 0.8

func remote_busy() -> bool:
	return remote_left > 0

func build_password_panel() -> void:
	password_panel = level.panel_at(Vector2(110, 95), Vector2(420, 190))
	var box := VBoxContainer.new()
	password_panel.add_child(box)
	var title := Label.new()
	title.text = "CHECKPOINT LOGIN"
	box.add_child(title)
	password_input = LineEdit.new()
	password_input.secret = true
	password_input.secret_character = "*"
	password_input.placeholder_text = "Password (case-sensitive)"
	box.add_child(password_input)
	password_input.text_submitted.connect(submit_password)
	var login := Button.new()
	login.text = "Log in"
	login.pressed.connect(func(): submit_password(password_input.text))
	box.add_child(login)
	password_use = Button.new()
	password_use.text = "Enter the known password"
	password_use.pressed.connect(func(): submit_password("root"))
	box.add_child(password_use)
	var slip := Button.new()
	password_slip = slip
	slip.text = "Inspect maintenance slip"
	slip.pressed.connect(func():
		password_known = true
		password_status.text = "Maintenance slip: root (all lowercase)."
		password_use.show()
		password_use.grab_focus())
	box.add_child(slip)
	password_status = Label.new()
	password_status.text = "Listen nearby, or inspect the maintenance slip."
	box.add_child(password_status)
	var cancel := Button.new()
	cancel.text = "Close"
	cancel.pressed.connect(func(): password_panel.hide())
	box.add_child(cancel)
	password_panel.hide()

func open_terminal() -> void:
	password_panel.show()
	password_input.text = ""
	password_status.text = "Overheard password: root" if password_known else "Listen nearby, or inspect the maintenance slip."
	password_use.visible = password_known
	# With a controller there is no keyboard to type into, so focus starts on a button.
	if Input.get_connected_joypads().is_empty():
		password_input.grab_focus()
	elif password_known:
		password_use.grab_focus()
	else:
		password_slip.grab_focus()

func submit_password(text: String) -> void:
	if text != "root":
		password_status.text = "Access denied. Password is case-sensitive."
		return
	terminal_authenticated = true
	password_panel.hide()
	level.hack_remaining = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if modal_open() and event.is_action_pressed("ui_cancel"):
		password_panel.hide()
		get_viewport().set_input_as_handled()

func modal_open() -> bool:
	return is_instance_valid(password_panel) and password_panel.visible

func _exit_tree() -> void:
	if is_instance_valid(voice):
		voice.stop()
		voice.stream = null
	actors.clear()
	voice_speaker = null

func placement_clear(point: Vector2) -> bool:
	for area in level.areas.get_children():
		if area.kind == "ladder" and Rect2(area.global_position - area.area_size / 2, area.area_size).grow(30).has_point(point):
			return false
	var shape := RectangleShape2D.new()
	shape.size = Vector2(12, 26)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, point + Vector2(0, 1.5))
	query.collision_mask = 1
	query.margin = 0
	return get_world_2d().direct_space_state.intersect_shape(query).is_empty()
