extends SceneTree
var intervals: Array = []
var previous := 0
var stage := "initializing"
func _process(_delta: float) -> bool:
	var now := Time.get_ticks_usec()
	if previous > 0: intervals.append({"stage":stage,"interval_ms":(now-previous)/1000.0})
	previous=now
	return false
class CineLevel extends Node2D:
	var paused:=false
	var hud:CanvasLayer
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for index in range(AudioServer.bus_count):AudioServer.set_bus_mute(index,false)
	AudioServer.set_bus_volume_db(0,0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),-4)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"),-2)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"),-1)
	root.get_node("SoundFX").muted=false
	root.get_node("ControllerSettings").preferences.speaker_enabled=false
	var recorder:=AudioEffectRecord.new()
	recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder)
	stage="opening"
	var opening=load("res://scenes/opening_cinematic.tscn").instantiate()
	root.add_child(opening)
	current_scene=opening
	recorder.set_recording_active(true)
	await create_timer(14).timeout
	recorder.set_recording_active(false)
	recorder.get_recording().save_to_wav("res://tmp/performance/mix_verified_opening.wav")
	opening.queue_free()
	await process_frame
	root.get_node("RemoteRadio").stop()
	root.get_node("MusicDirector").silence()
	await create_timer(1.6).timeout
	var level:=CineLevel.new()
	level.hud=CanvasLayer.new()
	level.add_child(level.hud)
	root.add_child(level)
	stage="ending"
	var ending=load("res://scenes/ending_cinematic.tscn").instantiate()
	ending.level=level
	level.hud.add_child(ending)
	current_scene=level
	recorder.set_recording_active(true)
	await create_timer(14).timeout
	recorder.set_recording_active(false)
	recorder.get_recording().save_to_wav("res://tmp/performance/mix_verified_ending.wav")
	level.queue_free()
	await process_frame
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var f:=FileAccess.open("C:/Users/ethan/Miro/tmp/performance/cinematic-frames.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(intervals))
	print("CINEMATIC_MIX_CAPTURED")
	quit()
