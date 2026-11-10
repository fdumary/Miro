extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func wait_ready(music) -> void:
	for i in range(2000):
		music.poll_prefetch()
		if music.warming_path.is_empty(): return
		await process_frame
	check(false,"prefetch completed within bounded wait")
func run() -> void:
	var music=root.get_node("MusicDirector")
	music.start_floor(4)
	var initial_track: String=music.track_id
	await wait_ready(music)
	check(music.track_id == initial_track,"preload does not switch the track")
	check(music.prepared_path == str(music.catalog.sumcrazy.stream),"floor prepares next section")
	check(music.prepared_stream != null,"prepared stream exists")
	if music.prepared_stream != null:
		check(music.prepared_stream.data.size() <= music.PREPARED_STREAM_LIMIT,"prepared data fits byte budget")
	var source=music.prepared_stream
	var before := Time.get_ticks_usec()
	music.play_track("sumcrazy")
	print("PREPARED_SWITCH_US ",Time.get_ticks_usec()-before)
	check(music.track_id == "sumcrazy" and music.voices[music.active].stream != source,"play uses a duplicate to protect shared loop metadata")
	check(music.prepared_stream == null and music.prepared_path.is_empty(),"consumed preparation is released")
	music.prefetch_track("swag")
	music.prefetch_track("cyberpunk")
	await wait_ready(music)
	check(music.prepared_path == str(music.catalog.cyberpunk.stream),"latest request replaces obsolete future track")
	music.prefetch_track("invalid")
	check(music.prepared_stream == null and music.desired_path.is_empty(),"unknown tracks clear preparation")
	music.start_floor(5)
	await wait_ready(music)
	check(music.prepared_path == str(music.catalog[music.GUITAR_TRACK].stream),"guitar pickup is prepared without starting it")
	print("MUSIC_PREFETCH_RESULT: failures=",failures)
	quit(0 if failures == 0 else 1)
