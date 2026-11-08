extends Node2D
## The first floor only. Story flags stay local so R restores the entry state.

@onready var player: IntroPlayer = $Player
@onready var areas: Node2D = $Interactables
var radio_line := ""
## A cinematic card over the start of a floor or a story beat (scripts/floor_card.gd).
var card: Control
var door_open: bool = false
var sigil_placed: bool = false
## Niro over the remote when Level 1 ends ("The remote crackles").
const FLOOR_END_CRACKLE := "...Miro?"
var crackle_played := false
var brother_heard: bool = false
var completed: bool = false
var paused: bool = false
var route: String = ""
var dialogue: Array = []
var dialogue_index: int = 0
var dialogue_event: String = ""
var message: String = ""
var message_left: float = 0.0
var elapsed: float = 0.0
var hud: CanvasLayer
var status_label: Label
var health_label: RichTextLabel
var objective_label: Label
var hint_label: Label
var message_label: Label
var dialogue_panel: Control
var dialogue_label: Label
var overlay: PanelContainer
var overlay_label: Label
var shot_flash: float = 0.0
var world_features: Node2D
const VISUALS = preload("res://scripts/visual_assets.gd")
var hint_icon: TextureRect
var stealth_meter: Control
var effects: Node2D
# Branch tracking (committed to Campaign only when the floor is completed).
var floor_detections := 0
var was_spotted := false
var loud_events := 0
var stealth_bonus := 0

func _ready() -> void:
	get_node("/root/Campaign").enter_floor(1)
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_inputs()
	player.level = self
	if has_node("LevelPlan/PlayerSpawn"):
		player.global_position = $LevelPlan/PlayerSpawn.global_position
	for guard in guards():
		guard.level = self
	build_hud()
	apply_difficulty()
	setup_world_features(1)
	start_dialogue([
		["MIRO", "Stone. Iron. A name scratched into the bed: Miro.\nMine... I think. Nothing before this room.", "thought"],
		["JUDAS", "Awake again. Keep it down, traitor."],
		["MIRO", "Is there anything you can do for me?"],
		["JUDAS", "Depends. Cell 04 gave me his boots. Cell 09 gave me his ration card.\nWhat have you got?"],
		["MIRO", "You're looking at it."],
		["JUDAS", "Then I'm not looking. (He turns away, coughing.)\nThe tower doesn't pay me enough to care."],
		["MIRO", "His hands are shaking. The same marks as the others.\nHe's turned away. This might be my only chance.", "thought"]
	], "intro")
	show_card("floor", "01", "THE PRISONER")
	var launch_floor: int = get_node("/root/Campaign").launch_floor()
	if launch_floor > 1:
		get_tree().call_deferred("change_scene_to_file", "res://scenes/levels/level_%02d.tscn" % launch_floor)

## Settings difficulty: Miro's hearts and the blanket's active/recharge times.
func apply_difficulty() -> void:
	var tuning: Dictionary = get_node("/root/Campaign").tuning()
	player.health = int(tuning.health)
	player.stealth_cooldown = float(tuning.stealth_cooldown)
	player.stealth_duration = float(tuning.stealth_duration)

func setup_inputs() -> void:
	var bindings := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "climb_up": [KEY_W, KEY_UP], "climb_down": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE], "dodge": [KEY_C], "attack": [], "cloak": [], "explosive": [], "fire": [], "interact": [KEY_E], "advance": [KEY_ENTER], "skip": [KEY_TAB], "pause_game": [KEY_ESCAPE], "retry": [KEY_BACKSPACE]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)

	for action in ["pad_use", "pad_focus"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
	add_pad_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	add_pad_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	add_pad_axis("climb_up", JOY_AXIS_LEFT_Y, -1.0)
	add_pad_axis("climb_down", JOY_AXIS_LEFT_Y, 1.0)
	add_pad_axis("pad_use", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	add_pad_axis("pad_focus", JOY_AXIS_TRIGGER_LEFT, 1.0)
	for pair in [["dodge", JOY_BUTTON_B], ["advance", JOY_BUTTON_A], ["pause_game", JOY_BUTTON_START]]:
		var event := InputEventJoypadButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0], event)

	# Menus and pop-ups (the Level 3 checkpoint login) take A to press and B to back out.
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var event := InputEventJoypadButton.new()
		event.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], event):
			InputMap.action_add_event(pair[0], event)

	apply_controller_deadzone()
	var settings = get_node("/root/ControllerSettings")
	if not settings.changed.is_connected(apply_controller_deadzone):
		settings.changed.connect(apply_controller_deadzone)

