extends "res://tools/test_intro.gd"
func run() -> void:
	level = load("res://scenes/levels/level_02.tscn").instantiate()
	root.add_child(level)
	current_scene = level
	await frames(10)
	level.finish_dialogue()
	var c = level.player.controls
	c.show_console(true, true)
	await frames(3)
	check(c.command.keep_editing_on_text_submit, "Terminal keeps editing after Enter")
	check(c.command.has_focus(), "Terminal text box starts focused")
	c.command.text = "whoami"
	c.command.text_submitted.emit("whoami")
	await frames(3)
	check(c.command.has_focus(), "Text box keeps focus after a command")
	c.command.text = "help"
	c.command.text_submitted.emit("help")
	await frames(3)
	check(c.command.has_focus(), "...and after a second command")
	print("FOCUS_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)
