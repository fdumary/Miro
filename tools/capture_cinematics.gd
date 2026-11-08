extends SceneTree
## Stills from the cutscenes: xvfb-run godot --path . --script res://tools/capture_cinematics.gd
## Writes tmp/cine/*.png. Optional user arg "--only=<prefix>" limits to opening/ending/finale/menu/pickup/card.
var only := ""

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			only = argument.trim_prefix("--only=")
	call_deferred("run")

func shot(path: String) -> void:
	for i in range(3):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func wanted(part: String) -> bool:
	return only.is_empty() or only == part

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://tmp/cine")
	if wanted("opening"):
		var opening = load("res://scenes/opening_cinematic.tscn").instantiate()
		root.add_child(opening)
		opening.set_process(false)
		for time in [1.45, 3.0, 6.62, 7.5, 10.25, 11.5, 13.6]:
			opening.elapsed = time
			opening.queue_redraw()
			await shot("res://tmp/cine/opening_%05.2f.png" % time)
		opening.queue_free()
	if wanted("ending") or wanted("finale"):
		var level = load("res://scenes/levels/level_05.tscn").instantiate()
		root.add_child(level)
		current_scene = level
		await process_frame
		level.finish_dialogue()
		if wanted("ending"):
			var ending = load("res://scenes/ending_cinematic.tscn").instantiate()
			ending.level = level
			level.hud.add_child(ending)
			ending.set_process(false)
			for time in [0.8, 2.3, 4.2, 6.2, 6.95, 7.3, 7.9, 8.8, 10.5, 12.4, 14.0]:
				ending.elapsed = time
				ending.queue_redraw()
				await shot("res://tmp/cine/ending_%05.2f.png" % time)
			ending.queue_free()
		if wanted("finale"):
			var layer := CanvasLayer.new()
			layer.layer = 90
			level.add_child(layer)
			var finale = preload("res://scripts/finale.gd").new()
			finale.level = level
			layer.add_child(finale)
			finale.set_process(false)
			for time in [2.5, 6.0, 10.5]:
				finale.elapsed = time
				finale.queue_redraw()
				await shot("res://tmp/cine/finale_%05.2f.png" % time)
			finale.elapsed = 14.0
			finale.credits_time = 4.0
			finale.queue_redraw()
			await shot("res://tmp/cine/finale_credits_a.png")
			finale.credits_time = 30.0
			finale.queue_redraw()
			await shot("res://tmp/cine/finale_credits_b.png")
			finale.queue_free()
		level.queue_free()
		await process_frame
	if wanted("menu"):
		for completed in [false, true]:
			var backdrop = preload("res://scripts/start_backdrop.gd").new()
			root.add_child(backdrop)
			backdrop.completed = completed
			backdrop.set_process(false)
			backdrop.time = 9.03 if not completed else 5.0
			backdrop.queue_redraw()
			await shot("res://tmp/cine/menu_%s.png" % ("completed" if completed else "dusk"))
			backdrop.queue_free()
	if wanted("pickup"):
		var intro = load("res://scenes/intro.tscn").instantiate()
		root.add_child(intro)
		current_scene = intro
		await process_frame
		var card = preload("res://scripts/remote_pickup_card.gd").new()
		intro.hud.add_child(card)
		card.set_process(false)
		card.elapsed = 1.4
		card.queue_redraw()
		await shot("res://tmp/cine/pickup.png")
		intro.queue_free()
	if wanted("card"):
		var l3 = load("res://scenes/levels/level_03.tscn").instantiate()
		root.add_child(l3)
		current_scene = l3
		await process_frame
		l3.card.set_process(false)
		l3.card.elapsed = 1.4
		await shot("res://tmp/cine/floor_card_03.png")
	quit()
