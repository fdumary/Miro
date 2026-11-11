extends SceneTree
class SoundSpy extends Node:
 var steps:Array=[]
 func play_sound(cue:String,db:float=-16,pitch:float=1) -> void:
  if cue=="step":steps.append({"db":db,"pitch":pitch})
 func play_near(_cue:String,_from:Vector2,_to:Vector2,_db:float=-8,_reach:float=560,_pitch:float=1) -> void:pass
 func cough_near(_from:Vector2,_to:Vector2,_variation:int) -> void:pass
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func frames(n:=2) -> void:
 for i in range(n):await process_frame
func run() -> void:
 var level
 for number in range(2,6):
  if is_instance_valid(level):level.queue_free();await frames(3)
  level=load("res://scenes/levels/level_%02d.tscn"%number).instantiate();root.add_child(level);current_scene=level;await frames(8);level.finish_dialogue()
  var director=level.get_node("InnerConflict")
  check(is_instance_valid(director.frame),"Painting exists on floor %d"%number)
  if is_instance_valid(director.frame):
   var art_rect:Rect2=director.frame.canvas_rect().grow(6);art_rect.position+=director.frame.global_position
   var poster_rect:=Rect2(level.poster.global_position-Vector2(14,18),Vector2(28,36))
   check(not art_rect.intersects(poster_rect),"Painting and branch poster do not overlap on floor %d"%number)
 level.queue_free();await frames(3)
 level=load("res://scenes/levels/level_02.tscn").instantiate();root.add_child(level);current_scene=level;await frames(8);level.finish_dialogue()
 var world=level.world_features
 for guard in level.guards():guard.set_physics_process(false)
 world.conversation_done=true;world.casual_scenes.clear();world.mutter_wait=100
 var wick
 for guard in level.guards():
  if guard.guard_name=="Wick":wick=guard
 check(is_instance_valid(wick),"Wick is available for speech regression")
 if is_instance_valid(wick):
  level.player.position=wick.position-Vector2(25,0);level.player.set_physics_process(false)
  world.speak(wick,"idle_1","Test before takedown")
  check(world.line_left>0 and world.voice_speaker==wick,"Awake Wick can speak")
  wick.strangle();await frames(3)
  check(not world.voice.playing and world.subtitle.text.is_empty() and not world.voice_audible(),"Strangling stops Wick's current voice and subtitle")
  world.speak(wick,"idle_1","Unconscious guards must not speak")
  check(world.line_left==0 and world.subtitle.text.is_empty(),"Unconscious Wick cannot start another line")
  var other=level.guards()[0]
  if other==wick:other=level.guards()[1]
  world.speak(other,"sleeping","Reaction from another keeper")
  check(world.voice_speaker==other and world.line_left>0,"Awake witnesses retain their reaction dialogue")
  world.voice.stop();world.line_left=0;world.subtitle.text=""
  world.actors.assign([wick,other]);world.conversation=[{"speaker":0,"text":"Should not play"}];world.conversation_done=false;world.conversation_started=true;world.conversation_index=-1
  world._process(0.01)
  check(world.conversation_done,"Main conversation cancels when a participant is unconscious")
  world.casual_scenes=[{"done":false,"started":false,"actors":[wick,other],"lines":[{"speaker":0,"text":"Should not play"}],"index":-1,"hold":false}]
  world.update_casual(0.01)
  check(world.casual_scenes[0].done,"Casual conversations skip unconscious participants")
 world.set_process(false);level.player.set_physics_process(true);level.player.position=Vector2(600,236);level.player.velocity=Vector2.ZERO;await frames(20);level.player.set_physics_process(false)
 var sound=root.get_node("SoundFX");root.remove_child(sound);var spy=SoundSpy.new();spy.name="SoundFX";root.add_child(spy)
 var cadence={};var p=level.player;p.has_supplies=true;p.health=100
 var speeds:Dictionary={}
 for mode in ["normal","quiet","crouch","blanket","blanket_fast"]:
  for action in ["move_right","slow_walk","crouch"]:Input.action_release(action)
  p.position=Vector2(600,236.924);p.velocity=Vector2.ZERO;p.respawn_cloak_left=0;p.is_concealed=mode.begins_with("blanket");p.stealth_remaining=100;p.footstep_left=0
  Input.action_press("move_right")
  if mode in ["quiet","blanket_fast"]:Input.action_press("slow_walk")
  if mode=="crouch":Input.action_press("crouch")
  spy.steps.clear()
  speeds[mode]=0.0
  for tick in range(120):
   p._physics_process(1.0/60)
   speeds[mode]=maxf(speeds[mode],absf(p.velocity.x))
  cadence[mode]=spy.steps.duplicate(true)
  check(not spy.steps.is_empty(),"Footsteps produced for "+mode)
 for action in ["move_right","slow_walk","crouch"]:Input.action_release(action)
 for mode in ["quiet","crouch"]:
  if not cadence[mode].is_empty() and not cadence.normal.is_empty():
   check(cadence[mode][0].db<cadence.normal[0].db,"Quieter step volume for "+mode)
   check(cadence[mode].size()<cadence.normal.size(),"Slower step cadence for "+mode)
 check(absf(speeds.blanket-115*.55)<.1 and absf(speeds.blanket_fast-115*.8)<.1,"Blanket moves at 55 percent, Shift blanket at 80 percent")
 check(cadence.blanket_fast.size()>cadence.blanket.size() and cadence.blanket_fast[0].db==cadence.blanket[0].db,"Fast blanket steps are faster but remain equally quiet")
 root.remove_child(spy);spy.queue_free();root.add_child(sound)
 print("PLAYTEST_WORLD_REGRESSIONS_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
