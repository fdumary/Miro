extends SceneTree
var level
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func frames(n:=2) -> void:
 for i in range(n):await process_frame
func key(code:int,down:bool,modifier:String="") -> void:
 var event:=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=down
 event.shift_pressed="shift" in modifier;event.ctrl_pressed="ctrl" in modifier
 Input.parse_input_event(event);await frames()
func mouse(button:int,down:bool,modifier:String="") -> void:
 var event:=InputEventMouseButton.new();event.button_index=button;event.pressed=down;event.position=Vector2(320,200);event.global_position=event.position
 event.shift_pressed="shift" in modifier;event.ctrl_pressed="ctrl" in modifier
 Input.parse_input_event(event);await frames()
func run() -> void:
 var bindings=root.get_node("InputBindings");bindings.custom={};bindings.apply()
 level=load("res://scenes/intro.tscn").instantiate();root.add_child(level);current_scene=level;await frames(5)
 level.finish_dialogue();level.player.has_supplies=true;level.door_open=true
 for guard in level.guards():guard.set_physics_process(false)
 var p=level.player;var controls=p.controls
 p.set_physics_process(false);p.guns.assign(["pistol"]);p.has_gun=true;p.equipped_gun="pistol";controls.sync_slots()
 for modifier in ["","shift","ctrl","shift ctrl"]:
  p.ammunition=1;p.gun_ammo["pistol"]=1;controls.reserves["pistol"]=20;controls.select_item("c4")
  await key(KEY_1,true,modifier);await key(KEY_1,false,modifier)
  check(controls.active=="pistol","Slot 1 selects pistol with modifiers: "+modifier)
  controls.select_item("pistol")
  await key(KEY_R,true,modifier);await key(KEY_R,false,modifier)
  check(controls.reload_left>0,"R starts reload with modifiers: "+modifier)
  await create_timer(1.1).timeout
  check(p.ammunition==8 and controls.reserves.pistol==13,"Reload completes without reserve reset: "+modifier)
  p.attack_cooldown=0
  var ammo:int=p.ammunition
  await mouse(MOUSE_BUTTON_LEFT,true,modifier);await mouse(MOUSE_BUTTON_LEFT,false,modifier)
  check(p.ammunition==ammo-1,"Left click fires with modifiers: "+modifier)
  await mouse(MOUSE_BUTTON_RIGHT,true,modifier)
  check(controls.focus,"Right click focuses with modifiers: "+modifier)
  await mouse(MOUSE_BUTTON_RIGHT,false,modifier)
  check(not controls.focus,"Right click release clears focus: "+modifier)
 # Authenticated floor-one practice port has no linked camera: report that, not lost authentication.
 controls.has_remote=true;controls.remote_unlocked=true;p.position=level.world_features.access_point+Vector2(0,-5)
 controls.open_remote(true);controls.run_command("login root")
 check(level.world_features.early_authenticated,"Floor-one service login succeeds")
 controls.run_command("cameras off")
 check(not "authenticate first" in controls.output.text.to_lower(),"Authenticated floor-one cameras command does not report login failure")
 check("no" in controls.output.text.to_lower() and "camera" in controls.output.text.to_lower(),"Camera-less service port explains absence of cameras")
 controls.close_panels()
 for number in range(1,6):
  if number>1:
   level.queue_free();await frames(3);level=load("res://scenes/levels/level_%02d.tscn"%number).instantiate();root.add_child(level);current_scene=level;await frames(4)
  level.finish_dialogue()
  level.start_dialogue([["NIRO","First line"],["NIRO","Second line"],["NIRO","Third line"]])
  await frames(2);level.line_lock=14
  await key(KEY_E,true);await key(KEY_E,false)
  check(level.dialogue_index==1,"E advances exactly one voiced line on floor %d"%number)
  level.line_lock=14
  var event:=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_A;event.pressed=true;Input.parse_input_event(event);await frames(2)
  event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await frames()
  check(level.dialogue_index==2,"Cross/A advances exactly one voiced line on floor %d"%number)
  await key(KEY_TAB,true);await key(KEY_TAB,false)
  check(level.dialogue.is_empty(),"Tab skips the remaining dialogue on floor %d"%number)
 print("LIVE_PLAYTEST_BLOCKERS_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
