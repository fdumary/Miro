extends "res://tools/test_intro.gd"

func run() -> void:
	level = load("res://scenes/levels/level_04.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(3)
	level.finish_dialogue()
	for guard in level.guards():
		guard.set_physics_process(false)

	var spikes: Area2D
	var turret: Area2D
	for child in level.get_children():
		if child.get_script() == preload("res://scripts/tower_hazard.gd"):
			if child.kind == "spikes" and spikes == null:
				spikes = child
			elif child.kind == "turret":
				turret = child
	check(spikes != null and turret != null, "Ward loads both hazards from its blueprint")
	if not spikes or not turret:
		quit(1)
		return

	var player: IntroPlayer = level.player
	var starting_health := player.health
	player.position = spikes.position + Vector2(0, -55)
	await frames(3)
	check(player.health == starting_health, "Passing above spikes is safe")
	player.position = spikes.position + Vector2(0, -15)
	await frames(8)
	check(player.health == starting_health - 1, "Spikes remove one heart on contact")

	player.position = turret.position + Vector2(168, -15)
	await frames(3)
	player.invulnerability_left = 0.0
	player.toggle_stealth()
	check(player.is_concealed, "Ward shadow lets Miro use the blanket")
	await frames(70)
	check(player.health == starting_health - 1, "Turret leaves hidden Miro alone")
	player.end_stealth()
	await frames(125)
	check(absf(angle_difference(turret.aim, 0.0)) < 0.08, "Turret head turns toward Miro")
	check(player.health < starting_health - 1, "An exposed Miro can be hit by the turret")
	print("TOWER_HAZARDS_RESULT: %d/%d passed" % [checks - failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
