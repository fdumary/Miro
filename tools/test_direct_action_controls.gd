extends SceneTree
var checks:=0
var failures:Array[String]=[]
var level
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 print("PASS: " if ok else "FAIL: ",label_)
 if not ok:failures.append(label_)
func frames(n:=3) -> void:
 for i in range(n):await process_frame
func key(code:int,down:bool=true) -> void:
 var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=down;root.push_input(e,true);await frames()
func press(code:int) -> void:await key(code);await key(code,false)
func pad(code:int,down:bool=true) -> void:
 var e:=InputEventJoypadButton.new();e.button_index=code;e.pressed=down;root.push_input(e,true);await frames()
func run() -> void:
 var bindings=root.get_node("InputBindings");bindings.custom={};bindings.apply()
 level=load("res://scenes/levels/level_03.tscn").instantiate();root.add_child(level);current_scene=level;await frames(8);level.finish_dialogue()
 var p=level.player;var c=p.controls;p.set_physics_process(false);level.world_features.set_process(false)
 for g in level.guards():g.set_physics_process(false)
 p.guns.assign(["pistol","smg"]);p.has_gun=true;p.has_supplies=true;p.position=Vector2(600,-1000);c.has_remote=true;c.layout.assign(["pistol","smg","c4"]);c.sync_slots()
 p.guns.clear();c.sync_slots();await press(KEY_1);check("No loaded weapon. A fallen Keeper may carry one." in level.message,"Selecting an unowned gun gives the fallen Keeper cue")
 p.guns.assign(["pistol","smg"]);c.sync_slots();await press(KEY_4);check(c.active=="shank","4 equips knife mode")
 await press(KEY_2);check(c.active=="smg","2 selects SMG")
 if is_instance_valid(level.card):level.card.finish()
 await create_timer(.5).timeout
 var camera:Camera2D=p.get_node("Camera2D");var base:Vector2=c.camera_base_zoom
 var aim:=InputEventMouseButton.new();aim.button_index=MOUSE_BUTTON_RIGHT;aim.position=Vector2(320,200);aim.global_position=aim.position;aim.pressed=true;Input.parse_input_event(aim);await create_timer(.35).timeout
 print("ADS_PROBE focus=",c.focus," zoom=",camera.zoom," base=",base," ready=",c.gameplay_ready())
 check(c.focus and camera.zoom.x>base.x*1.05 and camera.zoom.x<=base.x*1.081,"Right-click ADS adds a smooth bounded 8 percent camera zoom")
 aim=aim.duplicate();aim.pressed=false;Input.parse_input_event(aim);await create_timer(.5).timeout
 check(not c.focus and camera.zoom.distance_to(base)<.002,"Releasing aim restores camera scale")
 c.reload_left=.8;p.ammunition=1;c.reserves.smg=20;p.attack_cooldown=.12
 await press(KEY_F);check(c.active=="smg" and c.melee_left>0 and p.attack_cooldown>.1,"F immediately interrupts gun recovery and preserves equipped SMG")
 check(c.reload_left==0 and p.ammunition==1 and c.reserves.smg==20,"Melee cancels reload without transferring ammo")
 var cooldown:float=c.melee_left;await press(KEY_F);check(c.melee_left<=cooldown,"Repeated F cannot restart or bypass melee recovery")
 var before:int=p.ammunition;c.use_item();check(p.ammunition==before,"Held-fire use cannot shoot during melee recovery")
 await create_timer(.6).timeout;p.attack_cooldown=0;c.use_item();check(p.ammunition==before-1,"Selected gun resumes firing after melee recovery")
 await press(KEY_Q);check(p.is_concealed and c.active=="smg","Q activates blanket without replacing weapon")
 await press(KEY_Q);check(not p.is_concealed and c.active=="smg","Q deactivates blanket directly")
 await press(KEY_X);check(c.remote_open and c.active=="smg","X opens MP3 without replacing weapon");c.close_panels();await frames()
 await pad(JOY_BUTTON_Y);await pad(JOY_BUTTON_Y,false);check(c.active=="shank","Tap Triangle cycles weapons once, including knife")
 await pad(JOY_BUTTON_Y);await create_timer(.4).timeout;check(c.active=="c4","Hold Triangle selects C4 at threshold");await pad(JOY_BUTTON_Y,false);check(c.active=="c4","Hold release does not cycle gun")
 await pad(JOY_BUTTON_DPAD_DOWN);await pad(JOY_BUTTON_DPAD_DOWN,false);check(c.remote_open,"Tap Down opens MP3");c.close_panels()
 var music=root.get_node("MusicDirector");var was:bool=music.shuffle_enabled
 await pad(JOY_BUTTON_DPAD_DOWN);await create_timer(.4).timeout;check(music.shuffle_enabled!=was and not c.remote_open,"Hold Down toggles shuffle without opening hacking");await pad(JOY_BUTTON_DPAD_DOWN,false);check(not c.remote_open,"Shuffle release does not open hacking")
 await pad(JOY_BUTTON_Y);level.start_dialogue([["MIRO","A modal line."]]);await frames();await pad(JOY_BUTTON_Y,false);check(c.held_buttons.is_empty() and c.active=="c4","Dialogue clears pending weapon hold");level.finish_dialogue()
 await pad(JOY_BUTTON_Y);c._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT);check(c.held_buttons.is_empty(),"Window focus loss clears pending tap/hold")
 c.show_inventory();var concealed:bool=p.is_concealed;await press(KEY_Q);await press(KEY_F);check(p.is_concealed==concealed and c.melee_left==0,"Inventory blocks gameplay direct actions");c.close_panels()
 c.layout.assign(["remote","c4","gun_2","shank","gun_1"]);c.sync_slots();check(c.layout==["c4","smg","pistol","shank"] and c.slots.size()==4,"Five-slot save migrates preserving gun order and placing knife last")
 p.stealth_cooldown_left=0;p.gun_ammo.pistol=7;c.reserves.pistol=11;c.collect_guitar();check(c.slots[2]=="guitar" and c.active=="guitar" and p.gun_ammo.pistol==7 and c.reserves.pistol==11,"Guitar replaces pistol slot without losing pistol ammo")
 await press(KEY_Q);check(p.is_concealed and c.active=="guitar","Blanket remains a direct action with guitar owned")
 await press(KEY_Q)
 for preset in ["Default","Bumper Jumper","Tactical","Bumper Jumper Tactical","Southpaw"]:
  bindings.preset=preset;bindings.apply();c.select_item("smg");c.melee_left=0
  await pad(bindings.pad_button(JOY_BUTTON_RIGHT_SHOULDER));await pad(bindings.pad_button(JOY_BUTTON_RIGHT_SHOULDER),false)
  check(c.melee_left>0 and c.active=="smg","Controller preset direct melee: "+preset)
  p.is_concealed=false;p.stealth_cooldown_left=0
  await pad(bindings.pad_button(JOY_BUTTON_LEFT_SHOULDER));await pad(bindings.pad_button(JOY_BUTTON_LEFT_SHOULDER),false)
  check(p.is_concealed and c.active=="smg","Controller preset immediate blanket: "+preset)
  await pad(bindings.pad_button(JOY_BUTTON_Y));await pad(bindings.pad_button(JOY_BUTTON_Y),false)
  check(c.active=="guitar","Controller preset weapon tap follows rearranged slots: "+preset)
  await pad(bindings.pad_button(JOY_BUTTON_Y));await create_timer(.4).timeout;await pad(bindings.pad_button(JOY_BUTTON_Y),false)
  check(c.active=="c4","Controller preset C4 hold: "+preset)
  var text:String=root.get_node("ControllerSettings").controls_help(root.get_node("Campaign").tuning())
  check("Melee" in text and "tap Weapons / hold C4" in text and "tap MP3 / hold Shuffle" in text,"Controller menu explains new actions: "+preset)
 var settings_parent:=Control.new();root.add_child(settings_parent)
 var settings_box=preload("res://scripts/menu_screens.gd").controller_settings(settings_parent,Rect2(0,0,420,265),func():pass)
 for preset in ["Default","Tactical","Bumper Jumper","Bumper Jumper Tactical","Southpaw"]:
  bindings.preset=preset;bindings.apply();settings_box.refresh()
  check(("R3" in settings_box.crouch.text or "RS" in settings_box.crouch.text) if "Tactical" in preset else ("L3" in settings_box.crouch.text or "LS" in settings_box.crouch.text),"Settings crouch checkbox reflects controller preset: "+preset)
  check(("left stick" in settings_box.invert.text.to_lower()) if preset=="Southpaw" else ("right stick" in settings_box.invert.text.to_lower()),"Settings aim checkbox reflects stick mapping: "+preset)
 settings_parent.queue_free();await frames()
 bindings.preset="Default";bindings.apply();bindings.open();await frames()
 check(bindings.rows.has("melee") and bindings.rows.melee.text=="F" and bindings.rows.mp3.text=="X" and bindings.rows.slot_4.text=="4","Main menu binding screen shows F/X and four weapon binds")
 bindings.close();bindings.custom={"melee":["key",KEY_J],"mp3":["key",KEY_K]};bindings.apply();c.melee_left=0;await press(KEY_J);check(c.melee_left>0,"Rebound melee executes")
 await press(KEY_K);check(c.remote_open,"Rebound MP3 opens hacking");c.close_panels();bindings.custom={};bindings.apply()
 level.queue_free();await frames(8)
 print("DIRECT_ACTION_CONTROLS_RESULT: ",checks-failures.size(),"/",checks," passed");quit(0 if failures.is_empty() else 1)
