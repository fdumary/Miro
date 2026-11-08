extends IntroGuard
## docs/class.md Brother; docs/mirospec.md final encounter.
enum Phase { TELEGRAPH, RUSH, RECOVERY }
var current_phase := Phase.TELEGRAPH
var is_vulnerable := false
var phase_left := 1.1
var attack_number := 0
var projectile := Vector2.ZERO
var projectile_velocity := Vector2.ZERO
var projectile_live := false

func _ready() -> void:
	add_to_group("guards")
	health = 6
	alert_state = State.ALERT
	sees_player = true

func _physics_process(delta: float) -> void:
	if is_dead or level.controls_locked() or level.player.is_dead:
		return
	invulnerability_left = maxf(0, invulnerability_left - delta)
	phase_left -= delta
	velocity.y += 850 * delta
	velocity.x = 0
	if current_phase == Phase.TELEGRAPH:
		facing = 1 if level.player.position.x > position.x else -1
		if phase_left <= 0:
			if attack_number % 2 == 0:
				current_phase = Phase.RUSH
				phase_left = 0.65
			else:
				projectile = global_position + Vector2(facing * 15, -5)
				projectile_velocity = (level.player.global_position - projectile).normalized() * 210
				projectile_live = true
				begin_recovery()
	elif current_phase == Phase.RUSH:
		if level.has_floor_below(global_position + Vector2(facing * 20, 0)):
			velocity.x = facing * 230
		if global_position.distance_to(level.player.global_position) < 28:
			level.player.take_damage(1)
		if phase_left <= 0 or is_on_wall():
			begin_recovery()
	elif phase_left <= 0:
		is_vulnerable = false
		attack_number += 1
		current_phase = Phase.TELEGRAPH
		phase_left = 1.1
	move_and_slide()
	if projectile_live:
		var next := projectile + projectile_velocity * delta
		if not level.clear_sight(projectile, next):
			projectile_live = false
		elif Geometry2D.get_closest_point_to_segment(level.player.global_position, projectile, next).distance_to(level.player.global_position) < 13:
			level.player.take_damage(1)
			projectile_live = false
		projectile = next
		if projectile.distance_to(global_position) > 600:
			projectile_live = false
	queue_redraw()

func begin_recovery() -> void:
	current_phase = Phase.RECOVERY
	is_vulnerable = true
	phase_left = 1.6

func receive_shank() -> void:
	take_damage(1)

func take_damage(amount: int) -> void:
	if is_vulnerable:
		super.take_damage(amount)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	level.emit_effect("blood", global_position + Vector2(0, 12))
	projectile_live = false
	velocity = Vector2.ZERO
	level.brother_defeated()
	queue_redraw()

func _draw() -> void:
	var color := Color("f2d3ab") if is_vulnerable else Color("8b6d9c")
	draw_texture_rect(preload("res://assets/characters/miro_idle.png"), Rect2(-16, -26, 32, 32), false, color)
	# A physician's coat, badge and control remote distinguish the brother.
	draw_rect(Rect2(-9, -6 if not is_dead else -3, 18, 19 if not is_dead else 8), Color("d9d9d9"))
	draw_rect(Rect2(3, -4, 4, 3), Color("b62432"))
	draw_rect(Rect2(facing * 12 - 3, -3, 6, 9), Color("494d7e"))
	if is_dead:
		return
	draw_circle(Vector2(0, -24), 7, Color("c69fa5"))
	var cue := "RECOVER" if is_vulnerable else ("RUSH" if attack_number % 2 == 0 else "THROW")
	draw_string(ThemeDB.fallback_font, Vector2(-30, -43), cue, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("fbf5ef"))
	for index in range(health):
		draw_rect(Rect2(-21 + index * 7, -36, 5, 3), Color("f2d3ab"))
	if current_phase == Phase.TELEGRAPH:
		draw_line(Vector2(0, 8), Vector2(facing * 90, 8), Color("c69fa5"), 2)
	if projectile_live:
		draw_circle(to_local(projectile), 4, Color("fbf5ef"))
