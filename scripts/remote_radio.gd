extends Node
## Niro's voice through Miro's hacked remote / MP3 player (Ethan, 7 Nov 2026):
## band-limited, bitcrushed, with a static bed and short dropouts, so it always sounds
## like it is coming out of a cheap speaker rather than from the room.
## Clips: res://assets/audio/voice/niro_<sha1(text)[0:10]>.mp3 (tools/generate_voices.py).
## Without a clip the line still shows; only the static plays.
const BUS := "Radio"
const STATIC_RATE := 22050.0
var voice: AudioStreamPlayer
var room: AudioStreamPlayer
var hiss: AudioStreamPlayer
var hiss_playback: AudioStreamGeneratorPlayback
var speaking_left := 0.0
var burst_left := 0.0
var clock := 0.0
var noise_state := 22695477
var last_text := ""
var controller_worker := false
var controller_playing := false
var controller_link = preload("res://scripts/controller_radio_link.gd").new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	controller_worker = "--controller-radio-worker" in OS.get_cmdline_user_args()
	if AudioServer.get_bus_index(BUS) < 0:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, BUS)
		AudioServer.set_bus_send(index, "Voice" if AudioServer.get_bus_index("Voice") >= 0 else "Master")
		var low_cut := AudioEffectHighPassFilter.new()
		low_cut.cutoff_hz = 420
		AudioServer.add_bus_effect(index, low_cut)
		var high_cut := AudioEffectLowPassFilter.new()
		high_cut.cutoff_hz = 3400
		AudioServer.add_bus_effect(index, high_cut)
		# LOFI distortion is Godot's bitcrusher: it quantises the signal into a crumbled, 8-bit edge.
		var crush := AudioEffectDistortion.new()
		crush.mode = AudioEffectDistortion.MODE_LOFI
		crush.drive = 0.62
		crush.pre_gain = 6.0
		crush.post_gain = -7.0
		crush.keep_hf_hz = 3200
		AudioServer.add_bus_effect(index, crush)
		var grit := AudioEffectDistortion.new()
		grit.mode = AudioEffectDistortion.MODE_OVERDRIVE
		grit.drive = 0.35
		grit.post_gain = -3.0
		AudioServer.add_bus_effect(index, grit)
	voice = AudioStreamPlayer.new()
	voice.bus = BUS
	voice.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(voice)
	room = AudioStreamPlayer.new()
	room.bus = "Voice"
	room.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(room)
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = STATIC_RATE
	generator.buffer_length = 0.25
	hiss = AudioStreamPlayer.new()
	hiss.stream = generator
	hiss.bus = BUS
	hiss.volume_db = -14
	hiss.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(hiss)

static func clip_path(text: String, prefix := "niro") -> String:
	return "res://assets/audio/voice/%s_%s.mp3" % [prefix, text.strip_edges().sha1_text().substr(0, 10)]

static func has_clip(text: String, prefix := "niro") -> bool:
	return ResourceLoader.exists(clip_path(text, prefix))

## Same clips, no radio: Niro face to face, the tower PA, Judas, or Miro himself
## (his thoughts go through the reverb "Thought" bus).
func say_in_room(text: String, prefix := "niro", bus := "Voice") -> void:
	stop()
	if has_clip(text, prefix) and audible():
		room.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Voice"
		room.stream = load(clip_path(text, prefix))
		room.play()

## Plays one line over the remote. Returns how long it lasts, so a bubble can match it.
func say(text: String) -> float:
	last_text = text
	var duration := maxf(2.2, text.length() * 0.06)
	stop_remote_audio()
	if has_clip(text):
		voice.stream = load(clip_path(text))
		duration = voice.stream.get_length()
		controller_playing = not controller_worker and controller_link.send(["say", text])
		if not controller_playing and audible():
			voice.play()
	speaking_left = duration
	burst_left = 0.22
	if not controller_playing:
		start_hiss()
	return duration

func start_hiss() -> void:
	if audible() and not hiss.playing:
		hiss.play()
		hiss_playback = hiss.get_stream_playback()

func stop_remote_audio() -> void:
	if controller_playing:
		controller_link.send(["stop"])
	controller_playing = false
	voice.stop()
	hiss.stop()
	hiss_playback = null

func stop() -> void:
	stop_remote_audio()
	speaking_left = 0
	burst_left = 0.0
	if is_instance_valid(room):
		room.stop()

func _exit_tree() -> void:
	controller_link.close()

func busy() -> bool:
	return speaking_left > 0

func audible() -> bool:
	return controller_worker or DisplayServer.get_name() != "headless"

## Deterministic noise (no RNG state shared with gameplay).
func noise() -> float:
	noise_state = (noise_state * 1103515245 + 12345) & 0x7fffffff
	return float(noise_state) / float(0x3fffffff) - 1.0

func _process(delta: float) -> void:
	if not controller_worker:
		var config: Dictionary = get_node("/root/ControllerSettings").preferences
		controller_link.update(delta, get_tree().paused, config.speaker_enabled, config.speaker_endpoint)
		if controller_playing and not controller_link.ready:
			controller_playing = false
			if speaking_left > 0.0 and audible() and voice.stream != null:
				voice.play(maxf(0.0, voice.stream.get_length() - speaking_left))
				start_hiss()
	if get_tree().paused:
		return
	clock += delta
	speaking_left = maxf(0, speaking_left - delta)
	burst_left = maxf(0, burst_left - delta)
	# Dropouts: the signal cuts and warps for a few frames on a fixed stutter pattern.
	var phase := fmod(clock, 1.37)
	var dropout := voice.playing and (phase < 0.05 or (phase > 0.71 and phase < 0.74))
	voice.volume_db = -26.0 if dropout else 0.0
	voice.pitch_scale = 0.93 if dropout else 1.0
	if hiss_playback == null:
		return
	var level := 0.0
	if burst_left > 0 or dropout:
		level = 0.32
	elif speaking_left > 0:
		level = 0.05
	var frames := hiss_playback.get_frames_available()
	for i in range(frames):
		var sample := noise() * level
		hiss_playback.push_frame(Vector2(sample, sample))
