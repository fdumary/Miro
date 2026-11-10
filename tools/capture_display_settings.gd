extends SceneTree
var results: Array = []
var menu
var display
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	results.append({"pass":ok,"message":message})
	print("PASS: " if ok else "FAIL: ",message)
func shot(name_: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tmp/performance/"+name_+".png")
func run() -> void:
	var best := 0
	for index in range(DisplayServer.get_screen_count()):
		if DisplayServer.screen_get_refresh_rate(index) > DisplayServer.screen_get_refresh_rate(best): best = index
	DisplayServer.window_set_current_screen(best)
	DisplayServer.window_set_position(DisplayServer.screen_get_position(best)+Vector2i(40,40))
	display = root.get_node("DisplaySettings")
	display.settings_path = "user://display-review.cfg"
	var physics := Engine.physics_ticks_per_second
	menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.show_screen("settings")
	await create_timer(0.5).timeout
	check(menu.page.find_child("DisplaySettingsButton",true,false) != null,"Display settings reachable from main menu")
	await shot("settings-overview")
	menu.page.find_child("DisplaySettingsButton",true,false).pressed.emit()
	await process_frame
	display.set_preference("vsync",0)
	var options = menu.page.find_child("frame_cap",true,false)
	for cap in display.CAPS:
		options.select(display.CAPS.find(cap))
		options.item_selected.emit(display.CAPS.find(cap))
		await create_timer(0.25).timeout
		var samples: Array[float] = []
		var begin := Time.get_ticks_usec()
		var previous := begin
		while Time.get_ticks_usec()-begin < 700000:
			await process_frame
			var now := Time.get_ticks_usec()
			samples.append((now-previous)/1000.0)
			previous=now
		samples.sort()
		var median: float = samples[samples.size()/2]
		var expected: int = display.resolved_cap()
		check(Engine.max_fps == expected,"UI applies FPS cap " + str(cap))
		if expected > 0: check(absf(1000.0/median-expected)/expected < 0.15,"Measured frame intervals follow cap " + str(cap))
		results.append({"event":"cap_measurement","selection":cap,"engine_cap":Engine.max_fps,"median_interval_ms":median,"median_fps":1000.0/median})
	# Cap selection must also work while native V-Sync remains enabled.
	display.set_preference("vsync",1)
	for cap in [30,60,120,240]:
		options.select(display.CAPS.find(cap))
		options.item_selected.emit(display.CAPS.find(cap))
		await create_timer(0.25).timeout
		var intervals: Array[float] = []
		var begin := Time.get_ticks_usec()
		var previous := begin
		while Time.get_ticks_usec()-begin < 700000:
			await process_frame
			var now := Time.get_ticks_usec()
			intervals.append((now-previous)/1000.0)
			previous=now
		intervals.sort()
		var median: float = intervals[intervals.size()/2]
		check(Engine.max_fps == cap and absf(1000.0/median-cap)/cap < 0.15,"Selected cap works with V-Sync On: " + str(cap))
		results.append({"event":"vsync_cap_measurement","selection":cap,"median_interval_ms":median,"vsync":DisplayServer.window_get_vsync_mode()})
	display.set_preference("vsync",0)
	options.select(display.CAPS.find(360))
	options.item_selected.emit(display.CAPS.find(360))
	var counter = menu.page.find_child("ShowFPS",true,false)
	counter.button_pressed = true
	await create_timer(3.0).timeout
	check(Engine.max_fps == 360,"360 FPS option applies in graphical runtime")
	check(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED,"V-Sync Off reaches Windows display backend")
	check(display.fps_layer.visible and not display.fps_label.text.is_empty(),"FPS counter is visible with a measured rate")
	results.append({"event":"360_menu_fps","fps":Engine.get_frames_per_second(),"screen_hz":display.refresh_rate()})
	await shot("display-360-fps")
	var mode_option = menu.page.find_child("window_mode",true,false)
	mode_option.select(1)
	mode_option.item_selected.emit(1)
	await create_timer(0.5).timeout
	check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,"Borderless fullscreen applies in native Windows")
	check(DisplayServer.window_get_size() == DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()),"Borderless fullscreen fills monitor bounds rather than taskbar work area")
	mode_option.select(2)
	mode_option.item_selected.emit(2)
	await create_timer(1.0).timeout
	check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,"Fullscreen applies exclusive mode in native Windows")
	check(DisplayServer.window_get_size() == DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()),"Exclusive fullscreen fills the entire monitor")
	check(DisplayServer.window_get_position() == DisplayServer.screen_get_position(DisplayServer.window_get_current_screen()),"Fullscreen window starts at monitor origin")
	display.set_preset(true)
	display.load_preferences()
	check(display.preferences.frame_cap == -2 and display.preferences.vsync == 0,"VRR preset reloads from disk")
	check(Engine.max_fps == display.resolved_cap(),"VRR cap matches current display minus three")
	menu.show_screen("display")
	await create_timer(2.0).timeout
	await shot("display-vrr-fullscreen")
	display.set_preset(false)
	await create_timer(0.5).timeout
	check(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED,"Tear-free preset enables native V-Sync")
	display.set_preference("window_mode",0)
	await create_timer(0.5).timeout
	check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED,"Windowed mode restores successfully")
	check(Engine.physics_ticks_per_second == physics,"Native display changes preserve simulation rate")
	menu.queue_free()
	await process_frame
	var level = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await create_timer(1.0).timeout
	level.finish_dialogue()
	level.paused = true
	paused = true
	var pause_menu = level.get_node("HUD/PauseMenu") if level.has_node("HUD/PauseMenu") else level.find_child("PauseMenu",true,false)
	await process_frame
	await process_frame
	pause_menu.toggle_side("settings",true)
	await process_frame
	var display_button = pause_menu.side.find_child("DisplaySettingsButton",true,false)
	check(display_button != null,"Pause settings exposes display controls")
	if display_button == null:
		paused=false
		quit(1)
		return
	display_button.pressed.emit()
	await process_frame
	check(pause_menu.side.find_child("frame_cap",true,false) != null,"Display controls operate while gameplay is paused")
	await shot("display-pause-menu")
	paused = false
	var file = FileAccess.open("res://tmp/performance/display-native-verification.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(results,"\t"))
	file.close()
	DirAccess.remove_absolute("user://display-review.cfg")
	var failures := 0
	for item in results:
		if item.has("pass") and not item.pass: failures += 1
	print("DISPLAY_NATIVE_RESULT: ",failures," failures")
	quit(0 if failures == 0 else 1)
