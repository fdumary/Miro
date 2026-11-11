extends SceneTree
var checks:=0
var failures:Array[String]=[]
var level
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func frames(n:=3) -> void:
 for i in range(n):await physics_frame
 await process_frame
func key(code:int) -> void:
 var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=true;Input.parse_input_event(e);await frames(1);e=e.duplicate();e.pressed=false;Input.parse_input_event(e);await frames(1)
func run() -> void:
 var campaign=root.get_node("Campaign");var music=root.get_node("MusicDirector");var bindings=root.get_node("InputBindings");var settings=root.get_node("ControllerSettings")
 level=load("res://scenes/levels/level_03.tscn").instantiate();root.add_child(level);current_scene=level;await frames(8);level.finish_dialogue();level.world_features.set_process(false);level.player.set_physics_process(false)
 for g in level.guards():g.set_physics_process(false)
 var c=level.player.controls;campaign.session_unlocks.assign(["yz33","dope2","bobblehead"]);c.has_remote=false;c.remote_unlocked=false
 await key(KEY_H);check(not music.shuffle_enabled,"H needs an owned MP3")
 c.has_remote=true;music.resume_floor();await key(KEY_B);check(music.track_id=="yz33","B selects next unlocked track")
 await key(KEY_B);check(music.track_id=="dope2","B advances MP3 selection")
 await key(KEY_V);check(music.track_id=="yz33","V plays previous track")
 await key(KEY_H);check(music.shuffle_enabled and music.review_override and campaign.unlocked_tracks().has(music.track_id),"H starts shuffle of earned tracks without terminal unlock")
 check(not music.voices[music.active].stream.loop,"Shuffled MP3 track advances at its end rather than looping")
 var before:String=music.track_id;music.shuffle_finished(1-music.active);check(music.track_id==before,"Finishing the old crossfade voice cannot advance shuffle")
 music.shuffle_finished(music.active);check(music.track_id!=before and campaign.unlocked_tracks().has(music.track_id),"Shuffle advances to another unlocked beat without immediate repeat")
 await key(KEY_H);check(not music.shuffle_enabled and not music.review_override and music.track_id==music.floor_track,"H stops shuffle and returns floor soundtrack")
 c.handle_pad_button(JOY_BUTTON_DPAD_RIGHT);var after_next:String=music.track_id;c.handle_pad_button(JOY_BUTTON_DPAD_LEFT)
 check(music.track_id!=after_next,"Controller D-pad Left/Right select previous/next")
 c.handle_pad_button(JOY_BUTTON_DPAD_DOWN);check(music.shuffle_enabled and not c.local_console and not c.remote_open,"Controller D-pad Down shuffles instead of opening a terminal")
 c.handle_pad_button(JOY_BUTTON_DPAD_UP);check(level.world_features.thought_left>0,"Controller D-pad Up remains the hint button")
 for number in range(1,6):
  music.toggle_shuffle() if not music.shuffle_enabled else ""
  music.start_floor(number)
  check(not music.shuffle_enabled and not music.review_override,"Floor %d entry soundtrack takes priority over shuffle"%number)
 music.start_floor(3);music.toggle_shuffle();music.second_section(3)
 check(not music.shuffle_enabled and not music.review_override and (music.pending_track==music.SECOND[3] or music.track_id==music.SECOND[3]),"Authored music checkpoint stops shuffle and schedules its floor beat")
 music._process(10);var checkpoint_track:String=music.track_id;music.shuffle_finished(music.active)
 check(music.track_id==checkpoint_track,"Old shuffle completion cannot override checkpoint song")
 music.start_floor(5);music.toggle_shuffle();music.guitar_section();check(not music.shuffle_enabled and music.track_id==music.GUITAR_TRACK,"Guitar pickup music overrides shuffle")
 music.toggle_shuffle();music.play_outro();check(not music.shuffle_enabled and music.track_id==music.OUTRO_TRACK,"Ending music overrides shuffle")
 music.start_floor(3);level.player.set_physics_process(true)
 for x in range(300,1300,56):
  level.player.position=Vector2(x,432);level.player.velocity=Vector2.ZERO;await frames(ceili(Engine.physics_ticks_per_second*.3))
  if level.player.is_on_floor() and absf(level.player.position.y-432)<3:break
 print("CHECKPOINT_MUSIC_FIXTURE pos=",level.player.position," hp=",level.player.health," dead=",level.player.is_dead," locked=",level.controls_locked()," physics=",level.player.is_physics_processing()," hide=",level.player.in_hiding_spot," dialogue=",level.dialogue)
 level.player.set_physics_process(false);check(level.player.is_on_floor(),"Storey music probe uses grounded Miro")
 campaign.checkpoint={"floor":3,"storey":0};music.cancel_shuffle();music.toggle_shuffle();level.update_checkpoint()
 check(not music.shuffle_enabled and music.track_id==music.floor_track,"Actual storey checkpoint restores authored soundtrack")
 music.toggle_shuffle();level.checkpoint_refreshed=-10000;level.update_checkpoint();check(music.shuffle_enabled,"Routine same-storey checkpoint save does not interrupt shuffle")
 music.cancel_shuffle();music.review_override=true;music.play_track("dope2");music.toggle_shuffle();await key(KEY_V);check(not music.shuffle_enabled,"V stops automatic shuffle before selecting previous")
 var prompts:String=settings.controller_text("[V] Previous · [B] Next · [H] Shuffle · [Z] Hint",true)
 check("D-pad Left" in prompts and "D-pad Right" in prompts and "D-pad Down" in prompts and "D-pad Up" in prompts,"In-game controller prompts match all four D-pad directions")
 check(bindings.KEYS.music_previous==KEY_V and bindings.KEYS.music_shuffle==KEY_H,"V/H appear in configurable PC bindings")
 music.cancel_shuffle();music.resume_floor();level.queue_free();await frames(8);OS.delay_msec(120)
 print("MP3_SHUFFLE_CONTROLS_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
