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
var password_panel: PanelContainer
var password_input: LineEdit
var password_status: Label
var password_known := false
var terminal_authenticated := false
var config: Dictionary
var case_anchor_index := -1
const NAMES := {1: ["Rowan", "Ivo", "Bram", "Seth"], 2: ["Alden", "Corin", "Dane", "Ellis"], 3: ["Marek", "Oren", "Pavel", "Silas"], 4: ["Tomas", "Ulric", "Venn", "Wren"], 5: ["Yorick", "Zane", "Arlen", "Beck"]}

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
	subtitle = level.label_at(level.hud, Vector2(22, 250), Vector2(596, 42), 11)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_shadow_color", Color.BLACK)
	var keepers: Array[Node] = level.guards()
	for index in range(keepers.size()):
		keepers[index].guard_name = NAMES[number][index % 4]
		keepers[index].voice_index = index % 3
	if config.conversations.has(str(number)) and not keepers.is_empty():
		var first = keepers[0]
		if number == 3:
			first.position = Vector2(330, 236)
		var partner = load("res://scenes/guard.tscn").instantiate()
		partner.name = "ConversationKeeper"
		partner.position = first.position + Vector2(50, 0)
		partner.patrol_left = partner.position.x
		partner.patrol_right = partner.position.x + 100
		partner.level = level
		partner.illness_started = true
		partner.guard_name = NAMES[number][3]
		partner.voice_index = 1
		level.get_node("Guards").add_child(partner)
		actors = [first, partner]
		conversation = config.conversations[str(number)]
		first.facing = 1
		partner.facing = -1
		# Hold a conversation-ready pose; detection and damage still work.
		first.conversation_hold = true
		partner.conversation_hold = true
	place_props_after_physics()
	build_password_panel()

func place_props_after_physics() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	add_props()

func add_props() -> void:
	# Authored flat-floor anchors only: no random world-coordinate placements.
	var anchors := [Vector2(910, 236), Vector2(750, 432), Vector2(550, 656)]
	if floor_number == 1:
		anchors = [Vector2(580, 236), Vector2(900, 432), Vector2(780, 656)]
	var valid: Array[Vector2] = []
	for point in anchors:
		if not level.has_floor_below(point + Vector2(0, 13)):
			continue
		var near_station := false
		for node in level.areas.get_children():
			if node.global_position.distance_to(point) < 70:
				near_station = true
		if not near_station:
			valid.append(point)
	if not valid.is_empty():
		var campaign = get_node("/root/Campaign")
		if not campaign.case_anchors.has(floor_number):
			campaign.case_anchors[floor_number] = randi_range(0, valid.size() - 1)
		case_anchor_index = int(campaign.case_anchors[floor_number]) % valid.size()
		spawn_prop(valid[case_anchor_index], "case", "Suppressor case")
	# Enclosed wall recesses; no platform or collision geometry is removed.
	for entry in [[Vector2(900, 432), "VENT"], [Vector2(420, 656), "CRAWLSPACE"]]:
		var point: Vector2 = entry[0]
		var clear: bool = not level.areas.get_children().any(func(area): return area.global_position.distance_to(point) < 70) and not props.any(func(prop): return prop.global_position.distance_to(point) < 70)
		if clear and level.has_floor_below(point + Vector2(0, 13)):
			spawn_prop(point, "hide", entry[1])

func spawn_prop(point: Vector2, kind: String, title: String) -> void:
	var prop := Node2D.new()
	prop.set_script(load("res://scripts/review_prop.gd"))
	prop.position = point
	prop.kind = kind
	prop.title = title
	add_child(prop)
	props.append(prop)

func nearby_prop():
	for prop in props:
		if level.player.global_position.distance_to(prop.global_position) <= 36 and not (prop.kind == "case" and prop.used):
			return prop
	return null

func loot_takes_priority() -> bool:
	var guard = level.closest_guard()
	return guard != null and guard.is_dead and not guard.gun_taken

func hint() -> String:
	if level.player.in_hiding_spot:
		return "[E] Leave hiding spot • movement and attacks disabled inside"
	if loot_takes_priority():
		return ""
	var prop = nearby_prop()
	if prop:
		return "[E] Take suppressor • 3 shots" if prop.kind == "case" else "[E] Hide in " + prop.title.to_lower()
	return ""

func try_interact() -> bool:
	if level.player.in_hiding_spot:
		level.player.in_hiding_spot = false
		return true
	if loot_takes_priority():
		return false
	var prop = nearby_prop()
	if prop == null:
		return false
	if prop.kind == "case":
		prop.used = true
		prop.queue_redraw()
		level.player.suppressor_uses = 3
		level.notify("Suppressor attached: next 3 fired shots are quieter. No weapon or ammo granted.")
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

func speak(actor: Node2D, id: String, text: String, extra: Dictionary = {}) -> void:
	voice.stop()
	voice_speaker = actor
	voice.global_position = actor.global_position
	var path := "res://assets/audio/voice/%s.mp3" % id
	var duration := maxf(2.5, text.length() * 0.055)
	if ResourceLoader.exists(path):
		voice.stream = load(path)
		duration = voice.stream.get_length()
		if DisplayServer.get_name() != "headless":
			voice.play()
	line_left = duration + 0.35
	subtitle.text = "%s: %s" % [actor.guard_name, text]
	last_line = extra.duplicate()
	if last_line.is_empty():
		last_line = {"bark": true}

func bark(actor: Node2D, kind: String) -> void:
	abort_conversation()
	if voice.playing:
		return
	speak(actor, "%s_%d" % [kind, actor.voice_index], config.barks[kind].text)

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

func _draw() -> void:
	if is_instance_valid(level) and not level.controls_locked() and voice_audible():
		draw_texture_rect(preload("res://assets/library/speech.png"), Rect2(to_local(voice_speaker.global_position) + Vector2(-8, -56), Vector2(16, 16)), false, Color("f2d3ab"))

func build_password_panel() -> void:
	password_panel = level.panel_at(Vector2(110, 95), Vector2(420, 190))
	var box := VBoxContainer.new()
	password_panel.add_child(box)
	var title := Label.new()
	title.text = "CHECKPOINT LOGIN"
	box.add_child(title)
	password_input = LineEdit.new()
	password_input.placeholder_text = "Password (case-sensitive)"
	box.add_child(password_input)
	password_input.text_submitted.connect(submit_password)
	var login := Button.new()
	login.text = "Log in"
	login.pressed.connect(func(): submit_password(password_input.text))
	box.add_child(login)
	var slip := Button.new()
	slip.text = "Inspect maintenance slip"
	slip.pressed.connect(func(): password_known = true; password_status.text = "Maintenance slip: root (all lowercase).")
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
	password_input.grab_focus()

func submit_password(text: String) -> void:
	if text != "root":
		password_status.text = "Access denied. Password is case-sensitive."
		return
	terminal_authenticated = true
	password_panel.hide()
	level.hack_remaining = 1.0

func modal_open() -> bool:
	return is_instance_valid(password_panel) and password_panel.visible

func _exit_tree() -> void:
	if is_instance_valid(voice):
		voice.stop()
		voice.stream = null
	actors.clear()
	voice_speaker = null
