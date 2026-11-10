extends Node
## Sound for cutscenes: one-shots, fading loops and timed cues, on the Effects bus.
## Files live in res://assets/audio/cine/ (see tools/synth_cine_audio.py and
## tools/generate_cine_sfx_elevenlabs.py). A missing file is skipped silently.
const DIR := "res://assets/audio/cine/%s"
var cues: Array = []
const EFFECTS_TRIM_DB := -4.0

## Field recordings ship as .wav (rain, thunder); everything else is .ogg.
static func stream(id: String) -> AudioStream:
	for extension in [".wav", ".ogg"]:
		var path: String = (DIR % id) + extension
		if ResourceLoader.exists(path):
			return load(path)
	return null

static func audible() -> bool:
	return DisplayServer.get_name() != "headless"

## Fire `action` once when `clock` passes `time` (call tick(clock) every frame).
func at(time: float, action: Callable) -> void:
	cues.append([time, action])

func tick(clock: float) -> void:
	if cues.is_empty(): return
	for cue in cues.duplicate():
		if clock >= cue[0]:
			cues.erase(cue)
			cue[1].call()

func play(id: String, volume_db := -6.0, pitch := 1.0) -> AudioStreamPlayer:
	var source := stream(id)
	if source == null:
		return null
	var player := AudioStreamPlayer.new()
	player.bus = "Effects"
	player.stream = source
	player.volume_db = volume_db + EFFECTS_TRIM_DB
	player.pitch_scale = pitch
	add_child(player)
	if audible():
		player.play()
	player.finished.connect(player.queue_free)
	return player

## A looping bed that fades in over `fade_in` seconds.
func loop(id: String, volume_db := -10.0, fade_in := 1.0, bus := "Effects") -> AudioStreamPlayer:
	var source := stream(id)
	if source == null:
		return null
	source = source.duplicate()
	if source is AudioStreamWAV:
		source.loop_mode = AudioStreamWAV.LOOP_FORWARD
		source.loop_begin = 0
		source.loop_end = int(source.get_length() * source.mix_rate)
	else:
		source.loop = true
	var player := AudioStreamPlayer.new()
	player.bus = bus
	player.stream = source
	player.volume_db = -60.0
	add_child(player)
	if audible():
		player.play()
	fade(player, volume_db, fade_in)
	return player

func fade(player: AudioStreamPlayer, to_db: float, seconds: float, free_after := false) -> void:
	if player == null:
		return
	if player.bus == &"Effects": to_db += EFFECTS_TRIM_DB
	var tween := player.create_tween()
	tween.tween_property(player, "volume_db", to_db, maxf(0.01, seconds))
	if free_after:
		tween.tween_callback(player.queue_free)

## Moves a loop to the scene root so it keeps playing across a scene change, then fades it out.
func hand_off(player: AudioStreamPlayer, seconds: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var position := player.get_playback_position()
	var playing := player.playing
	player.get_parent().remove_child(player)
	get_tree().root.add_child(player)
	if playing:
		player.play(position)
	fade(player, -60.0, seconds, true)
