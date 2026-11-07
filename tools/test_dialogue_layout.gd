extends "res://tools/test_intro.gd"
## Forced dialogue sits in a bubble beside the speaker: on screen, readable, never over Miro,
## and the bottom strip stays free for objectives, cues and notices.

func run() -> void:
	for number in range(1, 6):
		if is_instance_valid(level):
			level.queue_free()
			await frames(2)
		var path := "res://scenes/intro.tscn" if number == 1 else "res://scenes/levels/level_%02d.tscn" % number
		level = load(path).instantiate()
		root.add_child(level)
		current_scene = level
		await frames(3)
		var lines: Array = level.dialogue.duplicate(true)
		if number > 1:
			for station in level.definition.stations:
				lines.append_array(station.lines)
		var all_fit := true
		var clear_of_miro := true
		for line in lines:
			level.start_dialogue([line])
			await frames(2)
			var bubble: Control = level.dialogue_panel
			var label: Label = level.dialogue_label
			var rect: Rect2 = bubble.get_global_rect()
			var required_height := label.get_line_count() * label.get_line_height()
			all_fit = all_fit and bubble.visible and required_height <= label.size.y + 1 and rect.position.y >= 48 and rect.end.y <= 326 and rect.position.x >= 0 and rect.end.x <= 640
			var miro: Vector2 = level.player.get_global_transform_with_canvas().origin
			clear_of_miro = clear_of_miro and not rect.has_point(miro)
			if not all_fit:
				print("LAYOUT_MISS floor ", number, " ", line[0], " ", rect)
		check(all_fit, "Floor %d dialogue bubbles fit on screen above the cue strip" % number)
		check(clear_of_miro, "Floor %d dialogue bubbles never cover Miro" % number)
	level.finish_dialogue()
	await frames(2)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_Z
	press.pressed = true
	Input.parse_input_event(press)
	await frames(3)
	check(level.world_features.thought_bubble.visible and level.world_features.thought_bubble.text_label.text.begins_with("MIRO · thinking"), "Z shows a hint in Miro's thought bubble")
	check(AudioServer.get_bus_index("Thought") >= 0, "Thought bus with reverb exists for voiced thoughts")
	print("DIALOGUE_LAYOUT_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
