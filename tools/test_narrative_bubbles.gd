extends "res://tools/test_intro.gd"
func run() -> void:
	await fresh()
	await supplies()
	var world = level.world_features
	await frames(4)
	check(world.thought_bubble.visible and world.thought_bubble.thought, "Miro has a silent thought bubble after introduction")
	var guard = level.guards()[0]
	guard.set_physics_process(false)
	guard.position = level.player.position + Vector2(40, 0)
	world.speak(guard, "password_1", "I need to log into this terminal. What was the password again?")
	await frames(3)
	check(world.speech_bubble.visible and not world.thought_bubble.visible, "Guard speech takes priority over inner dialogue")
	check(world.speech_bubble.get_global_rect().end.x <= 640 and world.speech_bubble.position.x >= 0, "Bubble remains inside viewport")
	guard.die()
	await frames(3)
	check(not world.speech_bubble.visible, "Dead speaker loses bubble")
	level.emit_effect("blood", level.player.position)
	var red := false
	for particle in level.effects.particles:
		if particle.id == "splat":
			red = particle.color.r > particle.color.g * 3 and particle.color.r > particle.color.b * 3
	check(red, "Blood uses red rather than purple")
	var ward: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/level_04.json"))
	var charges := 0
	for station in ward.stations:
		if station.kind == "sigil":
			charges += int(station.get("charge_count", 1))
	check(charges == 5 and ward.demolition_charges == 5, "Ward supplies and authored placements account for five charges")
	var final: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/level_05.json"))
	var reveal := ""
	for station in final.stations:
		if station.id == "FinalOffer":
			reveal = str(station.lines)
	check("You are immune" in reveal and "The tower made the sickness" in reveal, "Final mandatory offer contains both approved revelations")
	for number in range(2, 5):
		var earlier := FileAccess.get_file_as_string("res://data/levels/level_%02d.json" % number)
		check(not "You are immune" in earlier and not "The tower made the sickness" in earlier, "Floor %d does not reveal final lab findings" % number)
	print("NARRATIVE_BUBBLES_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
