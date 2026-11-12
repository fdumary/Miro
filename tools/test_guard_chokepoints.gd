extends SceneTree
## Play the reported encounters on authored terrain with simultaneous searchers.
var level: Node2D
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label_: String) -> void:
	checks += 1
	if not ok:
		failures.append(label_)
		push_error(label_)

func fresh(number: int) -> void:
	if is_instance_valid(level):
		level.queue_free()
		await process_frame
		await process_frame
	root.get_node("Campaign").checkpoint.clear()
	level = load("res://scenes/levels/level_%02d.tscn" % number).instantiate()
	root.add_child(level)
	current_scene = level
	await create_timer(0.2).timeout
	level.finish_dialogue()
	level.set_process(false)
	level.world_features.set_process(false)
	level.player.set_physics_process(false)
	level.player.in_hiding_spot = true
	for guard: IntroGuard in level.guards():
		guard.set_physics_process(false)
		guard.position = Vector2(-1200, -1200)
	for hazard: Node in get_nodes_in_group("tower_turrets"):
		hazard.set_physics_process(false)

func start(guard: IntroGuard, at: Vector2, target: Vector2) -> void:
	guard.global_position = at
	guard.velocity = Vector2.ZERO
	guard.conversation_hold = false
	guard.illness_started = true
	guard.distracted = false
	guard.alert_state = IntroGuard.State.SEARCH
	guard.pursuing = true
	guard.last_known_position = target
	guard.search_left = 35.0
	guard.set_physics_process(true)

func descent(number: int, rate: int) -> void:
	await fresh(number)
	var ladder: IntroArea = level.areas.get_node("FirstLadder")
	var x := ladder.position.x
	var party: Array[IntroGuard] = []
	var arrived: Array[bool] = [false, false, false]
	var most := 0
	var saw_queue := false
	var quick_turns := 0
	var previous_facing := 0.0
	var previous_turn := -1000
	for i in 3:
		var g: IntroGuard = level.guards()[i]
		party.append(g)
		start(g, Vector2(x + [-49.0, -92.0, 54.0][i], 236), Vector2(x - 103, 432))
	for tick in range(rate * 18):
		await physics_frame
		var in_shaft := 0
		for i in party.size():
			var g := party[i]
			if absf(g.position.x - x) < 19.0 and g.position.y > 250 and g.position.y < 414:
				in_shaft += 1
			if g.is_on_floor() and absf(g.position.y - 433.0) < 4.0:
				arrived[i] = true
			saw_queue = saw_queue or g.waiting_at_ladder
		most = maxi(most, in_shaft)
		var waiting := party[1]
		if waiting.waiting_at_ladder:
			if waiting.facing != previous_facing and previous_facing != 0:
				if tick - previous_turn <= 2: quick_turns += 1
				previous_turn = tick
			previous_facing = waiting.facing
		else:
			previous_facing = 0
		if not arrived.has(false): break
	check(not arrived.has(false), "L%d %dHz: all three searchers reach the floor below, %s, %s / %s / %s" % [number,rate,arrived,party[0].position,party[1].position,party[2].position])
	check(most == 1 and saw_queue, "L%d %dHz: shaft used by one guard while others hold the lip" % [number,rate])
	check(quick_turns == 0, "L%d %dHz: no split-frame turns in ladder queue" % [number,rate])

func perch() -> void:
	await fresh(2)
	var one: IntroGuard = level.guards()[0]
	var two: IntroGuard = level.guards()[1]
	# L2's 28px step next to the sick prisoner: column 13, row 8.
	one.position = Vector2(378, 209)
	two.position = Vector2(351, 237)
	two.facing = 1
	await physics_frame
	check(not two.can_hop(), "L2: occupied single tile cannot receive a second jumper")
	one.position = Vector2(405, 237)
	one.facing = -1
	check(two.can_hop() and not one.can_hop(), "L2: opposite approaches cannot claim the same empty step")
	two.asleep = true
	check(one.can_hop(), "L2: a sleeping jumper no longer holds the step")

func run() -> void:
	await perch()
	for rate in [60, 120]:
		Engine.physics_ticks_per_second = rate
		for number in [2,3,4]:
			await descent(number, rate)
	print("GUARD_CHOKEPOINT_RESULT: ",checks-failures.size(),"/",checks)
	quit(0 if failures.is_empty() else 1)
