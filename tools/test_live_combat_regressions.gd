extends SceneTree
const PROJECTILE=preload("res://scripts/weapon_projectile.gd")
var checks:=0
var failures:Array[String]=[]
var level
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func frames(n:=4) -> void:
 for i in range(n):await physics_frame
 await process_frame
func block(at:Vector2,size:Vector2) -> StaticBody2D:
 var body:=StaticBody2D.new();body.position=at;var col:=CollisionShape2D.new();var shape:=RectangleShape2D.new();shape.size=size;col.shape=shape;body.add_child(col);level.add_child(body);return body
func rounds() -> Array:
 return level.get_children().filter(func(n):return n.get_script()==PROJECTILE)
func spread(p,climbing:bool,focus:bool) -> float:
 p.climbing=climbing;p.controls.focus=focus;p.mouse_aim=false;p.controls.pad_aim=false
 var maximum:=0.0
 seed(20261110)
 for i in range(80):
  p.ammunition=100;p.attack_cooldown=0;p.facing=1;p.fire_gun()
  var bullets=rounds()
  if not bullets.is_empty():maximum=maxf(maximum,absf(bullets[-1].direction.angle()));bullets[-1].free()
 return maximum
func run() -> void:
 level=load("res://scenes/levels/level_03.tscn").instantiate();root.add_child(level);current_scene=level;await frames(8);level.finish_dialogue();level.world_features.set_process(false)
 var p=level.player;p.set_physics_process(false);p.position=Vector2(600,-1000)
 for g in level.guards():g.set_physics_process(false);g.position+=Vector2(0,3000)
 # Exact authored level-three offender: its original muzzle lies inside the lower 2x2 block.
 var misplaced:=Area2D.new();misplaced.set_script(preload("res://scripts/tower_hazard.gd"));misplaced.kind="turret";misplaced.position=Vector2(400,1260);misplaced.level=level;level.add_child(misplaced);misplaced.set_physics_process(false)
 p.position=Vector2(520,1244);p.is_concealed=false;p.in_hiding_spot=false;misplaced.aim=(p.position-misplaced.target_point()).angle()
 await frames()
 check(not level.clear_sight(misplaced.target_point(),p.global_position),"Exact original floor-three turret cannot see Miro through its 2x2 block")
 for i in range(180):misplaced._physics_process(1.0/60)
 check(misplaced.charge==0 and rounds().is_empty(),"Exact original floor-three turret cannot charge or fire through wall")
 misplaced.free();await frames()
 var clear_mounts:=true
 for device in get_nodes_in_group("tower_turrets"):
  if device.get_script()!=load("res://scripts/tower_hazard.gd"):continue
  var point_query:=PhysicsPointQueryParameters2D.new();point_query.position=device.target_point();point_query.collision_mask=1
  clear_mounts=clear_mounts and device.get_world_2d().direct_space_state.intersect_point(point_query).is_empty()
 check(clear_mounts,"Every current floor-three turret muzzle clears solid terrain")
 p.position=Vector2(600,-1000)
 var guard=level.guards()[0];guard.sick_guard=false;guard.key_taken=true;guard.position=Vector2(600,-1000);guard.facing=1;guard.alert_state=guard.State.PATROL
 p.position=guard.position+Vector2(-35,0);p.facing=1
 check(level.world_features.strangle_target()==guard,"Rear takedown works at 35px")
 p.position=guard.position+Vector2(0,-32);p.facing=-1
 check(level.world_features.strangle_target()==guard,"Overhead ledge takedown works")
 p.position=guard.position;p.facing=1;check(level.world_features.strangle_target()==guard,"Same-position takedown works")
 p.position=guard.position+Vector2(24,0);check(level.world_features.strangle_target()==null,"Front takedown remains disallowed")
 p.position=guard.position+Vector2(-35,0);var wall=block(guard.position+Vector2(-17,-8),Vector2(8,80));await frames()
 check(level.world_features.strangle_target()==null,"Takedown cannot pass through solid cover");wall.free();await frames()
 # A standing Miro two blocks higher is visible; crouching keeps the raised cover route.
 guard.position=Vector2(650,-1000);guard.facing=-1;p.position=Vector2(560,-1056);p.velocity=Vector2(0,20);guard.velocity=Vector2(0,20)
 var ground=block(Vector2(600,-974),Vector2(400,20));var shelf=block(Vector2(560,-1036),Vector2(48,8));await frames()
 for i in range(8):p.velocity=Vector2(0,300);guard.velocity=Vector2(0,300);p.move_and_slide();guard.move_and_slide();await physics_frame
 check(p.is_on_floor() and guard.is_on_floor(),"Vision probe uses grounded player and guard")
 p.crouching=false;check(guard.can_see_point(p.global_position),"Standing Miro atop two-block shelf is visible")
 p.crouching=true;check(not guard.can_see_point(p.global_position),"Crouching retains raised-shelf cover")
 ground.free();shelf.free();guard.position+=Vector2(0,3000);await frames()
 # A muzzle inside terrain and a muzzle behind a 2x4 block both stop fire.
 p.position=Vector2(730,-1000);p.is_concealed=false;p.in_hiding_spot=false;p.crouching=false;p.health=6;p.invulnerability_left=0
 wall=block(Vector2(650,-1000),Vector2(56,112));await frames()
 var turret:=Area2D.new();turret.set_script(preload("res://scripts/tower_hazard.gd"));turret.kind="turret";turret.position=Vector2(650,-983);turret.level=level;level.add_child(turret);turret.set_physics_process(false);turret.aim=0
 wall.get_child(0).shape.size=Vector2(56,56);await frames()
 for i in range(120):turret._physics_process(1.0/60)
 check(rounds().is_empty() and turret.charge==0,"Turret muzzle inside exact 2x2 block cannot fire through it")
 turret.position.x=600;turret.aim=0
 for i in range(120):turret._physics_process(1.0/60)
 check(rounds().is_empty() and turret.charge==0,"Turret adjacent to exact 2x2 block cannot fire through it")
 wall.get_child(0).shape.size=Vector2(56,112);turret.position.x=650;turret.aim=0;await frames()
 for i in range(120):turret._physics_process(1.0/60)
 check(rounds().is_empty() and turret.charge==0,"Turret muzzle inside 2x4 block cannot fire through it")
 turret.position.x=600;turret.aim=0
 for i in range(120):turret._physics_process(1.0/60)
 check(rounds().is_empty() and turret.charge==0,"Turret beside 2x4 block cannot fire through it")
 var bullet:=Node2D.new();bullet.set_script(PROJECTILE);bullet.level=level;bullet.position=Vector2(650,-1000);bullet.enemy=true;level.add_child(bullet);bullet.set_physics_process(false);bullet._physics_process(0.2)
 check(bullet.is_queued_for_deletion() and p.health==6,"Round starting inside terrain is absorbed before reaching Miro")
 await frames();wall.free();turret.free();await frames()
 wall=block(Vector2(650,-1000),Vector2(1,112));await frames()
 bullet=Node2D.new();bullet.set_script(PROJECTILE);bullet.level=level;bullet.position=Vector2(600,-1000);bullet.enemy=true;level.add_child(bullet);bullet.set_physics_process(false);bullet._physics_process(0.2)
 check(bullet.is_queued_for_deletion() and p.health==6,"Swept round cannot tunnel through one-pixel wall")
 await frames();wall.free();await frames()
 p.position=Vector2(600,-1000);p.has_gun=true;p.guns.assign(["pistol"]);p.equipped_gun="pistol";p.controls.sync_slots();p.controls.select_item("pistol");p.crouching=true;p.attack_cooldown=0;p.ammunition=8;p.fire_gun()
 check(p.ammunition==7 and rounds().size()==1 and rounds()[0].position.y==p.position.y+5,"Crouched fire consumes ammo and starts inside crouched body")
 for r in rounds():r.free()
 p.crouching=false;p.velocity=Vector2.ZERO;p.move_and_slide();var standing=spread(p,false,false);var climbing=spread(p,true,false);var focused=spread(p,true,true)
 check(standing>0.01 and climbing>standing*4 and focused<climbing,"Ladders increase spray and focusing improves ladder accuracy")
 check(tan(standing)*300>tan(standing)*50*5,"Shot cone creates greater lateral dispersion at distance")
 # An unconscious body must not intercept a knife meant for an active opponent.
 var sleeper=load("res://scenes/guard.tscn").instantiate();sleeper.level=level;sleeper.position=p.position+Vector2(12,0);level.get_node("Guards").add_child(sleeper);sleeper.set_physics_process(false);sleeper.fall_asleep()
 var opponent=load("res://scenes/guard.tscn").instantiate();opponent.level=level;opponent.position=p.position+Vector2(32,0);level.get_node("Guards").add_child(opponent);opponent.set_physics_process(false);opponent.facing=-1;opponent.alert_state=opponent.State.ALERT
 p.facing=1;p.attack_cooldown=0;p.shank()
 check(opponent.health<16 and sleeper.health==16,"Active enemy takes melee priority over a closer unconscious body")
 sleeper.free();opponent.free()
 # Two approaching live guards keep distinct bodies; sleeping bodies remain passable.
 var a=load("res://scenes/guard.tscn").instantiate();var b=load("res://scenes/guard.tscn").instantiate();a.level=level;b.level=level;a.position=Vector2(500,-1400);b.position=Vector2(540,-1400);level.get_node("Guards").add_child(a);level.get_node("Guards").add_child(b);a.set_physics_process(false);b.set_physics_process(false);await frames()
 for i in range(100):a.velocity=Vector2(80,0);b.velocity=Vector2(-80,0);a.move_and_slide();b.move_and_slide();await physics_frame
 check(absf(a.position.x-b.position.x)>=13,"Two living guards cannot merge into one visual position")
 b.fall_asleep();check(b.collision_layer==0,"Unconscious guard cannot block ladder or service access")
 var trap:=StaticBody2D.new();trap.set_script(preload("res://scripts/trapdoor.gd"));trap.level=level;trap.position=Vector2(600,-1600);level.add_child(trap);a.position=trap.position+Vector2(0,-20);trap.activate();a.position=trap.position+Vector2(0,5);trap.check_guard_crossings()
 check(root.get_node("Campaign").has_achievement("guard_trapdoor") and a.alert_state==a.State.ALERT and a.pursuing,"Guard trapdoor crossing alerts that guard and awards achievement")
 var c=level.player.controls
 check(c.capacity("smg")==24 and c.reserves.get("smg",0)<=24,"SMG retains magazine size with scarcer default reserve")
 print("LIVE_COMBAT_REGRESSIONS_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
