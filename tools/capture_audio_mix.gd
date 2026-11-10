extends SceneTree
class CineLevel extends Node2D:
	var paused := false
	var hud: CanvasLayer
var level
var recorder: AudioEffectRecord
var events: Array = []
func _initialize() -> void: call_deferred("run")
func wait_seconds(seconds: float) -> void: await create_timer(seconds).timeout
func record_start() -> void:
	recorder.set_recording_active(true)
func record_end(name_: String) -> void:
	recorder.set_recording_active(false)
	var wav := recorder.get_recording()
	wav.save_to_wav("res://tmp/performance/"+name_.replace("mix_", "mix_final_")+".wav")
	events.append({"segment":name_,"seconds":wav.get_length()})
func run() -> void:
	root.get_node("ControllerSettings").preferences.speaker_enabled=false
	root.get_node("SoundFX").muted=false
	for bus in range(AudioServer.bus_count): AudioServer.set_bus_mute(bus,false)
	AudioServer.set_bus_mute(0,false)
	AudioServer.set_bus_volume_db(0,0)
	recorder=AudioEffectRecord.new()
	recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder)
	for variant in ["original","candidate"]:
		seed(50709700)
		root.get_node("Campaign").checkpoint.clear()
		root.get_node("Campaign").carried_kit.clear()
		root.get_node("MusicDirector").section_id=""
		root.get_node("RemoteRadio").stop()
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),-6.0 if variant == "original" else -4.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"),0.0 if variant == "original" else -1.0)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"),0.0 if variant == "original" else -1.0)
		level=load("res://scenes/levels/level_03.tscn").instantiate()
		root.add_child(level)
		current_scene=level
		await wait_seconds(1)
		while not level.dialogue.is_empty(): level.finish_dialogue()
		level.player.health=10000
		level.player.has_supplies=true
		var director=root.get_node("MusicDirector")
		director.play_track("bobblehead")
		await wait_seconds(2)
		level.world_features.set_process(false)
		level.world_features.voice.stop()
		level.world_features.thought_voice.stop()
		root.get_node("RemoteRadio").stop()
		director.duck_db=0
		director.stealth_db=0
		director.voices[director.active].seek(15.0)
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"),true)
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Voice"),true)
		record_start()
		await wait_seconds(12)
		record_end("mix_"+variant+"_music")
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Effects"),false)
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Voice"),false)
		level.world_features.set_process(true)
		var p=level.player
		p.position=Vector2(350,432)
		p.has_gun=true
		p.guns.assign(["smg"])
		p.equipped_gun="smg"
		p.ammunition=1000
		p.mouse_aim=false
		p.facing=1
		p.controls.active="smg"
		for guard in level.guards(): guard.health=10000
		record_start()
		for i in range(80):
			p.health=10000
			while not level.dialogue.is_empty(): level.finish_dialogue()
			p.fire_gun()
			await wait_seconds(0.15)
		record_end("mix_"+variant+"_combat")
		level.start_dialogue([["NIRO","If you go any lower, I can't protect you."],["NIRO","You've read it by now. Miro, please... let me explain."]],"mix_test")
		record_start()
		await wait_seconds(5)
		level.dialogue_index=1
		await wait_seconds(5)
		record_end("mix_"+variant+"_speech")
		level.queue_free()
		await process_frame
		await process_frame
		root.get_node("RemoteRadio").stop()
		var opening=load("res://scenes/opening_cinematic.tscn").instantiate()
		root.add_child(opening)
		current_scene=opening
		record_start()
		await wait_seconds(14.0)
		record_end("mix_"+variant+"_opening")
		opening.queue_free()
		await process_frame
		await process_frame
		root.get_node("RemoteRadio").stop()
		director.silence()
		await wait_seconds(1.6)
		var cine_level:=CineLevel.new()
		cine_level.hud=CanvasLayer.new()
		cine_level.add_child(cine_level.hud)
		root.add_child(cine_level)
		var ending=load("res://scenes/ending_cinematic.tscn").instantiate()
		ending.level=cine_level
		cine_level.hud.add_child(ending)
		current_scene=cine_level
		record_start()
		await wait_seconds(14.0)
		record_end("mix_"+variant+"_ending")
		cine_level.queue_free()
		await process_frame
		await process_frame
		var chords=root.get_node_or_null("EndingChords")
		if is_instance_valid(chords): chords.queue_free()
		print("AUDIO_MIX_VARIANT_COMPLETE ",variant)
	var file=FileAccess.open("res://tmp/performance/mix-captures-final.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(events,"\t"))
	file.close()
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	quit()
