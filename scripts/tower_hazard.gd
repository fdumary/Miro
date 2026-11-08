extends Area2D
## Local up points away from the mounting surface. Aim is stored in world space.
const SPIKES := preload("res://assets/environment/spike_trap.png")
const BASE := preload("res://assets/environment/turret_body.png")
const HEAD := preload("res://assets/environment/turret_head.png")
const ROUND := preload("res://assets/misc/turret_projectile.png")
const PROJECTILE := preload("res://scripts/weapon_projectile.gd")
const PIVOT := Vector2(0, -17)
const RANGE := 185.0

var level: Node2D
var kind := "spikes"
var aim := PI
var charge := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	if kind == "spikes":
		add_to_group("lethal_spikes")
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(24, 9)
		collider.shape = shape
		collider.position.y = -4.5
		add_child(collider)
	else:
		aim = global_rotation + PI

func _physics_process(delta: float) -> void:
	if level.controls_locked() or level.player.is_dead:
		return
	if kind == "spikes":
		if overlaps_body(level.player):
			level.player.health = 0
			level.player.die()
		return
	var muzzle := to_global(PIVOT)
	var offset: Vector2 = level.player.global_position - muzzle
	if offset.length() > RANGE or level.player.is_concealed or level.player.in_hiding_spot or not level.clear_sight(muzzle, level.player.global_position):
		charge = 0.0
	else:
		aim = rotate_toward(aim, offset.angle(), delta * 4.0)
		if absf(angle_difference(aim, offset.angle())) < 0.08:
			charge += delta
			if charge >= 0.8:
				charge = 0.0
				var shot := Node2D.new()
				shot.set_script(PROJECTILE)
				shot.level = level
				shot.position = level.to_local(muzzle)
				shot.direction = Vector2.from_angle(aim)
				shot.enemy = true
				shot.remaining = RANGE
				shot.sprite = ROUND
				level.add_child(shot)
	queue_redraw()

func _draw() -> void:
	if kind == "spikes":
		draw_texture(SPIKES, Vector2(-16, -32))
		return
	draw_texture(BASE, Vector2(-16, -30))
	draw_set_transform(PIVOT, aim - global_rotation - PI)
	draw_texture(HEAD, Vector2(-25, -14), Color("f2d3ab") if charge > 0.5 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
