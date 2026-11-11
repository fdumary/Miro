extends SceneTree
const SOURCE=preload("res://scripts/world_audio_source.gd")
class Fixture extends Node2D:
 var player:Node2D
var checks:=0
var failures:Array[String]=[]
var capture:AudioEffectCapture
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func settle() -> void:
 for i in range(24):OS.delay_msec(10);await process_frame
func rms() -> Vector2:
 var data=capture.get_buffer(capture.get_frames_available());var sum:=Vector2.ZERO
 for sample in data:sum+=sample*sample
 var count:=maxf(data.size(),1)
 return Vector2(sqrt(sum.x/count),sqrt(sum.y/count))
func run() -> void:
 var spatial=root.get_node("SpatialAudio");var bus:=AudioServer.bus_count;AudioServer.add_bus();AudioServer.set_bus_name(bus,"PositionalAudit");AudioServer.set_bus_send(bus,"Master");capture=AudioEffectCapture.new();capture.buffer_length=.5;AudioServer.add_bus_effect(bus,capture);var master_muted:=AudioServer.is_bus_mute(0);AudioServer.set_bus_mute(0,true)
 var fixture:=Fixture.new();fixture.player=Node2D.new();fixture.add_child(fixture.player);root.add_child(fixture);current_scene=fixture;spatial._physics_process(1.0/360)
 var wave:=AudioStreamWAV.new();wave.format=AudioStreamWAV.FORMAT_16_BITS;wave.mix_rate=44100;wave.loop_mode=AudioStreamWAV.LOOP_FORWARD;wave.loop_end=44100;var data:=PackedByteArray();data.resize(88200)
 for i in range(44100):data.encode_s16(i*2,int(sin(TAU*440*i/44100)*12000))
 wave.data=data
 var voice=SOURCE.new();voice.bus="PositionalAudit";voice.max_distance=560;voice.attenuation=2;voice.stream=wave;fixture.add_child(voice)
 var measured:Dictionary={}
 for entry in [["left",Vector2(-120,0)],["right",Vector2(120,0)],["near",Vector2(0,0)],["middle",Vector2(240,0)],["far",Vector2(480,0)]]:
  voice.position=entry[1];voice.play();await settle();capture.clear_buffer();await settle();measured[entry[0]]=rms();voice.stop()
 var left:Vector2=measured.left;var right:Vector2=measured.right
 check(left.x>left.y*1.5 and left.x>0.001,"Rendered audio from the left favors the left headphone channel: "+str(left))
 check(right.y>right.x*1.5 and right.y>0.001,"Rendered audio from the right favors the right headphone channel: "+str(right))
 check(measured.near.length()>measured.middle.length() and measured.middle.length()>measured.far.length(),"Rendered positional audio fades smoothly with distance")
 voice.position=Vector2(200,196);voice.update_source();var other_floor_db:float=voice.source.volume_db;voice.position=Vector2(200,0);voice.update_source();check(other_floor_db<voice.source.volume_db,"Vertical distance attenuates adjacent-storey audio")
 voice.position=Vector2(200,0);fixture.player.position=Vector2(100,0);spatial._physics_process(1.0/360);voice.update_source()
 check(voice.source.position==spatial.mapped(Vector2(200,0)) and spatial.listener_point==Vector2(100,0),"Source stays anchored while listener follows moving Miro")
 var source=voice.source;voice.queue_free();await process_frame;await process_frame
 check(not is_instance_valid(source),"Scene cleanup releases the positional emitter")
 fixture.queue_free();await process_frame;await process_frame;AudioServer.remove_bus(bus);AudioServer.set_bus_mute(0,master_muted);OS.delay_msec(120)
 print("POSITIONAL_AUDIO_REVIEW_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
