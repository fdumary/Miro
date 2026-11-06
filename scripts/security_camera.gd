extends Area2D
## docs/class.md: SecurityCamera; docs/mirospec.md: Level 3 checkpoint.
@export var detection_range := 210.0
@export var half_angle := 0.48
@export var facing_angle := 1.57
var is_active := true
var sweep_time := 0.0
var alert_cooldown := 0.0
var level: Node
var cone_points := PackedVector2Array()

func _physics_process(delta: float) -> void:
	if not is_active or level.controls_locked():
		return
	sweep_time += delta
	cone_points = PackedVector2Array([Vector2.ZERO])
	for index in range(25):
		var tip := global_position + Vector2.from_angle(direction_angle() - half_angle + 2 * half_angle * index / 24.0) * detection_range
		var query := PhysicsRayQueryParameters2D.create(global_position, tip, 1)
		var hit := get_world_2d().direct_space_state.intersect_ray(query)
		cone_points.append(to_local(hit.position if not hit.is_empty() else tip))
	alert_cooldown = maxf(0, alert_cooldown - delta)
	if detects_player() and alert_cooldown <= 0:
		alert_cooldown = 2.0
		level.camera_alert(level.player.global_position)
	queue_redraw()

func direction_angle() -> float:
	return facing_angle + sin(sweep_time * 0.7) * 0.4

func detects_player() -> bool:
	if not is_active or level.player.is_dead or (level.player.is_concealed or level.player.in_hiding_spot):
		return false
	var offset: Vector2 = level.player.global_position - global_position
	return offset.length() <= detection_range and absf(wrapf(offset.angle() - direction_angle(), -PI, PI)) <= half_angle and level.clear_sight(global_position, level.player.global_position)

func disable() -> void:
	is_active = false
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-9, -5, 18, 10), Color("494d7e"))
	draw_circle(Vector2.ZERO, 3, Color("c69fa5") if is_active else Color("8b6d9c"))
	if is_active and cone_points.size() > 2:
		draw_colored_polygon(cone_points, Color(0.95, 0.83, 0.67, 0.12))
