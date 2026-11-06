extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func wait_frames(count: int) -> void:
	for index in range(count):
		await process_frame
		await physics_frame
func save_image(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func capture() -> void:
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await wait_frames(20)
	await save_image("res://tmp/review-menu.png")
	menu.queue_free()
	await wait_frames(2)
	var level = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await wait_frames(5)
	level.finish_dialogue()
	level.player.position.x = 160
	await wait_frames(80)
	await save_image("res://tmp/overheard-guards.png")
	level.player.position = Vector2(300, 236)
	level.world_features.open_terminal()
	await wait_frames(4)
	await save_image("res://tmp/terminal-login.png")
	quit()
