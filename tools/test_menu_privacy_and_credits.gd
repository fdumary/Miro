extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:
		failures.append(message)
		push_error("FAIL: "+message)
func run() -> void:
	var campaign=root.get_node("Campaign")
	var earned:Dictionary=campaign.achievements_earned.duplicate()
	campaign.achievements_earned.clear()
	var menu=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	check(menu.page.find_child("BeatsButton",true,false).text=="Achievements","Main menu names the achievement collection clearly")
	menu.page.find_child("BeatsButton",true,false).pressed.emit()
	check(menu.screen=="beats","Achievements still opens the existing rewards collection")
	var works:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/art_catalog.json")).works
	var panel=menu.page.find_child("ArtPanel",true,false)
	var grid=panel.get_child(0)
	check(grid.get_child_count()==works.size(),"All gallery entries remain present")
	for cell in grid.get_children():
		check(cell.get_child(1).text=="??? — ???","Locked painting masks title and artist")
		check(not cell.get_child(0) is TextureButton,"Locked painting cannot open full artwork")
	campaign.achievements_earned["art_"+str(works[0].id)]=true
	menu.show_screen("beats")
	panel=menu.page.find_child("ArtPanel",true,false)
	grid=panel.get_child(0)
	check(grid.get_child(0).get_child(1).text=="%s — %s" % [str(works[0].title),str(works[0].artist)],"Unlock reveals correct title and artist")
	for i in range(1,grid.get_child_count()): check(grid.get_child(i).get_child(1).text=="??? — ???","Other paintings stay masked after one unlock")
	var settings=load("res://scripts/controller_settings_panel.gd").new()
	menu.add_child(settings)
	settings.setup(func(): pass)
	check(settings.speaker.text=="Remote dialogue on controller speaker","Speaker setting uses neutral wording")
	check(not "niro" in settings.speaker_status.text.to_lower(),"Speaker help does not reveal character name")
	var credits=JSON.parse_string(FileAccess.get_file_as_string("res://data/credits.json"))
	var credited:=false
	for block in credits.blocks:
		if block.heading=="Loop credits":
			for line in block.lines:
				if "not new jazz x pinkghost" in str(line).to_lower() and "Pinkghost" in str(line): credited=true
	check(credited,"Pinkghost is named under loop credits for not new jazz x pinkghost")
	menu.show_screen("controller")
	var controller_box=menu.page.find_child("ControllerSettings",true,false)
	check(controller_box.get_parent() is ScrollContainer,"Controller preferences remain scrollable")
	check(controller_box.get_parent().get_parent() is PanelContainer,"Controller settings have a readable panel background")
	campaign.achievements_earned=earned
	menu.queue_free()
	await process_frame
	await process_frame
	print("MENU_PRIVACY_CREDITS_RESULT: ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
