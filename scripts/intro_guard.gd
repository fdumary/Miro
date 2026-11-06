class_name IntroGuard
extends BaseCharacter

enum State { PATROL, SUSPICIOUS, ALERT, SEARCH }
@export var patrol_left: float = 300.0
@export var patrol_right: float = 500.0
@export var sick_guard: bool = false
var level: Node2D
var alert_state: State = State.PATROL
var facing: float = 1.0
var suspicion: float = 0.0
var last_known_position := Vector2.ZERO
var search_left: float = 0.0
var attack_timer: float = 0.0
var windup: float = 0.0
var turn_wait: float = 0.0
var time: float = 0.0
var illness_started: bool = false
var seen_bodies: Array[int] = []
var key_taken: bool = false
var gun_taken: bool = false
var death_recorded: bool = false
var sees_player: bool = false
var body_reported: bool = false
var guard_name := "Keeper"
var voice_index := 0
var conversation_hold := false
var turn_away_left := 0.0
var alert_barked := false

func _ready() -> void:
	add_to_group("guards")
	health = 2
	movement_speed = 33.0 if sick_guard else 43.0

func can_see_point(point: Vector2, distance_limit: float = 165.0) -> bool:
	var difference := point - global_position
	return difference.length() < distance_limit and absf(difference.y) < 45 and difference.x * facing >= -8 and level.clear_sight(global_position + Vector2(0, -8), point + Vector2(0, -8))

func detect_player() -> bool:
	if is_dead or not level or level.player.is_dead or (level.player.is_concealed or level.player.in_hiding_spot):
		return false
	# Prisoners inside the locked cell are not escapees yet.
	if not level.door_open and level.player.global_position.x < level.get_node("Interactables/CellLock").global_position.x:
		return false
	return can_see_point(level.player.global_position)

func _physics_process(delta: float) -> void:
	time += delta
	queue_redraw()
	if not level or level.controls_locked():
		return
	if is_dead:
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	turn_wait = maxf(0.0, turn_wait - delta)
	sees_player = detect_player()
	if sees_player:
		suspicion = minf(1.0, suspicion + delta * 2.5)
		last_known_position = level.player.global_position
		search_left = 5.0
		if suspicion >= 1.0:
			alert_state = State.ALERT
			if not alert_barked and level.world_features:
				alert_barked = true
				level.world_features.bark(self, "alert")
		else:
			alert_state = State.SUSPICIOUS
	elif alert_state == State.ALERT or alert_state == State.SUSPICIOUS:
		alert_state = State.SEARCH
		search_left = 5.0
		suspicion = maxf(0.0, suspicion - delta)
	for body in level.guards():
		if body != self and body.is_dead and not seen_bodies.has(body.get_instance_id()) and can_see_point(body.global_position):
			seen_bodies.append(body.get_instance_id())
			body_reported = true
			if not sees_player:
				investigate(body.global_position)
			level.notify("%s found %s. The Keepers are searching." % [guard_name, body.guard_name])
			if level.world_features:
				level.world_features.bark(self, "body")
	velocity.x = 0
	if windup > 0:
		windup -= delta
		if windup <= 0 and sees_player and global_position.distance_to(level.player.global_position) < 35:
			level.player.take_damage(1)
	elif alert_state == State.ALERT and sees_player:
		facing = signf(last_known_position.x - global_position.x)
		if global_position.distance_to(last_known_position) < 29:
			if attack_timer <= 0:
				windup = 0.45
				attack_timer = 1.35
		else:
			velocity.x = facing * 78.0
	elif alert_state == State.SEARCH:
		search_left -= delta
		if absf(last_known_position.x - global_position.x) > 12:
			facing = signf(last_known_position.x - global_position.x)
			velocity.x = facing * 42.0
		else:
			facing = 1.0 if int(time) % 2 == 0 else -1.0
		if search_left <= 0:
			alert_state = State.PATROL
			suspicion = 0
	elif alert_state == State.PATROL:
		if conversation_hold or turn_away_left > 0:
			turn_away_left = maxf(0, turn_away_left - delta)
			velocity.y += 850.0 * delta
			move_and_slide()
			return
		if sick_guard and not illness_started:
			return
		if global_position.x <= patrol_left:
			if facing < 0:
				turn_wait = 1.8 if sick_guard else 0.8
			facing = 1
		elif global_position.x >= patrol_right:
			if facing > 0:
				turn_wait = 1.0
			facing = -1
		if turn_wait <= 0:
			velocity.x = facing * movement_speed
	# Do not walk off a floor or chase between tiers. Guards cannot climb.
	var foot := global_position + Vector2(signf(velocity.x) * 15, 12)
	if velocity.x != 0 and not level.has_floor_below(foot):
		velocity.x = 0
		facing *= -1
		if alert_state == State.SEARCH:
			last_known_position.x = global_position.x
	velocity.y += 850.0 * delta
	move_and_slide()
	if is_on_wall():
		facing *= -1

