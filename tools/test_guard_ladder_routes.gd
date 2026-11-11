extends SceneTree
var checks:=0
var failures:Array[String]=[]
var level
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures.append(label_);push_error("FAIL: "+label_)
func fresh(number:int) -> void:
 if is_instance_valid(level):level.queue_free();await process_frame;await process_frame
 level=load("res://scenes/intro.tscn" if number==1 else "res://scenes/levels/level_%02d.tscn"%number).instantiate();root.add_child(level);current_scene=level;await create_timer(.2).timeout;level.finish_dialogue();level.set_process(false);level.world_features.set_process(false);level.player.set_physics_process(false);level.player.in_hiding_spot=true
 if level.has_node("Gates"):
  for gate in level.get_node("Gates").get_children():gate.unlock()
 if level.get_node_or_null("HuntWaves")!=null:level.get_node("HuntWaves").set_process(false)
 for hazard in get_nodes_in_group("tower_turrets"):hazard.set_physics_process(false)
 for g in level.guards():g.set_physics_process(false);g.position=Vector2(-1000,-1000)
func run() -> void:
 for rate in [60,360]:
  Engine.physics_ticks_per_second=rate
  for number in range(1,6):
   await fresh(number)
   var guard=level.guards()[0];guard.conversation_hold=false;guard.distracted=false;guard.illness_started=true
   for ladder in level.areas.get_children():
    if ladder.kind!="ladder":continue
    var floors:Array=[252.0,448.0,672.0] if number==1 else level.definition.get("storeys",[252.0,448.0,672.0,868.0])
    var top_edge:float=ladder.position.y-ladder.area_size.y/2
    var bottom_edge:float=ladder.position.y+ladder.area_size.y/2
    var top_floor:float=floors[0];var bottom_floor:float=floors[-1]
    for row in floors:
     if absf(float(row)-(top_edge+16))<absf(top_floor-(top_edge+16)):top_floor=float(row)
     if absf(float(row)-bottom_edge)<absf(bottom_floor-bottom_edge):bottom_floor=float(row)
    var upper:float=top_floor-16
    var bottom:float=bottom_floor-16
    var side:=1.0 if ladder.position.x<level.player.get_node("Camera2D").limit_right/2.0 else -1.0
    if not level.has_floor_below(Vector2(ladder.position.x+side*48,upper+12)) and level.has_floor_below(Vector2(ladder.position.x-side*48,upper+12)):side*=-1
    level.player.position=Vector2(ladder.position.x+side*48,upper);guard.position=Vector2(ladder.position.x,bottom);guard.velocity=Vector2.ZERO;guard.alert_state=guard.State.SEARCH;guard.pursuing=true;guard.last_known_position=level.player.position;guard.search_left=30;guard.ladder_exit_left=0;guard.ladder_exit_side=0;guard.ladder_stall_time=0;guard.set_physics_process(true)
    var landed:=false
    for tick in range(rate*7):
     await physics_frame
     if absf(guard.position.y-upper)<7 and guard.is_on_floor() and absf(guard.position.x-ladder.position.x)>20:landed=true;break
    check(landed,"Floor%d %s guard exits onto upper floor at %dHz pos%s target%s"%[number,ladder.name,rate,str(guard.position),str(level.player.position)])
    guard.set_physics_process(false)
  # An unreachable vault beyond a landing must end in a local search, never endless wall jitter.
  await fresh(1)
  var guard=level.guards()[0];guard.conversation_hold=false;guard.distracted=false;guard.illness_started=true;level.player.position=Vector2(680,236);guard.position=Vector2(308,656);guard.velocity=Vector2.ZERO;guard.alert_state=guard.State.SEARCH;guard.pursuing=true;guard.last_known_position=level.player.position;guard.search_left=30;guard.set_physics_process(true)
  await create_timer(17).timeout
  check(guard.position.y<450,"Guard completes intermediate ladder before searching blocked vault at %dHz"%rate)
  check(not guard.pursuing and guard.alert_state==guard.State.PATROL,"Blocked ladder route clears pursuit instead of getting stuck at %dHz"%rate)
 print("GUARD_LADDER_ROUTES_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
