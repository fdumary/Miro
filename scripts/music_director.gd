extends Node
## Offline soundtrack playback. Two voices crossfade; no API calls at runtime.
## Also the game's beat clock: emits beat/bar from the playing track so patrols,
## waves and boss telegraphs can land on the music (docs/STORY_AND_SYSTEMS_IMPLEMENTATION.md).
signal beat(index: int)
signal bar(index: int)
signal track_changed(id: String)
var catalog: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var active := 0
var track_id := ""
var section_id := ""
var fade_progress := 1.0
var duck_db := 0.0
var review_override := false
var pending_track := ""
var pending_wait := 0.0
var track_time := 0.0
var last_beat := -1
var lowpass: AudioEffectLowPassFilter
var stealth_db := 0.0
# Approved order (Ethan, 7 Nov 2026). Level 5 is near-silent until the guitar pickup.
const FIRST := {1: "yz33", 2: "dope2", 3: "bobblehead", 4: "plane_drums", 5: ""}
const SECOND := {2: "swag", 3: "cyberpunk", 4: "sumcrazy", 5: "robot_attack"}
const GUITAR_TRACK := "shit_crashed"
const OUTRO_TRACK := "set_me_free"
const MENU_COMPLETED_TRACK := "lil_uzi2"
const BEATS_PER_BAR := 4
const OPEN_CUTOFF := 20500.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "Effects", "Voice"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	for bus in ["Music", "Effects", "Voice"]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), config.get_value("audio", bus, -6.0 if bus == "Music" else 0.0))
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/music/runtime_catalog.json")).tracks
	lowpass = AudioEffectLowPassFilter.new()
	lowpass.cutoff_hz = OPEN_CUTOFF
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), lowpass)
	for index in range(2):
		var voice := AudioStreamPlayer.new()
		voice.bus = "Music"
		voice.volume_db = -80
		voice.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(voice)
		voices.append(voice)

func set_volume(bus: String, db: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), db)
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", bus, db)
	config.save("user://settings.cfg")

func start_floor(number: int) -> void:
	review_override = false
	pending_track = ""
	section_id = "floor_%d_entry" % number
	if FIRST[number].is_empty():
		silence()
	else:
		play_track(FIRST[number])

func second_section(number: int) -> void:
	if review_override or section_id == "floor_%d_second" % number or not SECOND.has(number):
		return
	section_id = "floor_%d_second" % number
	queue_track(SECOND[number])

## Level 5: picking up the guitar starts Shit Crashed at once (the pickup is the downbeat).
func guitar_section() -> void:
	if review_override or section_id == "floor_5_guitar":
		return
	section_id = "floor_5_guitar"
	pending_track = ""
	play_track(GUITAR_TRACK)

func play_outro() -> void:
	review_override = false
	pending_track = ""
	section_id = "outro"
	play_track(OUTRO_TRACK, false)

## Switch on the next bar line of the current track (at most one bar of wait).
func queue_track(id: String) -> void:
	if id == track_id or not catalog.has(id):
		return
	if track_id.is_empty() or bpm() <= 0:
		play_track(id)
		return
	pending_track = id
	pending_wait = seconds_to_next_bar()

func play_track(id: String, loop := true) -> void:
	if id == track_id:
		return
	if not catalog.has(id):
		return
	pending_track = ""
	track_id = id
	active = 1 - active
	voices[active].stop()
	var stream = load(catalog[id].stream).duplicate()
	stream.loop = loop
	voices[active].stream = stream
	voices[active].volume_db = -80
	if DisplayServer.get_name() != "headless":
		voices[active].play()
	fade_progress = 0
	track_time = 0.0
	last_beat = -1
	track_changed.emit(id)

func silence() -> void:
	track_id = ""
	pending_track = ""
	fade_progress = 0

func bpm() -> float:
	return float(catalog.get(track_id, {}).get("bpm", 0.0))

func seconds_per_beat() -> float:
	return 60.0 / bpm() if bpm() > 0 else 0.5

func seconds_per_bar() -> float:
	return seconds_per_beat() * BEATS_PER_BAR

## Position in beats. Uses the audio clock when the track is audible, else a pause-aware game clock.
func beat_position() -> float:
	if track_id.is_empty() or bpm() <= 0:
		return -1.0
	var seconds := track_time
	var voice: AudioStreamPlayer = voices[active] if not voices.is_empty() else null
	if voice and voice.playing:
		seconds = voice.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return maxf(0.0, seconds) / seconds_per_beat()

func seconds_to_next_bar() -> float:
	var position := beat_position()
	if position < 0:
		return 0.0
	var into_bar := fmod(position, BEATS_PER_BAR)
	return (BEATS_PER_BAR - into_bar) * seconds_per_beat() if into_bar > 0.001 else 0.0

func is_on_beat(window := 0.12) -> bool:
	var position := beat_position()
	if position < 0:
		return false
	var offset := fmod(position, 1.0)
	return minf(offset, 1.0 - offset) * seconds_per_beat() <= window

func _process(delta: float) -> void:
	if voices.is_empty() or get_tree().paused:
		return
	if not track_id.is_empty():
		track_time += delta
		var whole := int(floor(beat_position()))
		if whole != last_beat and whole >= 0:
			last_beat = whole
			beat.emit(whole)
			if whole % BEATS_PER_BAR == 0:
				bar.emit(whole / BEATS_PER_BAR)
	if not pending_track.is_empty():
		pending_wait -= delta
		if pending_wait <= 0:
			play_track(pending_track)
	var scene = get_tree().current_scene
	var spoken := false
	var hidden := false
	var uneasy := false
	if is_instance_valid(scene) and scene.has_method("controls_locked"):
		spoken = not scene.dialogue.is_empty()
		if scene.get("world_features") != null:
			spoken = spoken or scene.world_features.voice_audible()
		var player = scene.get("player")
		if is_instance_valid(player):
			hidden = player.is_concealed or player.in_hiding_spot
			uneasy = str(player.detection_state).begins_with("SEARCHING")
	duck_db = move_toward(duck_db, -8.0 if spoken else 0.0, delta * (24 if spoken else 6))
	# Under the blanket the music is under it too: low-pass and -3 dB. Suspicion opens it a little.
	var cutoff := 800.0 if hidden else (2600.0 if uneasy else OPEN_CUTOFF)
	lowpass.cutoff_hz = lerpf(lowpass.cutoff_hz, cutoff, minf(1.0, delta * 6.0))
	stealth_db = move_toward(stealth_db, -3.0 if hidden else 0.0, delta * 9)
	fade_progress = minf(1, fade_progress + delta / 1.5)
	for index in range(2):
		var gain := fade_progress if index == active and not track_id.is_empty() else 1 - fade_progress
		voices[index].volume_db = linear_to_db(maxf(0.0001, gain)) + duck_db + stealth_db
		if gain <= 0 and voices[index].playing:
			voices[index].stop()

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	voices.clear()
