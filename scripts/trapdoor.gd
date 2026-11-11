extends StaticBody2D
## Replaces a connector tile at runtime without changing the authored floor layout.
var level: Node2D
var route_gate: Node
var is_open := false
var open_left := 0.0
var collision: CollisionShape2D
var previous_player_position := Vector2.ZERO
var crossing_armed := false
var reward_checked := false
var previous_guard_positions: Dictionary = {}
const ART = preload("res://assets/environment/connector.png")
func _ready() -> void:
	set_physics_process(false)
	collision_layer = 1
	collision_mask = 0
	collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 28)
	collision.shape = shape
	add_child(collision)
	add_to_group("trapdoors")
func available() -> bool:
	return not is_instance_valid(route_gate) or route_gate.is_open

func activate() -> void:
	if not available():
		level.notify("Open the checkpoint or ward seal first so the return route stays accessible.")
		return
	if is_open:
		return
	is_open = true
	previous_player_position = level.player.global_position
	crossing_armed = true
	for guard in level.guards():
		previous_guard_positions[guard.get_instance_id()] = guard.global_position
	set_physics_process(true)
	open_left = 5.0
	collision.set_deferred("disabled", true)
	get_node("/root/SoundFX").play_sound("gate", -24)
	queue_redraw()
func occupied() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = global_transform
	query.collision_mask = 2 | 4
	query.margin = 0.0
	if not get_world_2d().direct_space_state.intersect_shape(query).is_empty():
		return true
	for charge in level.player.controls.planted:
		if is_instance_valid(charge) and Rect2(global_position - Vector2(14, 14), Vector2(28, 28)).has_point(charge.global_position):
			return true
	return false
func _physics_process(delta: float) -> void:
	if not is_open: return
	if level.controls_locked():
		previous_player_position = level.player.global_position
		return
	check_player_crossing()
	check_guard_crossings()
	open_left = maxf(0, open_left - delta)
	if open_left <= 0 and not occupied():
		is_open = false
		crossing_armed = false
		set_physics_process(false)
		collision.set_deferred("disabled", false)
	queue_redraw()
func check_player_crossing() -> void:
	var now: Vector2 = level.player.global_position
	if crossing_armed and not reward_checked and not level.player.is_dead:
		var before := previous_player_position
		var crossed := (before.y < global_position.y and now.y >= global_position.y) or (before.y > global_position.y and now.y <= global_position.y)
		# Scene/checkpoint teleports do not count as traversing the opening.
		if crossed and now.distance_squared_to(before) < 96.0 * 96.0:
			var t := (global_position.y - before.y) / (now.y - before.y)
			var crossing_x := lerpf(before.x, now.x, t)
			if absf(crossing_x - global_position.x) < 14.0:
				reward_checked = true
				if get_node("/root/Campaign").record_trapdoor_use():
					level.notify("Achievement: Down the Hatch · carson jbau unlocked on the MP3.", 5.0)
	previous_player_position = now

func _draw() -> void:
	if not is_open:
		draw_texture(ART, Vector2(-14, -13.5))
	else:
		draw_line(Vector2(-13, -13), Vector2(-13, 8), Color("e6a24f"), 3)
		draw_line(Vector2(13, -13), Vector2(13, 8), Color("e6a24f"), 3)
		draw_arc(Vector2(0, -20), 4, -PI / 2, -PI / 2 + TAU * open_left / 5, 16, Color("f2d3ab"), 1)

func check_guard_crossings() -> void:
	for guard in level.guards():
		if guard.is_dead:continue
		var id: int = guard.get_instance_id()
		var now: Vector2 = guard.global_position
		var before: Vector2 = previous_guard_positions.get(id, now)
		previous_guard_positions[id] = now
		if before.y < global_position.y and now.y >= global_position.y and now.distance_squared_to(before) < 96.0 * 96.0:
			var t := (global_position.y - before.y) / (now.y - before.y)
			if absf(lerpf(before.x, now.x, t) - global_position.x) < 14.0:
				get_node("/root/Campaign").unlock_achievement("guard_trapdoor")
				if not guard.asleep:
					guard.alert_state = IntroGuard.State.ALERT
					guard.suspicion = 1.0
					guard.pursuing = true
					guard.last_known_position = level.player.global_position
					guard.search_left = 8.0
