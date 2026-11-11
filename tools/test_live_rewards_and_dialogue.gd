extends SceneTree
var checks:=0
var failures:Array[String]=[]
var level
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func frames(n:=3) -> void:
 for i in range(n):await process_frame
func load_floor(number:int) -> void:
 if is_instance_valid(level):level.queue_free();await frames()
 root.get_node("Campaign").checkpoint.clear()
 level=load("res://scenes/intro.tscn" if number==1 else "res://scenes/levels/level_%02d.tscn"%number).instantiate();root.add_child(level);current_scene=level
 await frames(8);level.finish_dialogue();level.player.set_physics_process(false);level.world_features.set_process(false);level.world_features.conversation_done=true;level.world_features.casual_scenes.clear()
 for g in level.guards():g.set_physics_process(false);g.position+=Vector2(0,3000)
func run() -> void:
 var campaign=root.get_node("Campaign");var radio=root.get_node("RemoteRadio");radio.controller_worker=true
 await load_floor(2)
 var w=level.world_features
 var choices:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue_choices.json"));var director=level.get_node("InnerConflict")
 for choice in choices.choices:
  await load_floor(int(str(choice.id).substr(1,1)));w=level.world_features;director=level.get_node("InnerConflict")
  for option in range(choice.options.size()):
   var actor:="JUDAS" if choice.id=="l1_keeper" else ("PRISONER" if choice.id=="l2_sick" else "NIRO")
   level.start_dialogue([["MIRO",choice.prompt,"thought","choice:"+str(choice.id),actor]])
   await frames()
   check(radio.room.stream!=null and radio.room.stream.resource_path==radio.clip_path(choice.prompt,"miro"),"Choice prompt plays exact clip: %s option%d"%[choice.id,option])
   var old_stream=radio.room.stream;var old_key:String=level.radio_line;director.choice_selected=1-option;director.update_choice_bubble();await frames()
   check(radio.room.stream==old_stream and level.radio_line==old_key,"Changing highlighted option never restarts prompt: "+str(choice.id))
   director.choose(option);await frames()
   check(radio.room.stream!=null and radio.room.stream.resource_path==radio.clip_path(choice.options[option].text,"miro"),"Chosen Miro reply plays: %s option%d"%[choice.id,option])
   if choice.options[option].has("reply"):
    level.dialogue_index=1;await frames()
    var prefix:="judas" if actor=="JUDAS" else ("prisoner" if actor=="PRISONER" else "niro")
    var expected:String=radio.clip_path(choice.options[option].reply[1],prefix)
    check(ResourceLoader.exists(expected) and ((radio.room.stream!=null and radio.room.stream.resource_path==expected) or (radio.voice.stream!=null and radio.voice.stream.resource_path==expected)),"NPC reaction plays after branch: %s option%d"%[choice.id,option])
   level.finish_dialogue();await frames()
 await load_floor(2);w=level.world_features
 # Both reported missing inner thoughts still exist and pause while forced dialogue owns the voice.
 var thoughts:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/inner_dialogue.json"))
 for thought in thoughts.get("2",[]):
  if "locks face inward" in str(thought.text):
   var path:="res://assets/audio/voice/thought_2_%s.mp3"%thought.id
   check(ResourceLoader.exists(path) and load(path).get_length()>0,"Protection/locks thought has a decoded voice clip")
   w.thought_left=0;w.think(thought.text,"thought_2_"+str(thought.id));w.thought_voice.stream=load(path);w.thought_voice.play();level.start_dialogue([["MIRO","Test interruption"]]);w._process(0.01)
   check(w.thought_voice.stream_paused,"Inner thought pauses during a forced dialogue")
   level.finish_dialogue();w._process(0.01);check(not w.thought_voice.stream_paused,"Inner thought resumes after the dialogue")
 w.thought_seen.clear();w.thought_left=0;w.pending_thoughts.clear();w.turret_hinted=true;w.voice_speaker=null;w.line_left=0
 var port=w.props.filter(func(prop):return is_instance_valid(prop) and prop.kind=="access")[0];level.player.position=port.position+Vector2(400,0)
 w.update_bubbles(0.01);check(not w.thought_seen.has("camera_hack_hint"),"Camera proximity never speaks the hacking hint automatically")
 check(level.z_hint()==w.CAMERA_HACK_HINT and w.thought_seen.has("camera_hack_hint"),"Z offers the contextual camera hacking hint")
 check(w.security_hint()!=w.CAMERA_HACK_HINT,"Camera hint is not repeated after being requested")
 w.thought_left=0;w.pending_thoughts.clear()
 # Real detonation: three living targets die, reward appears immediately, B plays it.
 campaign.achievements_earned.erase("c4_spree");campaign.c4_kill_count=0;campaign.session_unlocks=[];campaign.pending_achievement_notices.clear()
 level.player.position=Vector2(100,-1000);level.player.c4_count=4
 for i in range(3):
  var guard=load("res://scenes/guard.tscn").instantiate();guard.level=level;guard.position=Vector2(600+i*20,-1000);level.get_node("Guards").add_child(guard);guard.set_physics_process(false)
 var c=level.player.controls;c.has_remote=true;c.remote_unlocked=false;c.drop_charge();c.planted[0].position=Vector2(620,-1000);c.planted[0].set_physics_process(false);c.detonate_charges();await frames()
 check(campaign.has_achievement("c4_spree") and campaign.pending_achievement_notices.has("c4_spree"),"Three-guard C4 blast immediately queues its achievement popup")
 check(campaign.unlocked_tracks().has("project_dancehall_hard_af_2"),"C4 reward beat is immediately owned")
 campaign.pending_achievement_notices.assign(["c4_spree"]);campaign.show_next_achievement_notice()
 var toast=campaign.achievement_notice.find_child("AchievementText",true,false)
 check(toast!=null and campaign.achievement_notice.get_meta("achievement_id")=="c4_spree" and campaign.track_title("project_dancehall_hard_af_2") in toast.text,"C4 popup displays the correct unlocked beat name")
 await frames()
 var toast_panel=campaign.achievement_notice.get_child(0)
 check(toast_panel.position.x+toast_panel.size.x<=640 and toast_panel.position.y+toast_panel.size.y<=360,"Achievement popup fits inside the authored screen bounds")
 var played:=false
 for i in range(campaign.unlocked_tracks().size()+1):
  c.next_beat()
  if root.get_node("MusicDirector").track_id=="project_dancehall_hard_af_2":played=true;break
 check(played,"B cycles to the C4 reward during gameplay without service unlock")
 # Foreva bonus depends on this run, not historical lifetime kills.
 var egg:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/easter_eggs.json")).eggs[0]
 campaign.floor_stats={};level.player.casualty_count=1;campaign.achievements_earned.erase("foreva_peaceful");campaign.session_unlocks=[];w.show_egg(egg)
 check(campaign.unlocked_tracks().has("spanish_guitarhall") and not campaign.unlocked_tracks().has("foreva"),"Ordinary Foreva discovery grants Spanish Guitarhall")
 w.hide_egg();level.player.casualty_count=0;campaign.kill_count=100;w.show_egg(egg)
 check(campaign.has_achievement("foreva_peaceful") and campaign.unlocked_tracks().has("foreva"),"No-kill current-run discovery earns bonus despite historical kills")
 w.hide_egg();w.thought_voice.stop();w.thought_voice.stream=null;radio.stop();radio.room.stream=null;radio.voice.stream=null;radio.room_spatial.stream=null;radio.controller_worker=false
 level.queue_free();level=null;await frames(8);OS.delay_msec(150)
 print("LIVE_REWARDS_DIALOGUE_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
