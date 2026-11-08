extends SceneTree
## Stills of the start menu screens and the pause menu (tmp/menu_*.png).
## Runs as a player (--player) unless --dev is passed, so locked floors and beats show.
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
	var campaign = root.get_node("Campaign")
	campaign.session_level = 3
	campaign.session_unlocks = ["birthday_melody", "destroyed_lonely", "drill2"]
	var menu = load("res://scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	for screen in ["title", "levels", "beats", "settings"]:
		menu.show_screen(screen)
		await wait_frames(6)
		await save_image("res://tmp/menu_%s.png" % screen)
	menu.queue_free()
	await wait_frames(2)
	var level = load("res://scenes/levels/level_02.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await wait_frames(5)
	level.finish_dialogue()
	level.paused = true
	paused = true
	await wait_frames(6)
	await save_image("res://tmp/menu_pause.png")
	level.pause_menu.toggle_side("settings")
	await wait_frames(4)
	await save_image("res://tmp/menu_pause_settings.png")
	quit()
