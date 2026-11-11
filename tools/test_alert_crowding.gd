extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.get_node("Campaign").checkpoint.clear()
 var level=load("res://scenes/levels/level_03.tscn").instantiate();root.add_child(level);current_scene=level
 for i in range(4):await physics_frame
 level.finish_dialogue();level.player.set_physics_process(false);level.player.global_position=Vector2(100,236)
 var guards=level.guards();var a=guards[0];var b=guards[1]
 for g in guards:
  if g!=a and g!=b:g.set_physics_process(false);g.global_position=Vector2(100,236)
 a.global_position=Vector2(1100,1244);b.global_position=Vector2(1100,1216)
 for g in [a,b]:g.alert_state=g.State.SEARCH;g.pursuing=true;g.last_known_position=Vector2(1300,1244);g.search_left=10.0
 for i in range(500):
  if not level.dialogue.is_empty():level.finish_dialogue()
  await physics_frame
 var okay=absf(a.global_position.y-b.global_position.y)<8 and absf(a.global_position.x-b.global_position.x)>=16
 print("ALERT_CROWD_RESULT: ",okay," positions=",a.global_position," ",b.global_position)
 if not okay:push_error("FAIL: alerted guards remain stacked or merged")
 quit(0 if okay else 1)
