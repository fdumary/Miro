extends SceneTree
var checks:=0
var failures:Array[String]=[]
class DummyPlayer extends Node2D:
	var is_dead:=false
	var controls:Dictionary={"planted": []}
class Fixture extends Node2D:
	var player:DummyPlayer
	var messages:Array=[]
	func guards() -> Array[Node]: return []
	func controls_locked() -> bool: return false
	func notify(text:String,_duration:=4.0) -> void: messages.append(text)
class PersistentCampaign extends "res://scripts/campaign.gd":
	func can_persist() -> bool: return true
	func progress_path() -> String: return "user://trapdoor-reward-test.cfg"
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message)
	print("PASS: " if ok else "FAIL: ",message)
func run() -> void:
	var campaign=root.get_node("Campaign")
	var old_earned:Dictionary=campaign.achievements_earned.duplicate()
	var old_tracks:Array=campaign.session_unlocks.duplicate()
	var old_fresh:Array=campaign.fresh_unlocks.duplicate()
	campaign.achievements_earned.erase("trapdoor_used")
	campaign.session_unlocks.erase("trapdoor_bonus")
	campaign.fresh_unlocks.erase("trapdoor_bonus")
	var fixture:=Fixture.new()
	fixture.player=DummyPlayer.new()
	fixture.add_child(fixture.player)
	root.add_child(fixture)
	var trap=load("res://scripts/trapdoor.gd").new()
	trap.level=fixture
	trap.position=Vector2(300,300)
	fixture.add_child(trap)
	check(not trap.is_physics_processing(),"Closed trapdoors do not run idle physics callbacks")
	fixture.player.position=Vector2(300,280)
	trap.activate()
	trap.set_physics_process(false)
	check(not campaign.has_achievement("trapdoor_used"),"Opening a trapdoor alone does not award traversal")
	fixture.player.position=Vector2(350,310)
	trap._physics_process(1.0/60.0)
	check(not campaign.has_achievement("trapdoor_used"),"Crossing beside the opening does not award traversal")
	trap.previous_player_position=Vector2(300,100)
	fixture.player.position=Vector2(300,320)
	trap._physics_process(1.0/60.0)
	check(not campaign.has_achievement("trapdoor_used"),"Checkpoint-sized teleports do not award traversal")
	trap.previous_player_position=Vector2(300,280)
	fixture.player.position=Vector2(300,310)
	trap._physics_process(1.0/60.0)
	check(campaign.has_achievement("trapdoor_used"),"Passing through the open trapdoor earns Down the Hatch")
	check(campaign.session_unlocks.has("trapdoor_bonus"),"Traversal adds the bonus beat to the MP3")
	var fresh:int=campaign.fresh_unlocks.count("trapdoor_bonus")
	trap.reward_checked=false
	trap.previous_player_position=Vector2(300,280)
	trap._physics_process(1.0/60.0)
	check(campaign.fresh_unlocks.count("trapdoor_bonus")==fresh and fixture.messages.size()==1,"Repeated traversal does not duplicate rewards or notifications")
	var catalogue:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/music/runtime_catalog.json"))
	var reward_stream = load(catalogue.tracks.trapdoor_bonus.stream) if catalogue.tracks.has("trapdoor_bonus") else null
	check(reward_stream is AudioStream and reward_stream.get_length()>0,"Reward is a valid playable catalogue track")
	var credits:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	var credited:=false
	var loop_credited:=false
	for block in credits.blocks:
		if block.heading=="Music composed and produced by RXLA" and "carson jbau" in block.lines: credited=true
		if block.heading=="Loop credits":
			for line in block.lines:
				if "carson jbau" in line and "prodbybeven" in line:loop_credited=true
	check(credited and loop_credited,"Reward credits RXLA and preserves prodbybeven's loop credit")
	# Real physics traversal: the player falls through the authored floor-1 opening.
	campaign.achievements_earned.erase("trapdoor_used")
	campaign.session_unlocks.erase("trapdoor_bonus")
	var real_level=load("res://scenes/intro.tscn").instantiate()
	root.add_child(real_level)
	current_scene=real_level
	for index in range(5):
		await physics_frame
		await process_frame
	while not real_level.dialogue.is_empty(): real_level.finish_dialogue()
	real_level.brother_heard=true
	for keeper in real_level.guards(): keeper.set_physics_process(false)
	var physical_trap=real_level.world_features.trapdoors[0]
	if is_instance_valid(physical_trap.route_gate): physical_trap.route_gate.is_open=true
	real_level.player.has_supplies=true
	real_level.player.position=physical_trap.global_position-Vector2(0,26)
	real_level.player.velocity=Vector2.ZERO
	real_level.player.health=10000
	physical_trap.activate()
	for index in range(90):
		await physics_frame
		await process_frame
	check(real_level.player.global_position.y>physical_trap.global_position.y+10 and campaign.has_achievement("trapdoor_used"),"Authored trapdoor awards the achievement during actual player physics traversal")
	real_level.queue_free()
	await process_frame
	await process_frame
	DirAccess.remove_absolute("user://trapdoor-reward-test.cfg")
	var probe:=PersistentCampaign.new()
	root.add_child(probe)
	check(probe.record_trapdoor_use(),"First persistent traversal commits the reward")
	probe.free()
	probe=PersistentCampaign.new()
	root.add_child(probe)
	check(probe.has_achievement("trapdoor_used") and probe.stored_unlocks().has("trapdoor_bonus"),"A fresh campaign instance reloads both achievement and beat")
	check(not probe.record_trapdoor_use(),"Persistent reward remains one-time after reload")
	probe.free()
	DirAccess.remove_absolute("user://trapdoor-reward-test.cfg")
	campaign.achievements_earned=old_earned
	campaign.session_unlocks=old_tracks
	campaign.fresh_unlocks=old_fresh
	fixture.free()
	await process_frame
	print("TRAPDOOR_REWARD_RESULT: ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
