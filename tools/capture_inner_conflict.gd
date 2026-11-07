extends SceneTree
## Screenshots of the inner-conflict pieces:
## xvfb-run godot --path . --script res://tools/capture_inner_conflict.gd
## A stand-in canvas (generated stripes, not an artwork) shows how a cleared painting will sit.
func _initialize() -> void:
	call_deferred("run")

func shot(path: String) -> void:
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func open(path: String):
	var level = load(path).instantiate()
	root.add_child(level)
	current_scene = level
	for i in range(8):
		await physics_frame
		await process_frame
	return level

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp")
	var level = await open("res://scenes/intro.tscn")
	var director = level.get_node("InnerConflict")
	for index in range(level.dialogue.size()):
		if level.dialogue[index].size() > 3 and str(level.dialogue[index][3]) == "choice:l1_keeper":
			level.dialogue_index = index
	await shot("res://tmp/inner-choice.png")
	level.finish_dialogue()
	var terminal = director.terminals[0]
	level.player.global_position = terminal.global_position + Vector2(-20, 0)
	await shot("res://tmp/inner-terminal.png")
	director.open_prop(terminal)
	await shot("res://tmp/inner-terminal-read.png")
	level.finish_dialogue()
	level.player.global_position = director.frame.global_position + Vector2(-24, 0)
	await shot("res://tmp/inner-frame-covered.png")
	var stripes := Image.create(120, 90, false, Image.FORMAT_RGB8)
	for x in range(120):
		for y in range(90):
			stripes.set_pixel(x, y, Color.from_hsv(0.08 + y / 400.0, 0.5, 0.35 + 0.4 * float((x / 8) % 2)))
	var stand_in := ImageTexture.create_from_image(stripes)
	director.frame.hang(director.frame.art, stand_in, "preview")
	await shot("res://tmp/inner-frame-hung.png")
	director.open_prop(director.frame)
	await shot("res://tmp/inner-frame-inspect.png")
	quit()
