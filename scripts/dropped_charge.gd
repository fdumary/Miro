extends Node2D
## A thrown C4 charge: a short lunge, then it sticks to the first wall, floor, ceiling, turret
## or other charge it touches. A charge on a turret rides with it.
const GRAVITY := 600.0
const LATCH := 18.0
var velocity := Vector2.ZERO
var stuck := false
var attached: Node2D
var attach_offset := Vector2.ZERO

func _ready() -> void:
	add_to_group("c4_charges")

func _physics_process(delta: float) -> void:
	if get_parent().controls_locked():
		return
	if stuck:
		if attached != null:
			if is_instance_valid(attached) and attached.get("health") != 0:
				global_position = attached.global_position + attach_offset
			else:
				# Whatever it was stuck to is gone: drop to the floor.
				attached = null
				stuck = false
		return
	velocity.y += GRAVITY * delta
	var start := global_position
	var target := start + velocity * delta
	# Latch onto a live turret or another stuck charge the throw passes close to.
	for node in get_tree().get_nodes_in_group("tower_turrets") + get_tree().get_nodes_in_group("c4_charges"):
		if node == self or not is_instance_valid(node) or node.get("health") == 0 or (node.is_in_group("c4_charges") and not node.stuck):
			continue
		var anchor: Vector2 = node.target_point() if node.has_method("target_point") else node.global_position
		var closest := Geometry2D.get_closest_point_to_segment(anchor, start, target)
		if closest.distance_to(anchor) < LATCH:
			var away := (start - anchor).normalized() if start != anchor else Vector2.UP
			global_position = anchor + away * 6.0
			stick(node)
			return
	var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(start, target, 1))
	if hit.is_empty():
		global_position = target
	else:
		global_position = hit.position + hit.normal * 4.0
		stick(null)

func stick(to: Node2D) -> void:
	stuck = true
	velocity = Vector2.ZERO
	attached = to
	if to != null:
		attach_offset = global_position - to.global_position

func _draw() -> void:
	draw_texture_rect(preload("res://assets/weapons/c4.svg"), Rect2(-7, -7, 14, 14), false)
