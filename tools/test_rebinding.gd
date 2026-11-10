extends "res://tools/test_intro.gd"
func run() -> void:
	var binding=root.get_node("InputBindings")
	var previous: Dictionary=binding.custom.duplicate(true)
	var previous_preset: String=binding.preset
	await fresh()
	level.finish_dialogue()
	for guard in level.guards(): guard.set_physics_process(false)
	binding.custom={"dodge":["mouse",MOUSE_BUTTON_XBUTTON1]}
	binding.apply()
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_XBUTTON1
	event.pressed=true
	check(event.is_action("dodge"),"Mouse side button binds dash")
	var alternate:=InputEventKey.new()
	alternate.physical_keycode=KEY_C
	alternate.pressed=true
	check(alternate.is_action("dodge"),"C remains an alternate dash")
	check("Mouse 8" in binding.keyboard_prompt("[C] Dash"),"Dash prompt follows mouse assignment")
	for preset in ["Default","Bumper Jumper","Tactical","Bumper Jumper Tactical","Southpaw"]:
		binding.preset=preset
		binding.apply()
		binding.apply()
		var used={}
		for original in [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER,JOY_BUTTON_LEFT_STICK,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_TOUCHPAD,JOY_BUTTON_BACK,JOY_BUTTON_START]:
			var physical: int=binding.pad_button(original)
			check(not used.has(physical),"%s preserves distinct control %d" % [preset,original])
			used[physical]=true
			check(binding.canonical_pad(physical)==original,"%s resolves action %d" % [preset,original])
		for action in ["move_left","move_right","climb_up","climb_down"]:
			for entry in InputMap.action_get_events(action):
				if entry is InputEventJoypadMotion: check(entry.axis in [2,3] if preset=="Southpaw" else entry.axis in [0,1],"Movement stick remains correct after repeated preset application")
	binding.preset="Bumper Jumper Tactical"
	check(binding.pad_button(JOY_BUTTON_A)==JOY_BUTTON_LEFT_SHOULDER and binding.pad_button(JOY_BUTTON_LEFT_STICK)==JOY_BUTTON_RIGHT_STICK,"Bumper Jumper Tactical has L1 jump and R3 crouch")
	var save_path := "res://tmp/rebinding-test.cfg"
	binding.settings_path=save_path
	binding.save()
	var reopened=load("res://scripts/input_bindings.gd").new()
	reopened.settings_path=save_path
	root.add_child(reopened)
	check(reopened.custom.dodge==["mouse",MOUSE_BUTTON_XBUTTON1] and reopened.preset=="Bumper Jumper Tactical","Mouse binding and controller preset reload from disk")
	reopened.free()
	binding.settings_path=binding.PATH
	DirAccess.remove_absolute(save_path)
	for number in range(1,6):
		if is_instance_valid(level):
			level.queue_free()
			await frames(2)
		level=load("res://scenes/intro.tscn" if number==1 else "res://scenes/levels/level_%02d.tscn" % number).instantiate()
		root.add_child(level)
		current_scene=level
		await frames(12)
		level.finish_dialogue()
		level.player.has_supplies=true
		level.player.set_physics_process(false)
		for guard in level.guards():
			guard.set_physics_process(false)
			guard.position=Vector2(-500,-500)
		level.player.guns.assign(["pistol"])
		level.player.has_gun=true
		level.player.equipped_gun="pistol"
		for strangled in [false,true]:
			var guard=level.guards()[0]
			guard.position=Vector2(400,432)
			guard.weapon_kind="pistol"
			guard.asleep=false
			guard.strangled=false
			if strangled: guard.strangle()
			else:
				if number==5:
					level.player.position=Vector2(385,432)
					level.player.controls.has_guitar=true
					level.player.controls.strum_cooldown=0
					check(level.player.controls.strum()>0,"Actual guitar strum puts a level 5 guard to sleep")
				else: guard.fall_asleep()
			check(guard.asleep and not guard.is_dead and guard.strangled==strangled,"Unconscious pose is activated by the real sleep/strangle method")
			guard.gun_taken=false
			level.player.position=Vector2(385,432)
			var before: int=level.player.controls.reserves.get("pistol",0)
			level.interact()
			check(guard.gun_taken and level.player.controls.reserves.get("pistol",0)>before,"Floor %d ammo loots from %s guard" % [number,"strangled" if strangled else "sleeping"])
			var after: int=level.player.controls.reserves.get("pistol",0)
			level.interact()
			check(level.player.controls.reserves.get("pistol",0)==after,"Floor %d unconscious guard cannot be looted twice" % number)
	binding.custom=previous
	binding.preset=previous_preset
	binding.apply()
	var menu=load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	menu.show_screen("settings")
	await frames(3)
	check(menu.page.find_child("Difficulty_super_hard",true,false)!=null,"Settings exposes Super Hard alongside Easy, Medium and Hard")
	menu.queue_free()
	binding.open()
	await frames(3)
	check(binding.rows.size()==binding.KEYS.size(),"Settings exposes every keyboard and mouse action")
	binding.settings_path="res://tmp/rebinding-paused.cfg"
	binding.waiting="dodge"
	paused=true
	var paused_key:=InputEventKey.new()
	paused_key.physical_keycode=KEY_H
	paused_key.pressed=true
	Input.parse_input_event(paused_key)
	await process_frame
	await process_frame
	paused=false
	check(binding.custom.get("dodge")==["key",KEY_H],"Rebinding captures and saves keys while the game is paused")
	binding.close()
	binding.custom=previous
	binding.preset=previous_preset
	binding.settings_path=binding.PATH
	binding.apply()
	DirAccess.remove_absolute("res://tmp/rebinding-paused.cfg")
	print("REBINDING_RESULT: ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
