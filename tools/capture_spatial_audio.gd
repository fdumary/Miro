extends SceneTree
const SOURCE=preload("res://scripts/world_audio_source.gd")
var results:Array=[]
class Fixture extends Node2D:
	var player:Node2D
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	results.append({"pass":ok,"message":message})
	print("PASS: " if ok else "FAIL: ",message)
func rms(wav:AudioStreamWAV) -> Vector2:
	var energy:=Vector2.ZERO
	var data := wav.data
	var frames:=data.size()/4
	for i in range(frames):
		var l:=float(data.decode_s16(i*4))/32768.0
		var r:=float(data.decode_s16(i*4+2))/32768.0
		energy+=Vector2(l*l,r*r)
	return Vector2(sqrt(energy.x/maxi(1,frames)),sqrt(energy.y/maxi(1,frames)))
func run() -> void:
	for index in range(AudioServer.bus_count): AudioServer.set_bus_mute(index,false)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Effects"),0)
	AudioServer.set_bus_mute(0,false)
	AudioServer.set_bus_volume_db(0,0)
	var fixture:=Fixture.new()
	fixture.player=Node2D.new()
	fixture.add_child(fixture.player)
	root.add_child(fixture)
	current_scene=fixture
	var recorder:=AudioEffectRecord.new()
	recorder.format=AudioStreamWAV.FORMAT_16_BITS
	AudioServer.add_bus_effect(0,recorder)
	var tone:=AudioStreamWAV.new()
	tone.format=AudioStreamWAV.FORMAT_16_BITS
	tone.mix_rate=44100
	tone.loop_mode=AudioStreamWAV.LOOP_FORWARD
	tone.loop_end=44100
	var samples:=PackedByteArray()
	samples.resize(88200)
	for i in range(44100): samples.encode_s16(i*2,roundi(sin(TAU*440.0*i/44100.0)*3000.0))
	tone.data=samples
	var voice=SOURCE.new()
	voice.stream=tone
	voice.bus="Effects"
	fixture.add_child(voice)
	await create_timer(0.1).timeout
	var levels:Dictionary={}
	for spec in [["left",Vector2(-150,0)],["right",Vector2(150,0)],["near",Vector2(30,0)],["far",Vector2(450,0)]]:
		voice.stop()
		voice.position=spec[1]
		voice.play()
		await create_timer(0.15).timeout
		recorder.set_recording_active(true)
		await create_timer(1.0).timeout
		recorder.set_recording_active(false)
		var wav:=recorder.get_recording()
		wav.save_to_wav("res://tmp/performance/spatial_"+str(spec[0])+".wav")
		levels[spec[0]]=rms(wav)
		results.append({"playing":voice.source.playing,"playback_seconds":voice.source.get_playback_position(),"source_db":voice.source.volume_db,"bus_db":AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Effects")),"listener_current":root.get_node("SpatialAudio").listener.is_current(),"stereo":wav.stereo,"format":wav.format,"event":spec[0],"left_rms":levels[spec[0]].x,"right_rms":levels[spec[0]].y})
	check(levels.left.x>levels.left.y*1.15,"Left world source is louder in the left output channel")
	check(levels.right.y>levels.right.x*1.15,"Right world source is louder in the right output channel")
	check(levels.far.length()<levels.near.length()*0.7,"Far world source is quieter than near source")
	check(voice.source.playing and voice.source.get_playback_position()>0.0,"Spatial playback is active before pause check")
	var before:float=voice.source.get_playback_position()
	paused=true
	await create_timer(0.2,true).timeout
	var after:float=voice.source.get_playback_position()
	check(absf(after-before)<0.03,"Tree pause holds actual spatial audio playback position")
	paused=false
	voice.stop()
	fixture.queue_free()
	await process_frame
	await process_frame
	await process_frame
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	var file=FileAccess.open("res://tmp/performance/spatial-native-verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	file.close()
	var count:=0
	for result in results:
		if result.has("pass") and not result.pass: count+=1
	print("SPATIAL_NATIVE_RESULT: ",count," failures")
	quit(0 if count==0 else 1)
