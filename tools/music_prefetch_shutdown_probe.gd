extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var music=root.get_node("MusicDirector")
	var mode: String=OS.get_cmdline_user_args()[0]
	music.prefetch_track("sumcrazy")
	if mode in ["loaded","consumed"]:
		var deadline := Time.get_ticks_msec()+3000
		while not music.warming_path.is_empty() and Time.get_ticks_msec()<deadline:
			await create_timer(0.005).timeout
			music.poll_prefetch()
		if music.prepared_stream == null:
			push_error("FAIL: preparation did not finish")
			quit(1)
			return
		if mode == "consumed":
			music.play_track("sumcrazy")
			music.prefetch_track("cyberpunk")
	elif mode == "replaced": music.prefetch_track("swag")
	elif mode == "invalidated": music.prefetch_track("not_a_track")
	print("SHUTDOWN_PROBE_READY ",mode)
	quit()
