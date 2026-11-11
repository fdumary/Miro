extends SceneTree
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+label_)
func frames(n:=3) -> void:
 for i in range(n):await physics_frame;await process_frame
func run() -> void:
 var campaign=root.get_node("Campaign");campaign.checkpoint.clear()
 var level=load("res://scenes/levels/level_04.tscn").instantiate();root.add_child(level);current_scene=level;await frames();level.finish_dialogue()
 for g in level.guards():g.set_physics_process(false)
 var p=level.player;p.set_physics_process(false);p.has_supplies=true
 check(p.c4_count==3,"Level four starts with three carried C4")
 p.position=Vector2(600,-1000);p.controls.drop_charge();check(p.c4_count==2,"First optional charge consumes one")
 p.controls.drop_charge();check(p.c4_count==1,"Second optional charge consumes one")
 p.controls.drop_charge();check(p.c4_count==1 and p.controls.planted.size()==2,"Last charge reserved; no free spare appears")
 level.milestones["BrotherWarning"]=true;p.global_position=level.areas.get_node("WardChargeWest").global_position
 level.interact();level.finish_dialogue();check(level.milestones.has("WardChargeWest") and p.c4_count==1,"Story supports activate without consuming carried inventory")
 var inner=level.get_node("InnerConflict");var behavior=root.get_node("PlayerBehavior")
 behavior.committed.clear();behavior.pending_scores={"defiant":10};behavior.last_selected="defiant"
 var picks:Dictionary={}
 for i in range(40):
  inner.assign_frame(true);picks[inner.frame.art_id]=true
  check(inner.frame.art.themes.any(func(t):return t in ["defiance","betrayal"]),"Artwork matches active playstyle themes")
 check(picks.size()>1,"Repeated visits can select different themed paintings")
 var reachable:Dictionary={}
 for style in ["neutral","ghost","blackhat","defiant","survivor","seeker"]:
  behavior.pending_scores={} if style=="neutral" else {style:100};behavior.last_selected=style
  for i in range(200):inner.assign_frame(true);reachable[inner.frame.art_id]=true
 check(reachable.size()==27,"All 27 works reachable through playstyle selection")
 print("C4_ART_RELEASE_RESULT: ",checks-failures,"/",checks," passed")
 quit(0 if failures==0 else 1)
