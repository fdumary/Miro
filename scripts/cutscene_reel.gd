extends Control
## Review reel: the opening and the four between-level interludes, in story order.
## Run with scenes/cutscene_reel.tscn (Play Cutscenes.ps1).
var step := 0

func _ready() -> void:
	next()

func next() -> void:
	for child in get_children():
		child.queue_free()
	if step == 0:
		var opening: Control = load("res://scenes/opening_cinematic.tscn").instantiate()
		opening.set_meta("reel", next)
		add_child(opening)
	elif step <= 4:
		var scene: Control = preload("res://scripts/interlude_cinematic.gd").new()
		scene.floor_done = step
		scene.finished.connect(next)
		add_child(scene)
	else:
		get_tree().quit()
	step += 1
