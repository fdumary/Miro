extends Node
## Small bounded pool for licensed Kenney effects. No gameplay state depends on audio.
var muted := false
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var streams: Dictionary = {}
var spatial_voices: Array[Node2D] = []
var next_spatial_voice := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cue in ["step", "swing", "hit", "gate", "sigil", "shot", "collapse"]:
		streams[cue] = load("res://assets/audio/%s.ogg" % cue)
	streams["flame"] = preload("res://assets/audio/flame.wav")
	# Sick Keepers and prisoners cough (synthesized; replace the files with any .wav/.ogg of the same name).
	for index in range(1, 4):
		for extension in ["ogg", "mp3", "wav"]:
			var path := "res://assets/audio/cough_%d.%s" % [index, extension]
			if ResourceLoader.exists(path):
				streams["cough_%d" % index] = load(path)
				break
	for index in range(8):
		var voice := AudioStreamPlayer.new()
		voice.bus = "Effects"
		voice.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(voice)
		voices.append(voice)
	if "--controller-radio-worker" not in OS.get_cmdline_user_args():
		for index in range(8):
			var spatial_voice := preload("res://scripts/world_audio_source.gd").new()
			spatial_voice.linear_db_drop=22.0
			add_child(spatial_voice)
			spatial_voices.append(spatial_voice)
	var settings := ConfigFile.new()
	if settings.load("user://settings.cfg") == OK:
		muted = settings.get_value("audio", "muted", false)
	AudioServer.set_bus_mute(0, muted)

func play_sound(cue: String, volume_db: float = -16, pitch: float = 1.0) -> void:
	# Headless QA still loads/validates assets but has no audible output device.
	if muted or DisplayServer.get_name() == "headless" or not streams.has(cue):
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = streams[cue]
	voice.volume_db = volume_db
	voice.pitch_scale = pitch
	voice.play()

## A sound from the world: quieter with distance from the listener, silent beyond `reach`.
func play_near(cue: String, from: Vector2, listener: Vector2, base_db := -8.0, reach := 560.0, pitch := 1.0) -> void:
	var distance := from.distance_to(listener)
	if distance >= reach:
		return
	if muted or DisplayServer.get_name() == "headless" or not streams.has(cue) or spatial_voices.is_empty(): return
	var voice=spatial_voices[next_spatial_voice]
	next_spatial_voice=(next_spatial_voice+1)%spatial_voices.size()
	voice.stop()
	voice.global_position=from
	voice.max_distance=reach
	voice.stream=streams[cue]
	voice.volume_db=base_db
	voice.pitch_scale=pitch
	voice.play()

func cough_near(from: Vector2, listener: Vector2, variation: int) -> void:
	play_near("cough_%d" % (1 + posmod(variation, 3)), from, listener, -9.0, 560.0, 0.92 + 0.04 * posmod(variation, 4))

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	voices.clear()
	spatial_voices.clear()
	streams.clear()

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(get_node("/root/InputBindings").panel) and event.is_pressed() and get_node("/root/InputBindings").matches(event,"mute"):
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
		var settings := ConfigFile.new()
		settings.load("user://settings.cfg")
		settings.set_value("audio", "muted", muted)
		settings.save("user://settings.cfg")
		get_viewport().set_input_as_handled()
		var level = get_tree().current_scene
		if level and level.has_method("notify"):
			level.notify("Sound muted. [M]" if muted else "Sound enabled. [M]")
