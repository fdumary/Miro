extends SceneTree
var checks:=0
var failures: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label_: String) -> void:
	checks+=1
	if not ok:failures.append(label_);push_error(label_)
func run() -> void:
	var c=root.get_node("Campaign")
	var definitions: Array=c.achievement_data()
	var expected={"kill_named":"dancehall64","ghost_2":"destroyed_lonely","kill_50":"new_age_dancehall","ghost_4":"reaper","ghost_1":"pinkghost","defeat_niro":"set_me_free"}
	for id in expected:
		c.achievements_earned.clear();c.session_unlocks.clear();c.unlock_achievement(id)
		check(c.stored_unlocks()==[expected[id]],id+" grants exactly the approved track")
	c.achievements_earned.clear();c.session_unlocks.clear();c.floor_stats.clear();c.kill_count=49
	c.on_keeper_killed("WaveKeeper",false)
	check(c.has_achievement("kill_50") and c.stored_unlocks().has("new_age_dancehall") and not c.stored_unlocks().has("reaper"),"50 kills grants new age dancehall, not Reaper")
	c.achievements_earned.clear();c.session_unlocks.clear()
	for n in range(1,5):c.floor_stats[n]={"kills":0}
	c.check_peaceful_achievements()
	check(c.stored_unlocks().has("reaper") and c.stored_unlocks().has("destroyed_lonely") and not c.stored_unlocks().has("dancehall64") and not c.stored_unlocks().has("new_age_dancehall"),"Peaceful floors grant approved Ghost tracks, never Slayer tracks")
	c.floor_stats.clear();c.achievements_earned.clear();c.session_unlocks.clear();c.floor_stats[1]={"kills":100,"stealth":100}
	check(c.update_unlocks().is_empty(),"Legacy point thresholds cannot bypass approved achievements")
	c.session_unlocks=["dancehall64"];c.achievements_earned={"ghost_2":true}
	var repaired: Array=c.unlocked_tracks()
	check(repaired.has("dancehall64") and repaired.has("destroyed_lonely"),"Existing unlocked music is preserved and corrected earned reward repaired")
	var music=root.get_node("MusicDirector")
	var credits: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	var names: Array=[]
	for block in credits.blocks:names.append_array(block.lines)
	for id in music.catalog:
		var title: String=music.catalog[id].source.get_basename()
		check(music.catalog[id].title==title and names.has(title),"Exact filename title and credit: "+id)
	var menu=load("res://scenes/main_menu.tscn").instantiate();root.add_child(menu)
	await process_frame
	var box=preload("res://scripts/menu_screens.gd").beats(menu,Rect2(0,0,1000,700))
	for id in expected:
		var button=box.find_child("Beat_"+expected[id],true,false)
		var definition: Dictionary=definitions.filter(func(a):return a.id==id)[0]
		check(button!=null and definition.label in button.tooltip_text,"Tracker matches condition for "+id)
	var rows:=0
	for id in music.catalog:
		if box.find_child("Beat_"+id,true,false)!=null:rows+=1
	check(rows==42,"Tracker contains all 42 tracks once")
	c.achievements_earned.clear();c.session_unlocks.clear()
	for entry in definitions:
		if entry.id not in ["all_achievements","guitar_acquired"]:c.achievements_earned[entry.id]=true
	c.check_all_achievements()
	check(not c.has_achievement("all_achievements") and not c.stored_unlocks().has("all_achievements"),"Completionist stays locked with one gameplay achievement missing")
	c.unlock_achievement("guitar_acquired")
	check(c.has_achievement("all_achievements") and c.stored_unlocks().has("all_achievements"),"Last ordinary achievement automatically grants YZ2")
	check(not c.unlock_achievement("all_achievements"),"Completionist earns once")
	c.achievements_earned.erase("all_achievements");c.session_unlocks.erase("all_achievements")
	check(c.unlocked_tracks().has("all_achievements"),"Existing complete save receives Completionist reward")
	var all_button=box.find_child("Beat_all_achievements",true,false)
	check(all_button.get_index()==all_button.get_parent().get_child_count()-1,"Completionist is the last beat in the tracker")
	print("ACHIEVEMENT_PATHS_RESULT: ",checks-failures.size(),"/",checks)
	quit(0 if failures.is_empty() else 1)
