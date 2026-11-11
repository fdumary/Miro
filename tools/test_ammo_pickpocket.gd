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
func key(down:bool) -> void:
 var e:=InputEventKey.new();e.physical_keycode=KEY_E;e.keycode=KEY_E;e.pressed=down;Input.parse_input_event(e);await frames(3)
func pad(down:bool) -> void:
 var e:=InputEventJoypadButton.new();e.button_index=JOY_BUTTON_A;e.pressed=down;Input.parse_input_event(e);await frames(3)
func run() -> void:
 level=load("res://scenes/levels/level_03.tscn").instantiate();root.add_child(level);current_scene=level;await frames(10);level.finish_dialogue()
 for g in level.guards():g.set_physics_process(false);g.position+=Vector2(0,4000)
 var p=level.player;var c=p.controls;var w=level.world_features;p.set_physics_process(false);w.set_process(false);p.has_supplies=true;p.position=Vector2(600,-1000);p.facing=1
 var ground:=StaticBody2D.new();ground.position=Vector2(600,-974);var col:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=Vector2(400,20);col.shape=shape;ground.add_child(col);level.add_child(ground)
 var victim=load("res://scenes/guard.tscn").instantiate();victim.name="AmmoPocketFixture";victim.level=level;victim.position=Vector2(630,-1000);victim.facing=1;level.get_node("Guards").add_child(victim);victim.set_physics_process(false)
 await frames()
 for i in range(8):p.velocity=Vector2(0,300);p.move_and_slide();await physics_frame
 check(p.is_on_floor(),"Controller fixture is grounded")
 var start:int=victim.remaining_ammo();var reserve:int=c.reserves.get("pistol",0)
 await key(true);check(w.strangle_active(),"E press starts a pending hold behind unaware guard")
 await key(false);w.update_strangle(.01)
 check(not victim.asleep and victim.ammo_pickpocketed and c.reserves.pistol==reserve+3,"Tap E steals pistol ammo without strangling")
 check(victim.remaining_ammo()==start-3 and victim.dropped_ammo()==0,"Stolen ammo reduces guard stock and cannot be collected again as a drop")
 check(w.pickpocket_ammo(victim)==0 and c.reserves.pistol==reserve+3,"Repeat pickpocket cannot duplicate ammo")
 var ammo:int=victim.remaining_ammo();victim.shot_direction=Vector2.RIGHT;victim.shoot_weapon();check(victim.remaining_ammo()==ammo-1,"Guard firing spends real remaining ammo")
 victim.ammunition=0;var nodes:int=level.get_child_count();victim.shoot_weapon();check(level.get_child_count()==nodes and victim.burst_left==0,"Empty guard cannot spawn another bullet")
 victim.ammunition=2;var state:Dictionary=level.guard_ammo_snapshot();victim.ammunition=8;victim.ammo_pickpocketed=false;victim.stolen_ammo=0;level.restore_checkpoint_loot({"guard_ammo":state});for i in range(8):await physics_frame
 check(victim.ammunition==2 and victim.ammo_pickpocketed and victim.stolen_ammo==3,"Checkpoint restores guard ammunition and pickpocket consumption")
 await key(true);w.update_strangle(.3);await key(false);check(victim.asleep and victim.strangled,"Holding E completes strangle instead of taking ammo")
 victim.position+=Vector2(0,4000)
 var other=load("res://scenes/guard.tscn").instantiate();other.name="ControllerPocketFixture";other.level=level;other.position=Vector2(630,-1000);other.weapon_kind="smg";other.facing=1;level.get_node("Guards").add_child(other);other.set_physics_process(false);await frames()
 var before:int=c.reserves.get("smg",0);await pad(true);await pad(false);w.update_strangle(.01)
 check(other.ammo_pickpocketed and c.reserves.smg==before+6 and not other.asleep,"Tap Cross pickpockets scarce SMG ammo")
 await pad(true);w.update_strangle(.3);await pad(false);check(other.asleep,"Hold Cross strangles")
 var definition:Dictionary=level.definition
 check(not definition.features.hazards.any(func(h):return h.kind=="turret" and Vector2(h.position[0],h.position[1])==Vector2(400,1260)),"Problem floor-three turret is absent from actual level data")
 var campaign=root.get_node("Campaign")
 for mode in ["easy","medium","hard","super_hard"]:
  campaign.difficulty_override=mode
  for gun in ["pistol","smg"]:
   var guard=load("res://scenes/guard.tscn").instantiate();guard.level=level;guard.weapon_kind=gun;guard.position=p.position+Vector2(30,0);guard.facing=1;level.get_node("Guards").add_child(guard);guard.set_physics_process(false);await frames()
   var cfg:Dictionary=campaign.tuning()
   check(guard.sight==cfg.sight and guard.suspicion_rate==cfg.suspicion and guard.windup_time==cfg.windup and guard.attack_gap==cfg.attack_gap and guard.chase_speed==cfg.chase,"Actual guard difficulty tuning: "+mode+" "+gun)
   var expected_drop:int=({"easy":[5,18],"medium":[3,12],"hard":[2,8],"super_hard":[1,4]})[mode][0 if gun=="pistol" else 1]
   check(guard.dropped_ammo()==expected_drop,"Difficulty drop amount: "+mode+" "+gun)
   var expected_pocket:int=({"easy":[5,9],"medium":[3,6],"hard":[2,4],"super_hard":[1,2]})[mode][0 if gun=="pistol" else 1]
   check(w.pickpocket_ammo(guard)==expected_pocket and guard.dropped_ammo()==expected_drop-expected_pocket,"Difficulty pickpocket deducts the same drop budget: "+mode+" "+gun)
   p.guns.assign(["pistol","smg"]);p.has_gun=true;c.sync_slots();c.select_item(gun);c.reserves[gun]=0;c.collect_ammo_case()
   check(c.reserves[gun]==campaign.ammo_amount(12 if gun=="smg" else 8),"Actual ammo case scales by difficulty: "+mode+" "+gun)
   guard.free()
 campaign.difficulty_override=""
 var bindings=root.get_node("InputBindings");var settings=root.get_node("ControllerSettings");p.equipped_gun="pistol";p.ammunition=0;c.reserves.pistol=5
 settings.using_controller=false;p.fire_gun();await frames(4)
 check("Out of ammo. [R] Reload." in level.message_label.text,"Empty trigger displays R reload cue")
 bindings.custom={"reload":["key",KEY_J]};bindings.apply();await frames(4)
 check("[J] Reload" in level.message_label.text and not "[R]" in level.message_label.text,"Empty-trigger cue reflects rebound keyboard reload")
 for preset in ["Default","Tactical","Bumper Jumper","Bumper Jumper Tactical","Southpaw"]:
  bindings.preset=preset;bindings.apply();settings.using_controller=true;await frames(4)
  check("Square" in level.message_label.text or "[X]" in level.message_label.text,"Empty-trigger cue reflects controller reload in "+preset)
 bindings.custom={};bindings.preset="Default";bindings.apply()
 level.queue_free();await frames(8);print("AMMO_PICKPOCKET_RESULT: ",checks-failures.size(),"/",checks," passed");quit(0 if failures.is_empty() else 1)
