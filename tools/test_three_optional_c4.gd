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
 p.controls.drop_charge();check(p.c4_count==0 and p.controls.planted.size()==3,"Third optional charge is usable before the story support")
 p.controls.drop_charge();check(p.c4_count==0 and p.controls.planted.size()==3,"Fourth optional charge is unavailable")
 level.milestones["BrotherWarning"]=true;p.global_position=level.areas.get_node("WardChargeWest").global_position
 level.interact();level.finish_dialogue();check(level.milestones.has("WardChargeWest") and p.c4_count==0,"Story reserve works after all three optional charges are spent")
 print("THREE_OPTIONAL_C4_RESULT: ",checks-failures,"/",checks," passed")
 quit(0 if failures==0 else 1)
