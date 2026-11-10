extends SceneTree
var frames: Array[float] = []
var previous := 0
var rows: Array = []
var collecting := false
func _initialize() -> void: call_deferred("run")
func _process(_delta: float) -> bool:
	var now := Time.get_ticks_usec()
	if collecting and previous > 0: frames.append((now-previous)/1000.0)
	previous=now
	return false
func run() -> void:
	var music = root.get_node("MusicDirector")
	for id in music.catalog:
		await create_timer(0.05).timeout
		music.prefetch_track(id)
		for i in range(2000):
			music.poll_prefetch()
			if music.warming_path.is_empty(): break
			await process_frame
		frames.clear()
		collecting=true
		var start := Time.get_ticks_usec()
		music.play_track(id,false)
		var load_ms := (Time.get_ticks_usec()-start)/1000.0
		await create_timer(0.15).timeout
		collecting=false
		var max_ms := 0.0
		for value in frames: max_ms=maxf(max_ms,value)
		rows.append({"track":id,"load_ms":load_ms,"max_interval_ms":max_ms,"playing":music.voices[music.active].playing,"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})
		print("TRACK_PROFILE ",JSON.stringify(rows.back()))
	var f := FileAccess.open("C:/Users/ethan/Miro/tmp/performance/music-transitions-prepared.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(rows,"\t"))
	quit()
