extends SceneTree
## Whole-level overview images: xvfb-run godot --path . --script res://tools/capture_level_overview.gd [-- 2 3 4]
## Writes res://tmp/overview_level_0N.png at 1:1 scale (no HUD), plus three in-game views per level.
func _initialize() -> void:
	call_deferred("run")

func shot(path: String) -> void:
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp")
	var numbers := OS.get_cmdline_user_args()
	if numbers.is_empty():
		numbers = PackedStringArray(["2", "3", "4"])
	for value in numbers:
		var number := int(value)
		var level = load("res://scenes/levels/level_%02d.tscn" % number).instantiate()
		root.add_child(level)
		current_scene = level
		await process_frame
		level.finish_dialogue()
		for views in [[0.12, 0.2], [0.5, 0.55], [0.8, 0.9]]:
			level.player.position = Vector2(level.definition.world_size[0] * views[0], 0)
			var floor_y: float = level.definition.storeys[int(views[1] * 5.99)]
			level.player.position.y = floor_y - 14
			level.player.get_node("Camera2D").reset_smoothing()
			await shot("res://tmp/view_level_%02d_%d.png" % [number, int(views[1] * 10)])
		level.hud.visible = false
		var size := Vector2i(int(level.definition.world_size[0]), int(level.definition.world_size[1]))
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		root.size = size
		var camera := Camera2D.new()
		camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
		level.add_child(camera)
		camera.make_current()
		await shot("res://tmp/overview_level_%02d.png" % number)
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.size = Vector2i(1280, 720)
		level.queue_free()
		await process_frame
	quit()
