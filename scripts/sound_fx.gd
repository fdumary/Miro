extends Node
## Small bounded pool for licensed Kenney effects. No gameplay state depends on audio.
var muted := false
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cue in ["step", "swing", "hit", "gate", "sigil", "shot", "collapse"]:
		streams[cue] = load("res://assets/audio/%s.ogg" % cue)
	streams["flame"] = preload("res://assets/audio/flame.wav")
	for index in range(8):
		var voice := AudioStreamPlayer.new()
		voice.bus = "Effects"
		voice.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(voice)
		voices.append(voice)
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

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	voices.clear()
	streams.clear()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
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
