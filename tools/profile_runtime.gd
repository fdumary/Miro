extends SceneTree
var level
var floor_number := 1
var enabled := false
var stage := "startup"
var rows: Array = []
var events: Array = []
var last_us := 0
var start_us := 0
var active := false
var shot_count := 0
var discovery_count := 0
var stem := ""
var smoke := false
var endpoint := ""
var perf_tag := ""
var output_dir := "res://tmp/performance"
var expected_fps := -1
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--perf-output="): output_dir = arg.trim_prefix("--perf-output=").replace("\\", "/")
		if arg.begins_with("--perf-expected-fps="): expected_fps = int(arg.get_slice("=",1))
		if arg.begins_with("--perf-tag="): perf_tag = arg.trim_prefix("--perf-tag=")
		if arg.begins_with("--perf-floor="): floor_number = int(arg.get_slice("=", 1))
		if arg == "--perf-speaker": enabled = true
		if arg == "--perf-smoke": smoke = true
		if arg.begins_with("--perf-endpoint="): endpoint = arg.trim_prefix("--perf-endpoint=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	stem = output_dir.path_join("floor_%d_%s" % [floor_number, "worker" if not endpoint.is_empty() else ("on" if enabled else "off")])
	if not perf_tag.is_empty(): stem += "_" + perf_tag
	start_us = Time.get_ticks_usec()
	last_us = start_us
	call_deferred("run")
func _process(_delta: float) -> bool:
	var now := Time.get_ticks_usec()
	if active:
		var radio = root.get_node("RemoteRadio")
		rows.append([now - start_us, stage, (now-last_us)/1000.0, Performance.get_monitor(Performance.TIME_PROCESS)*1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0, Performance.get_monitor(Performance.OBJECT_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT), Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT), Performance.get_monitor(Performance.MEMORY_STATIC), Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED), Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), radio.controller_link.pid, radio.controller_link.ready])
		if is_instance_valid(level) and is_instance_valid(level.player):
			level.player.health = 10000
			level.player.is_dead = false
	last_us = now
	return false
func wait_seconds(seconds: float) -> void:
	await create_timer(seconds).timeout
func mark(name_: String, extra: Dictionary = {}) -> void:
	stage = name_
	extra["stage"] = stage
	extra["elapsed_us"] = Time.get_ticks_usec()-start_us
	events.append(extra)
	print("PERF_STAGE ", JSON.stringify(extra))
func scene_path() -> String:
	return "res://scenes/intro.tscn" if floor_number == 1 else "res://scenes/levels/level_%02d.tscn" % floor_number
func fresh(tag: String) -> void:
	mark(tag)
	if is_instance_valid(level):
		level.queue_free()
		await process_frame
		await process_frame
	var begin := Time.get_ticks_usec()
	level = load(scene_path()).instantiate()
	root.add_child(level)
	current_scene = level
	events.append({"event":"instantiate_ready", "stage":tag,"duration_ms":(Time.get_ticks_usec()-begin)/1000.0})
	await wait_seconds(1.0)
func unlock() -> void:
	while not level.dialogue.is_empty(): level.finish_dialogue()
	level.player.has_supplies = true
	level.player.health = 10000
	level.player.is_dead = false
func save() -> void:
	var f = FileAccess.open(stem+"_frames.csv", FileAccess.WRITE)
	f.store_csv_line(PackedStringArray(["elapsed_us","stage","interval_ms","process_ms","physics_ms","nodes","orphans","resources","static_bytes","render_video_bytes","texture_bytes","worker_pid","worker_ready"]))
	for row in rows:
		var line := PackedStringArray()
		for v in row: line.append(str(v))
		f.store_csv_line(line)
	f.close()
	var e = FileAccess.open(stem+"_events.json",FileAccess.WRITE)
	e.store_string(JSON.stringify(events,"\t"))
	e.close()
