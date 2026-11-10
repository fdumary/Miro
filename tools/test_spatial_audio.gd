extends SceneTree
const SOURCE=preload("res://scripts/world_audio_source.gd")
var checks:=0
var failures:Array[String]=[]
class Fixture extends Node2D:
	var player:Node2D
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok: failures.append(message)
	print("PASS: " if ok else "FAIL: ",message)
func run() -> void:
	var spatial=root.get_node("SpatialAudio")
	check(spatial.audio_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "3D audio does not add a 3D rendering pass")
	var baseline:int=spatial.audio_viewport.get_child_count()
	var fixture:=Fixture.new()
	fixture.player=Node2D.new()
	fixture.add_child(fixture.player)
	fixture.player.position=Vector2(300,400)
	root.add_child(fixture)
	current_scene=fixture
	spatial._physics_process(1.0/60.0)
	check(spatial.listener.is_current(),"3D listener is active in the audio-only viewport")
	check(spatial.listener.position.is_equal_approx(Vector3(3,-4,0.1)),"Audio listener follows Miro's world position")
	var voice=SOURCE.new()
	voice.position=Vector2(200,400)
	voice.bus="Voice"
	fixture.add_child(voice)
	voice.update_source()
	check(voice.source is AudioStreamPlayer3D,"World voice uses the native 3D audio panner")
	check(voice.source.position.is_equal_approx(Vector3(2,-4,0)),"World source maps left/right and height consistently")
	check(voice.source.bus == &"Voice","Spatial speech respects the Voice mixer bus")
	var near:float=voice.source.volume_db
	voice.position=Vector2(700,400)
	voice.update_source()
	check(voice.source.volume_db < near,"World sounds become quieter with distance")
	check(root.get_node("SoundFX").spatial_voices.size()==8,"Spatial SFX use a fixed eight-source pool")
	fixture.queue_free()
	await process_frame
	await process_frame
	await process_frame
	check(spatial.audio_viewport.get_child_count()==baseline,"Freeing a level releases its 3D audio sources")
	print("SPATIAL_AUDIO_RESULT: ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
