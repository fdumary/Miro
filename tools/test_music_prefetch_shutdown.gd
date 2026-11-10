extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var failures := 0
	for mode in ["pending","loaded","consumed","replaced","invalidated"]:
		for repeat in range(3):
			var output: Array=[]
			var code:=OS.execute(OS.get_executable_path(),PackedStringArray(["--headless","--verbose","--path",ProjectSettings.globalize_path("res://"),"--max-fps","1000","--quit-after","10000","--script","res://tools/music_prefetch_shutdown_probe.gd","--",mode]),output,true)
			var message: String="\n".join(output)
			var ok: bool=code==0 and "SHUTDOWN_PROBE_READY" in message and not ("SCRIPT ERROR:" in message or "ERROR:" in message or "ObjectDB instance" in message or "Leaked instance:" in message or "resources still in use" in message)
			if not ok:
				failures+=1
				push_error("FAIL: shutdown "+mode+" #"+str(repeat)+"\n"+message)
	print("MUSIC_PREFETCH_SHUTDOWN_RESULT: ",15-failures,"/15 passed; failures=",failures)
	quit(0 if failures==0 else 1)
