extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func capture() -> void:
	var level = load("res://scenes/levels/level_04.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(5)
	level.finish_dialogue()
	var guards = level.guards()
	# Deterministic UI review fixture: exercise real corpse-loot and choice paths.
	for guard in guards:
		guard.set_physics_process(false)
		guard.die()
	level.player.loot_weapon(guards[0])
	level.player.loot_weapon(guards[1])
	level.player.loot_weapon(guards[2])
	await frames(4)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://tmp/weapon-choice.png")
	level.queue_free()
	await frames(3)
	root.get_node("MusicDirector").silence()
	quit()
