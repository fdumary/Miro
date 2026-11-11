extends SceneTree
class Saved:
 extends "res://scripts/campaign.gd"
 func can_persist() -> bool:return true
 func progress_path() -> String:return "user://new-playthrough-test.cfg"
var failures:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok:bool,label_:String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(label_)
func run() -> void:
 var c=Saved.new();root.add_child(c)
 var cfg:=ConfigFile.new()
 cfg.set_value("checkpoint","data",{"floor":1,"storey":2})
 cfg.set_value("snapshots","floor_3",{"carried_from":2})
 cfg.set_value("achievements","earned",["kill_1","art_A1"])
 cfg.set_value("mp3","unlocked",["drill2","yz33"])
 cfg.set_value("levels","highest",5)
 cfg.set_value("game","completed",true)
 cfg.save(c.progress_path())
 c.checkpoint={"floor":1,"storey":2};c.floor_stats={2:{"kills":10}};c.carried_kit={"c4_count":0};c.remote_owned=true;c.boss_defeated=true
 c.start_new_playthrough()
 check(c.checkpoint.is_empty() and c.saved_checkpoint(1).is_empty(),"New playthrough clears persistent and session checkpoints")
 check(c.floor_snapshot(3).is_empty() and c.floor_stats.is_empty() and c.carried_kit.is_empty(),"Old floor snapshots, branch and inventory cannot resume")
 check(c.current_floor==1 and not c.remote_owned and not c.boss_defeated,"New run starts at Level 1 with fresh story flags")
 check(c.has_achievement("kill_1") and c.has_achievement("art_A1"),"Permanent achievements and artwork remain")
 check(c.stored_unlocks().has("drill2") and c.game_completed(),"Earned music and historical completion remain")
 cfg.load(c.progress_path());check(int(cfg.get_value("levels","highest"))==5,"Previously unlocked levels remain available")
 var menu=load("res://scenes/main_menu.tscn").instantiate();root.add_child(menu);current_scene=menu
 menu.show_screen("levels");await process_frame
 var button=menu.page.find_child("NewPlaythrough",true,false)
 check(button is Button and not button.disabled and button.focus_mode==Control.FOCUS_ALL,"Level Select exposes New Playthrough for mouse and controller")
 var actual=root.get_node("Campaign");actual.checkpoint={"floor":1,"storey":2};actual.floor_stats={2:{"kills":3}}
 var chosen: Array=[0]
 var holder:=Control.new();root.add_child(holder)
 var screen=preload("res://scripts/menu_screens.gd").level_select(holder,func(n):chosen[0]=n)
 screen.get_node("NewPlaythrough").pressed.emit()
 check(chosen[0]==1 and actual.checkpoint.is_empty() and actual.floor_stats.is_empty(),"Button clears current run and launches Level 1 through the existing cinematic path")
 # Persist different entry kits for floors 3 and 4; replaying one must not overwrite the other.
 c.carried_kit={"has_supplies":true,"has_gun":true,"guns":["pistol"],"equipped_gun":"pistol","gun_ammo":{"pistol":5},"ammunition":5,"c4_count":2,"health":6,"reserves":{"pistol":11}}
 c.carried_from=2;c.save_floor_snapshot(3)
 c.carried_kit={"has_supplies":true,"has_gun":true,"guns":["pistol","smg"],"equipped_gun":"smg","gun_ammo":{"pistol":3,"smg":9},"ammunition":9,"c4_count":1,"health":5,"reserves":{"smg":17}}
 c.carried_from=3;c.save_floor_snapshot(4)
 c.checkpoint={"floor":3,"storey":2};c.save_checkpoint()
 c.prepare_floor_replay(3)
 check(c.carried_from==2 and c.carried_kit.ammunition==5 and c.saved_checkpoint(3).is_empty(),"Replay Level 3 restores Level 2 entry kit and drops its mid-floor checkpoint")
 c.carried_kit={"guns":[],"ammunition":0};c.checkpoint={"floor":3,"storey":3};c.save_checkpoint()
 c.prepare_floor_replay(4)
 check(c.carried_from==3 and c.carried_kit.ammunition==9 and c.carried_kit.guns==["pistol","smg"],"Then replaying Level 4 restores its own original Level 3 equipment")
 actual.floor_snapshots=c.floor_snapshots.duplicate(true)
 for n in [3,4]:
  actual.prepare_floor_replay(n)
  var scene=load("res://scenes/levels/level_%02d.tscn"%n).instantiate();root.add_child(scene);current_scene=scene
  for i in range(5):await physics_frame
  var p=scene.player
  check(p.ammunition==(5 if n==3 else 9) and p.equipped_gun==("pistol" if n==3 else "smg") and p.controls.reserves.get("pistol" if n==3 else "smg")== (11 if n==3 else 17),"Actual Level %d spawns with its own saved entry weapon, ammo and reserves"%n)
  check(p.c4_count==3 and not scene.sigil_placed,"Actual replay %d starts fresh with three optional C4 and new story objectives"%n)
  p.ammunition=0;p.guns.clear()
  scene.queue_free();current_scene=null;await process_frame;await process_frame
 var reloaded=Saved.new();root.add_child(reloaded);reloaded.prepare_floor_replay(3)
 check(reloaded.carried_kit.ammunition==5,"Original Level 3 entry kit also survives a game relaunch")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(c.progress_path()))
 print("NEW_PLAYTHROUGH_RESULT: ",checks-failures,"/",checks)
 quit(0 if failures==0 else 1)
