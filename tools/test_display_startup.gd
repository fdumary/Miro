extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var display=root.get_node("DisplaySettings")
	var ok:bool=Engine.max_fps==60 and display.frame_cap_override
	display.update_display_cap()
	ok=ok and Engine.max_fps==60
	print("DISPLAY_STARTUP_RESULT: ","3/3 passed" if ok else "FAIL: explicit 60 FPS startup cap was overridden")
	quit(0 if ok else 1)
