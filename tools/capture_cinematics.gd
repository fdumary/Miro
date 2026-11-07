extends SceneTree
## Stills from the cutscenes: xvfb-run godot --path . --script res://tools/capture_cinematics.gd
func _initialize() -> void:
	call_deferred("run")

func shot(path: String) -> void:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/cine")
	var opening = load("res://scenes/opening_cinematic.tscn").instantiate()
	root.add_child(opening)
	opening.set_process(false)
	for time in [2.7, 6.5, 8.8, 11.8, 15.5]:
		opening.elapsed = time
		opening.queue_redraw()
		await shot("res://tmp/cine/opening_%04.1f.png" % time)
	opening.queue_free()
	var level = load("res://scenes/levels/level_05.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	level.finish_dialogue()
	var ending = load("res://scenes/ending_cinematic.tscn").instantiate()
	ending.level = level
	level.hud.add_child(ending)
	ending.set_process(false)
	for time in [0.8, 1.8, 4.2, 6.0, 8.6, 11.6, 12.6]:
		ending.elapsed = time
		ending.queue_redraw()
		await shot("res://tmp/cine/ending_%04.1f.png" % time)
	ending.queue_free()
	level.queue_free()
	await process_frame
	var l3 = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(l3)
	current_scene = l3
	await process_frame
	l3.card.set_process(false)
	l3.card.elapsed = 1.4
	await shot("res://tmp/cine/floor_card_03.png")
	quit()
