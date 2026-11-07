extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func save(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func capture() -> void:
	var level = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(5)
	level.finish_dialogue()
	await frames(5)
	await save("res://tmp/miro-thought.png")
	level.player.position.x = 160
	await frames(30)
	await save("res://tmp/guard-speech.png")
	level.queue_free()
	await frames(3)
	root.get_node("MusicDirector").silence()
	quit()
