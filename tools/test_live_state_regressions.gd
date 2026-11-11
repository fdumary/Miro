extends SceneTree
var checks:=0
var failures:Array[String]=[]
var level
var campaign
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func frames(n:=5) -> void:
 for i in range(n):await physics_frame
 await process_frame
func scene(number:int) -> void:
 if is_instance_valid(level):level.queue_free();await frames()
 campaign.checkpoint={};campaign.carried_kit={}
 level=load("res://scenes/intro.tscn" if number==1 else "res://scenes/levels/level_%02d.tscn"%number).instantiate();root.add_child(level);current_scene=level
 await frames(8);level.finish_dialogue();level.world_features.set_process(false);level.player.set_physics_process(false)
 for g in level.guards():g.set_physics_process(false)
func run() -> void:
 campaign=root.get_node("Campaign")
 for number in range(1,6):
  await scene(number)
  var c=level.player.controls;var w=level.world_features;c.has_remote=true;c.remote_unlocked=true
  var port
  for prop in w.props:
   if is_instance_valid(prop) and prop.kind=="access":port=prop;break
  if port==null:
   for terminal in get_nodes_in_group("security_terminals"):
    if level.is_ancestor_of(terminal):port=terminal;break
  check(is_instance_valid(port),"Authored service or records terminal exists floor %d"%number)
  if not is_instance_valid(port):continue
  var tested:=false
  for side in [-1,1]:
   level.player.position=port.global_position+Vector2(side*80,0)
   if not level.clear_sight(level.player.position+Vector2(0,-8),port.global_position+Vector2(0,-8)):continue
   c.show_console(false);c.run_command("login root")
   check(c.output.text=="Authenticated.","MP3 login at 80px actual port floor %d"%number)
   c.run_command("whoami");check(c.output.text=="root","MP3 authenticated command retains actual port floor %d"%number)
   c.run_command("turrets off");check(not "authenticated terminal" in c.output.text,"Authenticated MP3 service or records terminal accepts turret command floor %d"%number)
   tested=true;break
  check(tested,"Authored port has accessible wireless approach floor %d"%number)
  c.close_panels();level.player.position=port.global_position;level.player.velocity=Vector2.ZERO;level.player.set_physics_process(true);await frames(ceili(Engine.physics_ticks_per_second*.2));level.player.set_physics_process(false)
  c.has_remote=true;c.select_item("remote");Input.action_press("pad_use");await frames(3);Input.action_release("pad_use")
  check(c.remote_open and not c.local_console,"R2 equipped MP3 opens wireless console floor %d"%number)
  c.close_panels();c.handle_pad_button(JOY_BUTTON_A)
  check(c.remote_open and c.local_console,"Cross at physical terminal opens local console floor %d"%number)
  c.close_panels()
  # Isolate range and wall cases from authored obstacles.
  if port.get_script()!=load("res://scripts/review_prop.gd"):port=w.spawn_prop(Vector2(600,-1000),"access","TEST PORT")
  port.position=Vector2(600,-1000);level.player.position=port.position+Vector2(479,0);c.local_console=false
  check(c.at_early_port(),"479px wireless in range floor %d"%number)
  level.player.position.x+=2;check(not c.at_early_port(),"481px wireless out of range floor %d"%number)
  level.player.position=port.position+Vector2(80,0);c.local_console=true;check(not c.at_early_port(),"Physical terminal keeps 48px reach floor %d"%number);c.local_console=false
  var wall:=StaticBody2D.new();wall.position=port.position+Vector2(40,-8);var col:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(16,80);col.shape=shape;wall.add_child(col);level.add_child(wall);await frames()
  check(c.at_early_port(),"Wireless works through corridor cover floor %d"%number)
  level.player.position=port.position+Vector2(0,196);check(not c.at_early_port(),"Wireless excludes terminal on another storey floor %d"%number)
  level.player.position=port.position+Vector2(400,0);c.show_console(false);check("Nearby signal: service.local" in c.output.text,"MP3 announces terminal beyond camera edge floor %d"%number)
  wall.queue_free();c.close_panels()
 await scene(3)
 var p=level.player;var c=p.controls;var w=level.world_features
 p.position=Vector2(600,-1000);p.c4_count=1;c.drop_charge();c.planted[0].position=p.position;c.planted[0].set_physics_process(false)
 check(p.c4_count==1 and c.recover_charge() and p.c4_count==1,"Reserved spare C4 recovery never duplicates inventory")
 await frames();p.c4_count=4;c.drop_charge();c.planted[0].position=p.position;c.planted[0].set_physics_process(false)
 check(p.c4_count==3 and c.recover_charge() and p.c4_count==4,"Inventory C4 recovery refunds exactly one")
 await frames();c.drop_charge();c.planted[0].position=p.position+Vector2(20,0);c.planted[0].stuck=true;c.planted[0].set_physics_process(false)
 p.guns.assign(["pistol","smg"]);p.has_gun=true;p.gun_ammo={"pistol":3,"smg":7};p.equipped_gun="pistol";p.ammunition=3;c.reserves={"pistol":11,"smg":12};c.has_remote=true;c.sync_slots()
 var kit:Dictionary=level.player_snapshot();var cfg:=ConfigFile.new();cfg.set_value("test","kit",kit);cfg.save("user://live-kit-roundtrip.cfg");cfg=ConfigFile.new();cfg.load("user://live-kit-roundtrip.cfg");kit=cfg.get_value("test","kit")
 p.c4_count=99;p.gun_ammo={};p.ammunition=99;c.reserves={};level.apply_player_snapshot(kit);await frames()
 check(p.c4_count==3 and p.ammunition==3 and int(c.reserves.pistol)==11 and int(p.gun_ammo.smg)==7,"Checkpoint restores exact ammo and C4 through disk serialization")
 check(c.planted.size()==1 and c.planted[0].stuck and c.planted[0].get_meta("inventory_charge"),"Checkpoint restores planted refundable C4")
 var camera
 var turret
 for n in get_nodes_in_group("tower_turrets"):
  if not level.is_ancestor_of(n):continue
  if n.get_script()==load("res://scripts/security_camera.gd") and n.is_active:camera=n
  elif n.get_script()==load("res://scripts/tower_hazard.gd") and not n.disabled:turret=n
 check(camera!=null and turret!=null,"Active camera and turret available for independent checkpoint test")
 if camera!=null and turret!=null:
  camera.disable();check(not turret.disabled,"Cameras off preserves active turrets")
  var camera_pos:Vector2=camera.position;var turret_pos:Vector2=turret.position
  var saved:Dictionary={"security":level.security_checkpoint.duplicate(true)}
  camera.is_active=true;level.restore_checkpoint_security(saved)
  check(not camera.is_active and not turret.disabled,"Retry restores hacked camera while turret stays active")
  turret.take_turret_hit(100);await frames();check(not is_instance_valid(turret),"C4 overkill removes turret")
  saved={"security":level.security_checkpoint.duplicate(true)}
  await scene(3);level.restore_checkpoint_security(saved);await frames()
  var turret_found:=false;var camera_off:=false
  for n in get_nodes_in_group("tower_turrets"):
   if not level.is_ancestor_of(n):continue
   if n.position.distance_to(turret_pos)<1 and n.get_script()==load("res://scripts/tower_hazard.gd"):turret_found=true
   if n.position.distance_to(camera_pos)<1 and n.get_script()==load("res://scripts/security_camera.gd"):camera_off=not n.is_active
  check(not turret_found and camera_off,"Scene retry preserves destroyed turret and independently hacked camera")
 # Retry must use this checkpoint's kit, clear stale alarm state, and reject stale sigil flags.
 await scene(3)
 campaign.carried_from=2;campaign.carried_kit={"gun_ammo":{"pistol":8},"ammunition":8,"c4_count":99,"reserves":{"pistol":99}}
 campaign.checkpoint={"floor":3,"storey":1,"position":Vector2(600,-1000),"milestones":{},"sigil":true,"player":kit,"dead":[],"retry":true}
 for guard in level.guards():guard.alert_state=guard.State.ALERT;guard.pursuing=true;guard.windup=1.0;guard.suspicion=1.0
 level.apply_checkpoint()
 check(not level.sigil_placed,"Checkpoint rejects completed-sigil flag without its milestone")
 check(level.guards().all(func(g):return g.is_dead or (g.alert_state==g.State.PATROL and not g.pursuing and g.windup==0)),"Checkpoint clears stale guard alert, pursuit and queued fire")
 level.pause_menu.restart();await frames(12);level=current_scene
 check(level.player.ammunition==3 and level.player.c4_count==3 and int(level.player.controls.reserves.pistol)==11,"Pause-menu retry restores checkpoint kit rather than prior-floor ammo")
 check(level.player.controls.planted.size()==1,"Pause-menu retry preserves placed C4")
 await scene(4)
 check(not root.get_node("PlayerBehavior").pending_events.has("camera_0") and not root.get_node("PlayerBehavior").pending_events.has("camera_1"),"Already-disabled scenery cameras do not count as player hacks or bias artwork")
 var flasks=level.world_features.props.filter(func(n):return is_instance_valid(n) and n.get_meta("lab_flask",false))
 check(not flasks.is_empty(),"Science tables have collectible red flasks")
 if not flasks.is_empty():
  var flask=flasks[0];level.player.position=flask.global_position;level.player.health=level.player.max_health-2
  for g in level.guards():g.position+=Vector2(0,3000)
  check(level.world_features.try_interact() and flask.used and level.player.health==level.player.max_health,"Red science flask restores one full heart and is consumed")
  var used:Array=level.used_potion_positions();flask.used=false;level.restore_checkpoint_loot({"used_potions":used});await frames(8)
  check(flask.used,"Checkpoint preserves consumed red science flask")
 await scene(5)
 c=level.player.controls;campaign.session_unlocks.erase("shit_crashed");campaign.achievements_earned.erase("guitar_acquired");c.has_guitar=false;c.sync_slots();c.select_item("blanket")
 check(not c.blanket_removed() and c.active=="blanket" and not campaign.unlocked_tracks().has("shit_crashed"),"Level five begins with blanket and no guitar beat reward")
 c.collect_guitar();check(not c.blanket_removed() and c.slots.has("guitar") and c.has_guitar and campaign.has_achievement("guitar_acquired") and campaign.unlocked_tracks().has("shit_crashed"),"Guitar pickup replaces pistol slot and immediately awards its beat")
 c.has_remote=true;c.remote_unlocked=false
 check(not "hack" in c.next_beat().to_lower(),"B beat cycling works before MP3 service unlock")
 campaign.pending_achievement_notices.clear();campaign.achievements_earned.erase("acquire_smg");c.smg_achievement_checked=false;level.player.guns.assign(["smg"]);c.sync_slots()
 check(campaign.has_achievement("acquire_smg") and campaign.pending_achievement_notices.has("acquire_smg"),"SMG acquisition queues immediate achievement")
 campaign.show_next_achievement_notice();check(is_instance_valid(campaign.achievement_notice) and campaign.achievement_notice.get_meta("achievement_id")=="acquire_smg","Achievement has visible nonblocking toast")
 print("LIVE_STATE_REGRESSIONS_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
