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
			target.take_damage(1)
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
