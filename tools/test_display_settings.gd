extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("PASS: " if ok else "FAIL: ", message)
func run() -> void:
	var display = root.get_node("DisplaySettings")
	var original: Dictionary = display.preferences.duplicate()
	var original_path: String = display.settings_path
	var original_cap := Engine.max_fps
	var original_override: bool = display.frame_cap_override
	var original_vsync_override: bool = display.vsync_override
	var physics := Engine.physics_ticks_per_second
	display.settings_path = "user://test-display-settings.cfg"
	var config := ConfigFile.new()
	config.set_value("audio", "Music", -17.0)
	config.set_value("bindings", "preset", "Southpaw")
	config.save(display.settings_path)
	for cap in display.CAPS:
		display.set_preference("frame_cap",cap)
		check(display.preferences.frame_cap == cap, "Accept FPS cap " + str(cap))
		if cap >= 0: check(Engine.max_fps == cap, "Apply FPS cap " + str(cap))
		check(Engine.physics_ticks_per_second == physics, "FPS setting leaves physics rate unchanged")
	display.preferences.frame_cap = -1
	check(display.resolved_cap(239.76) == 240, "Display cap handles fractional 240 Hz")
	check(display.resolved_cap(-2.0) == 60, "Unknown refresh falls back to 60 Hz")
	display.preferences.frame_cap = -2
	check(display.resolved_cap(239.76) == 237, "VRR cap stays three FPS below 240 Hz")
	check(display.resolved_cap(143.98) == 141, "VRR cap stays below 144 Hz")
	check(display.resolved_cap(1.0) == 1, "Low reported refresh never produces Unlimited")
	display.set_preference("frame_cap",360)
	display.set_preference("frame_cap",-999)
	check(display.preferences.frame_cap == 360, "Reject invalid FPS option")
	display.set_preference("vsync",99)
	check(display.preferences.vsync in [0,1,2], "Reject invalid V-Sync mode")
	display.set_preference("window_mode",99)
	check(display.preferences.window_mode in [0,1], "Reject invalid window mode")
	display.set_preset(true)
	check(display.preferences.frame_cap == -2 and display.preferences.vsync == 0, "VRR preset selects below-refresh cap and disables in-game V-Sync")
	display.set_preset(false)
	check(display.preferences.frame_cap == -1 and display.preferences.vsync == 1, "Smooth preset matches display with V-Sync")
	display.set_preference("frame_cap",360)
	display.load_preferences()
	check(display.preferences.frame_cap == 360, "FPS cap persists after reload")
	config.load(display.settings_path)
	check(config.get_value("audio","Music") == -17.0 and config.get_value("bindings","preset") == "Southpaw", "Display saves preserve audio and input settings")
	config.set_value("display","frame_cap","bad")
	config.set_value("display","vsync",99)
	config.set_value("display","window_mode",-100)
	config.save(display.settings_path)
	display.load_preferences()
	check(display.preferences == display.DEFAULTS, "Invalid saved display values recover to defaults")
	display.frame_cap_override = true
	Engine.max_fps = 144
	display.update_display_cap()
	check(Engine.max_fps == 144, "Command-line FPS override survives monitor refresh updates")
	display.frame_cap_override = false
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu.show_screen("settings")
	await process_frame
	var button = menu.page.find_child("DisplaySettingsButton", true, false)
	check(button != null, "Main settings exposes Display button")
	button.pressed.emit()
	await process_frame
	check(menu.screen == "display", "Display button opens display screen")
	var options = menu.page.find_child("frame_cap", true, false)
	check(options != null and options.item_count == display.CAPS.size(), "Every FPS option is available in UI")
	options.select(display.CAPS.find(240))
	options.item_selected.emit(display.CAPS.find(240))
	check(display.preferences.frame_cap == 240 and Engine.max_fps == 240, "Selecting 240 in UI applies the saved cap")
	menu.show_screen("settings")
	await process_frame
	check(menu.page.find_child("Difficulty_super_hard",true,false) != null, "Display UI preserves all four difficulty choices")
	menu.queue_free()
	await process_frame
	display.preferences = original
	display.settings_path = original_path
	display.frame_cap_override = original_override
	display.vsync_override = original_vsync_override
	Engine.max_fps = original_cap
	DirAccess.remove_absolute("user://test-display-settings.cfg")
	print("DISPLAY_SETTINGS_RESULT: ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
