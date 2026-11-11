extends SceneTree
var failures:Array[String]=[]
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func run() -> void:
 for rate in [60,360]:
  Engine.physics_ticks_per_second=rate
  for start in [Vector2(728,432),Vector2(308,656)]:
   var upper:=236.0 if start.x==728 else 432.0
   for target_x in [start.x-48,start.x,start.x+48]:
    var level=load("res://scenes/intro.tscn").instantiate();root.add_child(level);current_scene=level
    await create_timer(0.1).timeout;level.finish_dialogue();level.player.set_physics_process(false);level.player.is_concealed=true;level.player.position=Vector2(target_x,upper)
    var guard
    for g in level.guards():
     g.set_physics_process(false)
     if g.guard_name=="Rocco":guard=g
    guard.position=start;guard.velocity=Vector2.ZERO;guard.alert_state=guard.State.SEARCH;guard.pursuing=true;guard.last_known_position=level.player.position;guard.search_left=30;guard.set_physics_process(true)
    var landed:=false
    var deadline:=Time.get_ticks_msec()+6000
    while Time.get_ticks_msec()<deadline:
     await physics_frame
     if absf(guard.position.y-upper)<6 and guard.is_on_floor() and absf(guard.position.x-start.x)>20:
      landed=true;break
    check(landed,"Guard exits ladder %s toward x%.0f at %dHz: %s"%[str(start),target_x,rate,str(guard.position)])
    check(not guard.is_dead,"Guard remains alive after ladder exit")
    level.queue_free();await process_frame;await process_frame
  var level=load("res://scenes/intro.tscn").instantiate();root.add_child(level);current_scene=level
  await create_timer(0.1).timeout;level.finish_dialogue();level.door_open=true
  level.player.set_physics_process(false);level.player.position=Vector2(728,335);level.player.climbing=true
  var guard
  for g in level.guards():
   g.set_physics_process(false)
   if g.guard_name=="Rocco":guard=g
  guard.position=Vector2(728,343);guard.velocity=Vector2.ZERO;guard.alert_state=guard.State.ALERT;guard.suspicion=1;guard.last_known_position=level.player.position;guard.set_physics_process(true)
  await create_timer(0.5).timeout
  check(absf(guard.position.x-728)<1 and absf(guard.position.y-343)<2,"Guard stays on ladder beside a climbing Miro at %dHz"%rate)
  level.queue_free();await process_frame;await process_frame
 print("GUARD_LADDER_EXIT_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
