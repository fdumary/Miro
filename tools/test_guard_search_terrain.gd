extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("run")

func block(level: Node, center: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	var collider := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	collider.shape = rect
	body.add_child(collider)
	body.position = center
	level.add_child(body)
	return body

func run() -> void:
	var level = load("res://scenes/levels/level_03.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await physics_frame
	level.finish_dialogue()
	level.set_process(false)
	level.world_features.set_process(false)
	level.player.set_physics_process(false)
	level.player.in_hiding_spot = true
	var guard = level.guards()[0]
	var origin := Vector2(-2000, -1000)
	block(level, origin + Vector2(0, 10), Vector2(500, 20))
	for rate in [60, 360]:
		Engine.physics_ticks_per_second = rate
		for obstacle in ["step", "wall", "crawlspace"]:
			var size := Vector2(28, 28 if obstacle == "step" else 56)
			var center := origin - Vector2(0, size.y / 2)
			if obstacle == "crawlspace":
				center.y -= 16 # Miro can crouch here; the standing guard cannot.
			var terrain := block(level, center, size)
			guard.position = origin + Vector2(-56, -15)
			guard.sweep_origin = INF
			guard.velocity = Vector2.ZERO
			guard.conversation_hold = false
			guard.alert_state = guard.State.SEARCH
			guard.last_known_position = origin + Vector2(50, -15)
			guard.pursuing = true
			guard.search_left = 8
			var peak := 0.0
			var closest := -INF
			var retreat := 0.0
			for tick in range(rate * 2):
				await physics_frame
				closest = maxf(closest, guard.position.x)
				retreat = maxf(retreat, closest - guard.position.x)
				peak = maxf(peak, origin.y - 15 - guard.position.y)
			var passed: bool = closest > origin.x + 24 if obstacle == "step" else guard.position.x < origin.x and peak < 2 and retreat > 24 and not guard.pursuing
			if not passed:
				failed = true
				push_error("%s at %d Hz: position=%s rise=%f pursuing=%s" % [obstacle, rate, guard.position-origin, peak, guard.pursuing])
			terrain.queue_free()
			await process_frame
	# Several guards share the same last sighting beyond an impassable wall.
	block(level, origin + Vector2(45, -28), Vector2(28, 56))
	var group: Array = level.guards().slice(0, 5)
	for i in group.size():
		var g = group[i]
		g.position = origin + Vector2(-48 - i * 3, -15)
		g.sweep_origin = INF
		g.velocity = Vector2.ZERO
		g.conversation_hold = false
		g.alert_state = g.State.SEARCH
		g.last_known_position = origin + Vector2(100, -15)
		g.pursuing = true
		g.search_left = 12
	for tick in range(720):
		await physics_frame
	for i in group.size():
		for j in range(i):
			if absf(group[i].position.x - group[j].position.x) < 24 or absf(group[i].position.y - group[j].position.y) > 2:
				failed = true
				push_error("Crowded guards: %s / %s" % [group[i].position, group[j].position])
	print("GUARD_SEARCH_TERRAIN_RESULT: ", not failed)
	quit(1 if failed else 0)