func apply_controller_deadzone() -> void:
	var value: float = get_node("/root/ControllerSettings").preferences.deadzone
	for action in ["move_left", "move_right", "climb_up", "climb_down"]:
		InputMap.action_set_deadzone(action, value)

func add_pad_axis(action: String, axis: int, direction: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = direction
	InputMap.action_add_event(action, event)

func controls_locked() -> bool:
	return (is_instance_valid(player.controls) and player.controls.locked()) or is_instance_valid(player.pending_guard) or paused or not dialogue.is_empty() or completed or (is_instance_valid(world_features) and world_features.modal_open())

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F10:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return
	if completed and event.is_action_pressed("advance") and not event.is_echo():
		get_node("/root/Campaign").complete_floor(1, sigil_placed, {"BrotherVoice": brother_heard}, floor_raw_stats())
		get_node("/root/Campaign").update_unlocks()
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/levels/level_02.tscn")
		return
	if event.is_action_pressed("retry") and not event.is_echo():
		get_tree().paused = false
		get_viewport().set_input_as_handled()
		get_tree().reload_current_scene()
	elif event.is_action_pressed("pause_game") and not completed:
		paused = not paused
		get_tree().paused = paused
		get_viewport().set_input_as_handled()
	elif not dialogue.is_empty() and not paused:
		if event.is_action_pressed("advance") or event.is_action_pressed("interact"):
			dialogue_index += 1
			if dialogue_index >= dialogue.size():
				finish_dialogue()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("skip"):
			finish_dialogue()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and not event.is_echo():
		interact()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Z and not controls_locked() and not player.is_dead:
		# Z: Miro thinks through what to do next, in his thought bubble.
		if is_instance_valid(world_features):
			world_features.think(z_hint())
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not paused:
		elapsed += delta
		update_stuck(delta)
		message_left = maxf(0, message_left - delta)
		shot_flash = maxf(0, shot_flash - delta)
	var pursuing := false
	var searching := false
	for guard in guards():
		if not guard.is_dead:
			pursuing = pursuing or (guard.sees_player and guard.alert_state == IntroGuard.State.ALERT)
			searching = searching or guard.alert_state == IntroGuard.State.SEARCH or guard.alert_state == IntroGuard.State.SUSPICIOUS
	if pursuing and not was_spotted and counts_detection():
		floor_detections += 1
	was_spotted = pursuing
	player.detection_state = "SPOTTED" if pursuing else ("HIDDEN" if player.is_concealed else ("SEARCHING / unseen" if searching else "UNSEEN"))
	var status := player.detection_state
	if player.has_key:
		status += " · KEY"
	var hearts := "[img=13x12]res://assets/misc/health_heart.png[/img] ".repeat(clampi(player.health, 0, 5))
	var health_text := "MIRO   " + hearts + "   " + status
	if health_label.text != health_text:
		health_label.text = health_text
	status_label.text = player.stealth_status() if player.has_supplies else ""
	objective_label.text = objective()
	hint_label.text = context_hint()
	hint_icon.texture = VISUALS.hint_texture(hint_label.text)
	if player.controls.pad_prompts:
		hint_label.text = hint_label.text.replace("[E]", "[Cross]").replace("[Z]", "[D-pad Up]")
	hint_icon.visible = hint_icon.texture != null
	stealth_meter.visible = player.has_supplies
	stealth_meter.value = player.stealth_remaining / player.stealth_duration if player.is_concealed else 1.0 - player.stealth_cooldown_left / player.stealth_cooldown
	message_label.text = message if message_left > 0 else ""
	dialogue_panel.visible = not dialogue.is_empty() and not paused
	if not dialogue.is_empty():
		var line: Array = dialogue[dialogue_index]
		var anchor := speaker_anchor(str(line[0]))
		dialogue_panel.actor = anchor
		var marked_thought: bool = line.size() > 2 and str(line[2]) == "thought"
		dialogue_panel.thought = str(line[0]) == "MIRO" and anchor == player and (marked_thought or is_thought_line(str(line[1])))
		var label := str(line[0])
		if anchor == player and str(line[0]) not in ["MIRO"]:
			label += " · remote" if str(line[0]) in ["NIRO", "THE VOICE", "BROTHER"] else ""
		dialogue_panel.speaker = label
		dialogue_label.text = str(line[1])
		dialogue_panel.follow_actor()
		# Niro's lines over the remote come out of the radio: bitcrushed, static, dropouts.
		var key := "%d:%s" % [dialogue_index, str(line[1])]
		if key != radio_line:
			radio_line = key
			var radio = get_node("/root/RemoteRadio")
			var niro_line := str(line[0]) in ["NIRO", "THE VOICE", "BROTHER", "A VOICE BEYOND THE BARS"]
			if niro_line and anchor == player:
				radio.say(str(line[1]))
			elif niro_line:
				radio.say_in_room(str(line[1]))
			elif str(line[0]) == "TOWER PA":
				radio.say_in_room(str(line[1]), "pa")
			elif str(line[0]) == "JUDAS":
				radio.say_in_room(str(line[1]), "judas")
			elif str(line[0]) in ["PRISONER", "THE PRISONER"]:
				radio.say_in_room(str(line[1]), "prisoner")
			elif str(line[0]) == "MIRO":
				radio.say_in_room(str(line[1]), "miro", "Thought" if dialogue_panel.thought else "Voice")
			else:
				radio.stop()
	elif not radio_line.is_empty():
		radio_line = ""
		get_node("/root/RemoteRadio").stop()
	# Paused: the pause menu (scripts/pause_menu.gd) covers the screen instead.
	overlay.visible = completed or player.is_dead
	if completed:
		if not crackle_played:
			# The remote crackles with his brother's voice as the floor report comes up.
			crackle_played = true
			get_node("/root/RemoteRadio").say(FLOOR_END_CRACKLE)
		var raw := floor_raw_stats()
		overlay_label.text = "THE PRISONER\n\nThe first mark is set. The remote crackles: \"...Miro?\"\n\nEscape: %s   ·   %s   ·   Kills %d   ·   Seen %d\n\n[Enter] Descend to Level 2\n[Backspace] Replay the floor" % [route, get_node("/root/Campaign").style_word(raw), raw.kills, raw.detections]
	elif player.is_dead:
		overlay_label.text = "THE TOWER KEEPS ITS PRISONERS\n\n[Backspace] Retry from the cell\nTry cover, a quiet key theft, or dodge the wind-up."
	queue_redraw()

## Z: Miro thinks it through. Up to three hints per objective, each press more direct
## (a nudge, then where, then exactly what to do), so a stuck player is never stuck for long.
var hint_tiers: Dictionary = {}
var stuck_key := ""
var stuck_time := 0.0
const STUCK_SECONDS := 60.0

const L1_HINTS := {
	"supplies": ["Something is hidden under my bed. I can feel the shape of it.",
		"The bed is right here in the cell. Stand at it.",
		"Walk to the bed in the cell and press E."],
	"door": ["Judas has a key. Or the lock could just stop existing.",
		"Wait for him to turn away and take the key [E]. Or set a charge on the lock: [2], right click.",
		"Stand behind Judas while he faces away and press E. Or select C4 [2], right click the lock, step back, left click."],
	"brother": ["The gallery leads to a barred gate. Someone's waiting there.",
		"Go right along the gallery, past the cells, to the bars.",
		"Walk right to the barred gate and press E."],
	"sigil": ["'Leave a mark.' Down where the tower holds itself up.",
		"Take the ladders down to the lowest floor.",
		"On the bottom floor, find the support and press E."],
	"exit": ["The stairs down. Lower right.",
		"Bottom floor, far right.",
		"Walk to the lower-right stair gate and press E."],
}

func hint_key() -> String:
	if not player.has_supplies:
		return "supplies"
	if not door_open:
		return "door"
	if not brother_heard:
		return "brother"
	if not sigil_placed:
		return "sigil"
	return "exit"

func hint_lines(key: String) -> Array:
	return L1_HINTS.get(key, [])

func z_hint() -> String:
	var key := hint_key()
	var lines: Array = hint_lines(key)
	if lines.is_empty():
		var goal := objective()
		if "\n" in goal:
			goal = goal.get_slice("\n", 1)
		return goal
	var tier := int(hint_tiers.get(key, 0))
	hint_tiers[key] = mini(tier + 1, lines.size() - 1)
	stuck_time = 0.0
	return str(lines[mini(tier, lines.size() - 1)])

## After a minute on the same objective, the bottom strip offers Z.
func update_stuck(delta: float) -> void:
	var key := hint_key()
	if key != stuck_key:
		stuck_key = key
		stuck_time = 0.0
	elif not controls_locked():
		stuck_time += delta

func stuck() -> bool:
	return stuck_time >= STUCK_SECONDS

func counts_detection() -> bool:
	return true

func floor_raw_stats() -> Dictionary:
	return {"kills": player.casualty_count, "detections": floor_detections, "stealth_bonus": stealth_bonus, "loud": loud_events}

func objective() -> String:
	if completed:
		return "01 / THE PRISONER   •   COMPLETE"
	if not player.has_supplies:
		return "01 / THE PRISONER\nSearch beneath your bed. [E]"
	if not door_open:
		return "Escape the cell\nSteal the key, use the shank, or breach the lock."
	if not brother_heard:
		return "Find a way down\nFollow the gallery to the barred gate."
	if not sigil_placed:
		return "Leave a mark\nDescend the ladders. Find the lower support."
	return "The way below\nReach the lower-right stair gate. [E]"

## Which character a forced line hangs over. Documents hang over the note being read.
func speaker_anchor(speaker: String) -> Node2D:
	match speaker:
		"MIRO":
			return player
		"JUDAS", "KEEPER":
			if has_node("Guards/CorruptKeeper"):
				return get_node("Guards/CorruptKeeper")
		"NIRO", "BROTHER":
			var boss = get("brother")
			if boss != null and is_instance_valid(boss):
				return boss
			return player
		"A VOICE BEYOND THE BARS":
			var gate = nearby("brother", 200)
			return gate if gate else player
		"THE VOICE":
			# His brother is never in the room as "The Voice": it always comes through the remote.
			return player
	var reading = nearby("note", 90)
	if reading == null:
		reading = nearby("sigil", 90)
	if reading == null:
		reading = nearby("brother", 90)
	return reading if reading else player

## Miro's lines in brackets or with no one to talk to read as thoughts.
func is_thought_line(text: String) -> bool:
	return text.begins_with("(") or speaker_listener() == null

func speaker_listener():
	for line in dialogue:
		if str(line[0]) != "MIRO":
			return line
	return null

func show_card(mode: String, heading: String, title_text: String, detail := "", accent := Color("c69fa5"), length := 3.4) -> void:
	if is_instance_valid(card):
		card.finish()
	card = Control.new()
	card.set_script(preload("res://scripts/floor_card.gd"))
	card.mode = mode
	card.heading = heading
	card.title_text = title_text
	card.detail = detail
	card.accent = accent
	card.length = length
	card.level = self
	hud.add_child(card)

func start_dialogue(lines: Array, event: String = "") -> void:
	dialogue = lines
	dialogue_index = 0
	dialogue_event = event
	player.velocity = Vector2.ZERO

func finish_dialogue() -> void:
	var event := dialogue_event
	dialogue = []
	dialogue_index = 0
	dialogue_event = ""
	if event == "intro":
		var guard: IntroGuard = $Guards/CorruptKeeper
		guard.illness_started = true
		guard.facing = 1
		guard.turn_wait = 4.0
		notify("Judas doubles over, coughing. Search your bed. [E]", 8)
	elif event == "brother":
		brother_heard = true

func guards() -> Array[Node]:
	return get_tree().get_nodes_in_group("guards")

func in_cover(point: Vector2) -> bool:
	var list := areas if is_instance_valid(areas) else get_node_or_null("Interactables")
	if not list:
		return false
	for area in list.get_children():
		if area.kind == "cover":
			var rect: Rect2 = Rect2(area.global_position - area.area_size / 2, area.area_size)
			var expanded := Rect2(rect.position.x - 6, rect.position.y - 45, rect.size.x + 12, rect.size.y + 45)
			if expanded.has_point(point):
				return true
	return false

func ladder_at(point: Vector2):
	for area in areas.get_children():
		if area.kind == "ladder" and area.contains(point):
			return area
	return null

func clear_sight(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func has_floor_below(point: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(point, point + Vector2(0, 22), 1)
	return not get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func can_melee_reach(from: Vector2, to: Vector2) -> bool:
	# The cell bars permit a reach-through attack on the nearby keeper.
	var lock_position: Vector2 = $Interactables/CellLock.global_position
	if not door_open and from.x < lock_position.x and to.x > lock_position.x and to.x < lock_position.x + 38 and absf(from.y - to.y) < 25 and absf(from.y - lock_position.y) < 40:
		return true
	return clear_sight(from, to)

func closest_guard(maximum: float = 45.0):
	var best = null
	var distance := maximum
	for guard in guards():
		var candidate: float = guard.global_position.distance_to(player.global_position)
		if candidate < distance and can_melee_reach(player.global_position, guard.global_position):
			distance = candidate
			best = guard
	return best

func nearby(kind: String, maximum: float = 48.0):
	for area in areas.get_children():
		if area.kind == kind and area.global_position.distance_to(player.global_position) < maximum:
			return area
	return null

func context_hint() -> String:
	if world_features and not world_features.hint().is_empty():
		return world_features.hint()
	if controls_locked() or player.is_dead:
		return ""
	if nearby("bed") and not player.has_supplies:
		return "[E] Search beneath the bed"
	var guard = world_features.nearest_loot() if world_features.loot_takes_priority() else closest_guard()
	if guard:
		if guard.is_dead and (not guard.gun_taken or (guard.sick_guard and not guard.key_taken)):
			return "[E] Search fallen Keeper"
		if guard.sick_guard and not guard.key_taken:
			return "[E] Pickpocket when he turns away   /   [1] Shank   /   [2] C4"
	if nearby("door", 65) and not door_open:
		return "[E] Unlock with key   /   [2] C4 with C4"
	if nearby("sigil"):
		return "The mark is set." if sigil_placed else "[E] Set your mark on the support"
	if nearby("exit", 65):
		return "[E] Descend" if sigil_placed else "Leave your mark at the support before descending."
	if nearby("brother", 75) and not brother_heard:
		return "[E] Listen at the barred gate"
	if nearby("note"):
		return "[E] Read the quarantine order"
	if player.is_concealed:
		return "Move carefully • touching a Keeper breaks stealth"
	if ladder_at(player.global_position):
		return "[W / S] Climb. Keepers cannot use ladders."
	if stuck():
		return "Not sure where to go? [Z] Think it through"
	return "A / D  Move    Space  Jump    C  Dash    Esc  Controls"

func interact() -> void:
	if controls_locked() or player.is_dead:
		return
	if player.controls.recover_charge():
		return
	if world_features and world_features.try_interact():
		return
	var bed = nearby("bed")
	if bed and not player.has_supplies:
		player.has_supplies = true
		player.c4_count = 4 # Three to use freely, one for the support below.
		bed.activated = true
		bed.queue_redraw()
		start_dialogue([
			["MIRO", "Wire. Powder. Two charges, hidden beneath the bed.\nI've been building these in secret. My hands remember; I don't."],
			["MIRO", "A sharpened spoon. My blanket. Something I scratched\non the wrapping: 'Leave a mark. Keep going down.'"],
			["MIRO", "His key, while he faces away [E]. The spoon for close work [1, left click].\nThe charges [2]: right click to set one, left click to blow it.", "thought"]
		])
		return
	var guard = world_features.nearest_loot() if world_features.loot_takes_priority() else closest_guard()
	if guard and ((guard.is_dead and (not guard.gun_taken or (guard.sick_guard and not guard.key_taken))) or (guard.sick_guard and not guard.key_taken)):
		if not player.has_supplies:
			notify("Gather your hidden supplies before leaving.")
			return
		if guard.is_dead:
			if guard.sick_guard and not guard.key_taken:
				player.has_key = true
				player.controls.collect_remote()
				guard.key_taken = true
				if route == "":
					route = "shank"
			if not guard.gun_taken:
				player.loot_weapon(guard)
			else:
				notify("Nothing else to take.")
		elif guard.facing * (player.global_position.x - guard.global_position.x) < -6 and guard.alert_state != IntroGuard.State.ALERT:
			guard.key_taken = true
			player.controls.collect_remote()
			player.has_key = true
			route = "pickpocket"
			stealth_bonus += 1
			notify("The key slips free. No one noticed. [E] at the lock to open it.")
		else:
			notify("He can see your hand. Wait until he turns his back.")
		return
	if nearby("door", 65) and not door_open:
		if player.has_key:
			open_door()
			notify("A quiet click. Shadow alcoves can hide you: select Q and click.", 7)
		else:
			notify("Locked. Steal the key from Judas, loot him, or use C4 [2].")
		return
	if nearby("brother", 75) and not brother_heard:
		start_brother()
		return
	if nearby("note"):
		start_dialogue([["QUARANTINE ORDER", "Keepers: report every cough, including your own.\nNo names. Record the cell numbers only.\nTransfer all marked prisoners to the lower ward."]])
		return
	if nearby("sigil") and not sigil_placed:
		if not player.has_supplies or player.c4_count < 1:
			notify("The materials are hidden beneath your bed.")
			return
		if not brother_heard:
			start_brother()
			return
		sigil_placed = true
		get_node("/root/SoundFX").play_sound("sigil", -16)
		player.c4_count -= 1
		var anchor = nearby("sigil")
		anchor.activated = true
		anchor.queue_redraw()
		make_noise(anchor.global_position, 240)
		start_dialogue([["MIRO", "This shape... I know it. My hands won't stop shaking.\nOne mark. Then down. Whoever wrote that wanted me to leave."]])
		return
	if nearby("exit", 65):
		if sigil_placed:
			completed = true
			player.velocity = Vector2.ZERO
		else:
			notify("'Leave a mark.' The support to the left feels familiar.")

func start_brother() -> void:
	var response := "You took his life. Was that necessary?" if player.casualty_count > 0 else "You got past him without killing. There is still time to stop."
	start_dialogue([
		["THE VOICE", "Miro. Please. Don't go any lower.\n%s" % response],
		["MIRO", "You know my name. Do I know you?"],
		["THE VOICE", "You used to. Stay there. Let me help you."],
		["MIRO", "That voice should mean something. It hurts that it doesn't.\nI can't stay here.", "thought"]
	], "brother")

func plant_c4() -> void:
	if controls_locked():
		return
	if not player.has_supplies:
		notify("The C4 is hidden beneath your bed. [E]")
	elif door_open:
		notify("Keep the remaining charge. Find the marked support below.")
	elif not nearby("door", 65):
		notify("Move close to the cell lock to place C4.")
	elif player.c4_count > 1:
		player.c4_count -= 1
		player.end_stealth()
		route = "C4 breach"
		loud_events += 1
		open_door()
		shot_flash = 0.4
		emit_effect("breach", $Interactables/CellLock.global_position)
		get_node("/root/SoundFX").play_sound("collapse", -20)
		make_noise(player.global_position, 700)
		notify("The lock bursts. Keepers heard it! Find shadow or fight your way through.", 7)

func open_door() -> void:
	get_node("/root/SoundFX").play_sound("gate", -17)
	door_open = true
	$CellDoor/CollisionShape2D.set_deferred("disabled", true)
	$Interactables/CellLock.activated = true
	$Interactables/CellLock.queue_redraw()

func make_noise(point: Vector2, radius: float) -> void:
	for guard in guards():
		if not guard.is_dead and guard.global_position.distance_to(point) < radius:
			guard.investigate(point)

func notify(text: String, duration: float = 4.0) -> void:
	message = text
	message_left = duration

func label_at(parent: Node, pos: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f2d3ab"))
	label.add_theme_color_override("font_shadow_color", Color("272744"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(label)
	return label

func panel_at(pos: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = pos
	panel.size = size
	panel.theme = VISUALS.ui_theme()
	panel.add_theme_stylebox_override("panel", VISUALS.panel_style())
	hud.add_child(panel)
	return panel

var pause_menu: CanvasLayer

func build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	pause_menu = CanvasLayer.new()
	pause_menu.set_script(preload("res://scripts/pause_menu.gd"))
	pause_menu.level = self
	add_child(pause_menu)
	var header := ColorRect.new()
	header.size = Vector2(640, 48)
	header.color = Color(0.15, 0.15, 0.26, 0.92)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(header)
	var inventory := Control.new()
	inventory.set_script(preload("res://scripts/weapon_inventory.gd"))
	inventory.player = player
	inventory.position = Vector2(14, 55)
	inventory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(inventory)
	health_label = RichTextLabel.new()
	health_label.position = Vector2(14, 10)
	health_label.size = Vector2(348, 18)
	health_label.bbcode_enabled = true
	health_label.scroll_active = false
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_label.add_theme_font_size_override("normal_font_size", 11)
	hud.add_child(health_label)
	status_label = label_at(hud, Vector2(14, 26), Vector2(348, 16), 11)
	status_label.clip_text = true
	objective_label = label_at(hud, Vector2(370, 10), Vector2(254, 48), 11)
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_icon = TextureRect.new()
	hint_icon.position = Vector2(12, 329)
	hint_icon.size = Vector2(24, 24)
	hint_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hint_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud.add_child(hint_icon)
	hint_label = label_at(hud, Vector2(42, 333), Vector2(584, 22), 11)
	stealth_meter = Control.new()
	stealth_meter.set_script(preload("res://scripts/stealth_meter.gd"))
	stealth_meter.position = Vector2(245, 42)
	stealth_meter.size = Vector2(104, 4)
	hud.add_child(stealth_meter)
	message_label = label_at(hud, Vector2(14, 295), Vector2(612, 34), 11)
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Forced dialogue lives in a bubble beside the speaker so Miro and the play area stay visible.
	# The bottom of the screen is reserved for the objective cue line and short notices.
	dialogue_panel = Control.new()
	dialogue_panel.set_script(preload("res://scripts/character_bubble.gd"))
	dialogue_panel.dialogue = true
	hud.add_child(dialogue_panel)
	dialogue_panel.visible = false
	dialogue_label = dialogue_panel.text_label
	overlay = panel_at(Vector2(45, 65), Vector2(550, 240))
	overlay_label = label_at(overlay, Vector2.ZERO, Vector2(510, 200), 13)
	overlay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _draw() -> void:
	if shot_flash > 0:
		draw_circle(to_local($Interactables/CellLock.global_position), (0.4 - shot_flash) * 160, Color(0.95, 0.83, 0.67, shot_flash))

func setup_world_features(number: int) -> void:
	effects = Node2D.new()
	effects.set_script(preload("res://scripts/visual_effects.gd"))
	add_child(effects)
	effects.level = self
	world_features = Node2D.new()
	world_features.set_script(load("res://scripts/world_features.gd"))
	add_child(world_features)
	world_features.setup(self, number)
	get_node("/root/MusicDirector").start_floor(number)

func emit_effect(cue: String, point: Vector2) -> void:
	if is_instance_valid(effects):
		effects.emit_burst(cue, point)
