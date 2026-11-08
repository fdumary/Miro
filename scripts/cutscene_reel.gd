extends Control
## Review reel: the opening, the four between-level interludes, then the tower explosion and
## the beach ending with the credits, in story order.
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
	elif step == 5:
		# The tower explosion and ending; the finale (beach, credits) follows it, then the menu.
		var stub := Node.new()
		stub.set_script(preload("res://scripts/reel_stub.gd"))
		stub.name = "ReelLevel"
		add_child(stub)
		var ending: Control = load("res://scenes/ending_cinematic.tscn").instantiate()
		ending.level = stub
		stub.add_child(ending)
	else:
		get_tree().quit()
	step += 1