func run() -> void:
	if expected_fps >= 0 and Engine.max_fps != expected_fps:
		push_error("Profiling launcher cap mismatch: expected %d, actual %d" % [expected_fps, Engine.max_fps])
		quit(1)
		return
	if Engine.max_fps > 60 and DisplayServer.get_name() != "headless":
		var best := 0
		for index in range(DisplayServer.get_screen_count()):
			if DisplayServer.screen_get_refresh_rate(index) > DisplayServer.screen_get_refresh_rate(best): best = index
		DisplayServer.window_set_current_screen(best)
		DisplayServer.window_set_position(DisplayServer.screen_get_position(best)+Vector2i(40,40))
	root.get_node("ControllerSettings").preferences.speaker_enabled = enabled
	root.get_node("ControllerSettings").preferences.speaker_endpoint = endpoint
	var radio = root.get_node("RemoteRadio")
	mark("environment", {"pid":OS.get_process_id(),"devices":AudioServer.get_output_device_list(),"speaker_enabled":enabled,"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"build_kind":"template" if OS.has_feature("template") else "editor","executable":OS.get_executable_path(),"physics_hz":Engine.physics_ticks_per_second,"max_fps":Engine.max_fps,"vsync":DisplayServer.window_get_vsync_mode(),"screen":DisplayServer.window_get_current_screen(),"screen_hz":DisplayServer.screen_get_refresh_rate(),"joypads":Input.get_connected_joypads(),"joypad_names":Input.get_connected_joypads().map(func(id): return Input.get_joy_name(id))})
	active = true
	await fresh("cold_entry")
	await wait_seconds(4.0)
	if smoke:
		save()
		quit()
		return
	unlock()
	mark("baseline")
	await wait_seconds(5.0)
	mark("smg_combat")
	var p = level.player
	p.position = Vector2(350, 236 if floor_number == 1 else float(level.definition.get("storeys", [236.0])[0]))
	for guard in level.guards(): guard.health = 10000
	p.has_gun = true
	p.guns.assign(["smg"])
	p.equipped_gun = "smg"
	p.ammunition = 1000
	p.controls.active = "smg"
	p.mouse_aim = false
	p.facing = 1
	for i in range(110):
		if not level.dialogue.is_empty(): unlock()
		p.health = 10000
		var before: int = p.ammunition
		p.fire_gun()
		if p.ammunition < before: shot_count += 1
		await wait_seconds(0.14)
	events.append({"event":"combat_complete","shots":shot_count,"guards":level.guards().size()})
	await fresh("body_setup")
	unlock()
	# Explicit fixture: multiple discoveries by live AI, preserving native perception/raycast logic.
	p = level.player
	var row_y := 236.0 if floor_number == 1 else float(level.definition.get("storeys", [236.0])[0])
	p.position = Vector2(950,row_y)
	p.in_hiding_spot = true
	var guards: Array = level.guards()
	var count := mini(3, guards.size()/2)
	for i in range(count):
		var victim = guards[i]
		victim.position = Vector2(400+i*45,row_y)
		victim.is_dead = true
		victim.asleep = false
		victim.queue_redraw()
		var observer = guards[count+i]
		observer.position = Vector2(530+i*30,row_y)
		observer.facing = -1
		observer.seen_bodies.clear()
		observer.seen_sleepers.clear()
	mark("body_discovery",{"victims":count})
	await wait_seconds(6.0)
	for guard in level.guards(): discovery_count += guard.seen_bodies.size()
	events.append({"event":"body_complete","discovery_pairs":discovery_count})
	unlock()
	mark("dialogue")
	for i in range(5):
		var line := str(level.FLOOR_END_LINES.get(i+1,"...Miro?"))
		level.start_dialogue([["NIRO",line]],"perf")
		await wait_seconds(1.8)
		events.append({"event":"dialogue_transition","index":i,"worker_ready":radio.controller_link.ready,"worker_pid":radio.controller_link.pid,"controller_playing":radio.controller_playing})
		level.finish_dialogue()
	for i in range(5):
		mark("retry_%d" % (i+1))
		var event := InputEventAction.new()
		event.action = "retry"
		event.pressed = true
		level._unhandled_input(event)
		await scene_changed
		level = current_scene
		await wait_seconds(1.0)
		unlock()
		await wait_seconds(1.0)
		mark("retry_settled_%d" % (i+1),{"nodes":get_node_count(),"orphans":Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)})
	await wait_seconds(2.0)
	mark("complete",{"shots":shot_count,"discovery_pairs":discovery_count,"worker_ready":radio.controller_link.ready})
	save()
	radio.stop()
	radio.controller_link.close()
	quit()
