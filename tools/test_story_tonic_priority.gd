extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:
  failures.append(label_)
  push_error("FAIL: "+label_)
func run() -> void:
 root.get_node("Campaign").checkpoint.clear()
 var level=load("res://scenes/levels/level_02.tscn").instantiate()
 root.add_child(level)
 current_scene=level
 await process_frame
 await process_frame
 while not level.dialogue.is_empty():level.finish_dialogue()
 for guard in level.guards():guard.set_physics_process(false)
 var p=level.player
 p.set_physics_process(false)
 p.position=Vector2(464.7706,1244.924)
 p.health=p.max_health
 var world=level.world_features
 var tonic
 for prop in world.props:
  if prop.kind=="potion" and prop.global_position.distance_to(p.global_position)<20:
   tonic=prop
   break
 check(tonic!=null,"Regression fixture has the overlapping floor2 tonic")
 if tonic==null:
  quit(1)
  return
 check(world.nearby_prop()!=tonic,"Full-health tonic leaves the required story interaction available")
 check(level.station_nearby().get("id","")=="SecondSigil","Required sigil is in reach at regression position")
 p.health=p.max_health-1
 check(world.nearby_prop()==tonic,"An injured player can still select the nearby tonic")
 check(world.try_interact() and p.health==p.max_health and tonic.used,"A usable tonic heals and consumes normally")
 tonic.used=false
 level.milestones["BrotherOffer"]=true
 level.milestones["TransferLedger"]=true
 level.interact()
 check(level.dialogue_event=="milestone","Full-health E starts the sigil dialogue instead of wasting the interaction")
 while not level.dialogue.is_empty():level.finish_dialogue()
 check(level.milestones.has("SecondSigil") and level.sigil_placed,"The required sigil actually completes")
 tonic.global_position=Vector2(700,1244)
 p.global_position=tonic.global_position
 check(world.story_distance()==48.0,"Standalone tonic fixture is outside story range")
 check(world.nearby_prop()==tonic,"Standalone full-health tonic still offers its informational hint")
 check(world.try_interact() and not tonic.used and p.health==p.max_health,"Standalone full-health interaction does not consume a tonic")
 level.queue_free()
 await process_frame
 await process_frame
 print("STORY_TONIC_PRIORITY_RESULT: ",checks-failures.size(),"/",checks," passed")
 quit(0 if failures.is_empty() else 1)
