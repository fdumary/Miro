extends SceneTree
var scene: Node

func _initialize() -> void:
	call_deferred("capture")

func frames(count := 4) -> void:
	for index in range(count):
		await physics_frame
		await process_frame

func open_scene(path: String) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
		await frames()
	scene = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames()

func shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tmp/polish/%s.png" % name)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/polish")
	root.get_node("SoundFX").muted = true
	await open_scene("res://scenes/main_menu.tscn")
	await shot("menu")
	await open_scene("res://scenes/intro.tscn")
	await shot("dialogue")
	scene.finish_dialogue()
	scene.interact()
	scene.finish_dialogue()
	scene.player.position = Vector2(240, 236)
	scene.plant_c4()
	await frames(5)
	await shot("breach")
	await open_scene("res://scenes/levels/level_03.tscn")
	scene.finish_dialogue()
	scene.player.position = Vector2(300, 236)
	scene.player.get_node("Camera2D").position_smoothing_enabled = false
	scene.world_features.open_terminal()
	await frames()
	await shot("checkpoint")
	await open_scene("res://scenes/levels/level_04.tscn")
	scene.finish_dialogue()
	scene.player.position = Vector2(800, 432)
	scene.player.get_node("Camera2D").position_smoothing_enabled = false
	await frames(4)
	await shot("ward")
	scene.queue_free()
	await frames()
	for service in ["MusicDirector", "SoundFX"]:
		for voice in root.get_node(service).voices:
			voice.stop()
			voice.stream = null
	await create_timer(0.2).timeout
	quit()
