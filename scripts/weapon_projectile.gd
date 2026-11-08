extends Node2D
const TURRET_LAYER := 1 << 6
## Swept collision prevents fast rounds from tunneling through thin walls.
var level: Node2D
var shooter: CollisionObject2D
var direction := Vector2.RIGHT
var speed := 700.0
var remaining := 420.0
var damage := 2
var enemy := false
var sprite: Texture2D
var trail_start := Vector2.ZERO

func _ready() -> void:
	trail_start = position

func _physics_process(delta: float) -> void:
	if not is_instance_valid(level) or level.controls_locked():
		return
	var distance := minf(remaining, speed * delta)
	var destination := global_position + direction * distance
	var query := PhysicsRayQueryParameters2D.create(global_position, destination, 1 | (2 if enemy else 4 | TURRET_LAYER))
	query.collide_with_areas = not enemy
	if is_instance_valid(shooter):
		query.exclude = [shooter.get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not enemy and strike_guard(global_position, hit.position if not hit.is_empty() else destination):
		queue_free()
		return
	if not hit.is_empty():
		global_position = hit.position
		var target = hit.collider
		if target is IntroGuard and not target.is_dead:
			target.take_damage(1 if target.has_method("begin_recovery") else damage)
		elif not enemy and target.is_in_group("tower_turrets"):
			target.take_turret_hit()
			queue_free()
			return
		elif enemy and target is IntroPlayer:
			# A pistol round or a turret bolt takes a heart; an SMG round takes half of one.
			target.take_damage(1 if is_instance_valid(shooter) and shooter.get("weapon_kind") == "smg" else 2)
		level.emit_effect("hit", global_position)
		queue_free()
		return
	global_position = destination
	remaining -= distance
	queue_redraw()
	if remaining <= 0:
		queue_free()

func _draw() -> void:
	if sprite:
		draw_texture(sprite, -sprite.get_size() / 2.0)
	else:
		draw_line(-direction * 10, Vector2.ZERO, Color("f2d3ab"), 2)

## Guards are hit by where the round actually passes, not just their collision capsule:
## the head (a generous box) is an instant kill and the body box reaches out over the
## gun they hold, so a Keeper's weapon never blocks a shot at him. Walls and beds still do.
func strike_guard(from: Vector2, to: Vector2) -> bool:
	var length := from.distance_to(to)
	var steps := maxi(1, int(length / 3.0))
	for step in range(steps + 1):
		var point := from.lerp(to, float(step) / steps)
		for guard in level.guards():
			if not is_instance_valid(guard) or guard.is_dead or guard == shooter or not guard is IntroGuard:
				continue
			var local: Vector2 = point - guard.global_position
			var reach := 14.0
			var body := Rect2(-10.0 - (reach if guard.facing < 0 else 0.0), -22.0, 20.0 + reach, 40.0)
			var head := Rect2(-9.0, -30.0, 18.0, 14.0)
			if head.has_point(local):
				# A headshot ignores the brief hit-recovery window; Niro just takes extra damage.
				guard.invulnerability_left = 0.0
				guard.take_damage(damage * 2 if guard.has_method("begin_recovery") else 99)
				level.emit_effect("hit", point)
				return true
			if body.has_point(local):
				guard.take_damage(1 if guard.has_method("begin_recovery") else damage)
				level.emit_effect("hit", point)
				return true
	return false
