extends SceneTree
## Saves screenshots of forced-dialogue bubbles: xvfb-run godot --path . --script res://tools/capture_dialogue_bubbles.gd
func _initialize() -> void:
	call_deferred("run")
func shot(path: String) -> void:
	for i in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp")
	var level = load("res://scenes/intro.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	level.dialogue_index = 1
	await shot("res://tmp/bubble-keeper.png")
	level.dialogue_index = 6
	await shot("res://tmp/bubble-miro.png")
	level.queue_free()
	var l3 = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(l3)
	current_scene = l3
	await shot("res://tmp/bubble-floor3-title.png")
	quit()