func investigate(point: Vector2) -> void:
	if is_dead or sees_player:
		return
	last_known_position = point
	search_left = 6.0
	alert_state = State.SEARCH
	suspicion = 0.3

func receive_shank() -> void:
	conversation_hold = false
	turn_away_left = 0
	var unaware := alert_state != State.ALERT and not detect_player()
	health -= 2 if unaware else 1
	if health <= 0:
		die()
	else:
		alert_state = State.ALERT
		suspicion = 1.0
		last_known_position = level.player.global_position
		facing = signf(last_known_position.x - global_position.x)
		level.notify("The Keeper turns. One more hit; dodge his wind-up with C.")

func die() -> void:
	if death_recorded:
		return
	death_recorded = true
	super.die()
	sees_player = false
	velocity = Vector2.ZERO
	level.player.casualty_count += 1
	level.notify("A body remains. Other Keepers may discover it. [E] Loot")
	queue_redraw()

func _draw() -> void:
	var ink := Color("272744")
	var blue := Color("494d7e")
	var pale := Color("f2d3ab")
	draw_string(ThemeDB.fallback_font, Vector2(-18, -36), guard_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, pale)
	if is_dead:
		draw_rect(Rect2(-15, 6, 27, 7), blue)
		draw_rect(Rect2(9, 3, 8, 7), pale)
		draw_line(Vector2(-12, 13), Vector2(17, 13), Color("8b6d9c"), 2)
		return
	if alert_state != State.PATROL or not sick_guard:
		var cone := PackedVector2Array([Vector2(0, -8), Vector2(facing * 150, -43), Vector2(facing * 150, 23)])
		draw_colored_polygon(cone, Color(0.78, 0.62, 0.65, 0.07 if alert_state != State.ALERT else 0.16))
	var coughing := sick_guard and illness_started and fmod(time, 4.0) < 1.4
	var bob := 5 if coughing else 0
	draw_rect(Rect2(-8, -4 + bob, 16, 14), blue)
	draw_rect(Rect2(-6, -13 + bob, 12, 10), pale)
	draw_rect(Rect2(-8, -17 + bob, 16, 6), ink)
	draw_rect(Rect2(-10, -12 + bob, 20, 3), Color("8b6d9c"))
	draw_rect(Rect2(facing * 4 - 1, -8 + bob, 2, 2), ink)
	draw_rect(Rect2(-7, 10, 5, 6), ink)
	draw_rect(Rect2(3, 10, 5, 6), ink)
	draw_rect(Rect2(-8, 3, 16, 3), Color("c69fa5"))
	draw_line(Vector2(facing * 9, 0), Vector2(facing * (27 if windup > 0 else 15), -9 if windup > 0 else 8), pale, 2)
	if coughing:
		draw_line(Vector2(facing * 8, 2), Vector2(facing * 6, -4), pale, 3)
		draw_circle(Vector2(facing * 14, -5 - fmod(time * 9, 12)), 1.5, Color("c69fa5"))
	if alert_state != State.PATROL:
		draw_string(ThemeDB.fallback_font, Vector2(-4, -24), "!" if alert_state == State.ALERT else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, pale)
	if sick_guard and not key_taken:
		draw_circle(Vector2(-facing * 9, 5), 2, pale)
		draw_line(Vector2(-facing * 9, 7), Vector2(-facing * 9, 12), pale, 1)
