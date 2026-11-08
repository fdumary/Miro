class_name IntroGuard
extends BaseCharacter

const KEEPER_IDLE = preload("res://assets/characters/standard_keeper_idle.png")
const KEEPER_WALK = preload("res://assets/characters/standard_keeper_walk.png")
const KEY_TEXTURE = preload("res://assets/environment/key.png")

enum State { PATROL, SUSPICIOUS, ALERT, SEARCH }
@export var patrol_left: float = 300.0
@export var patrol_right: float = 500.0
@export var sick_guard: bool = false
@export_enum("pistol", "smg") var weapon_kind := "pistol"
var burst_left := 0
var burst_timer := 0.0
var shot_direction := Vector2.RIGHT
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
## Individual character description from the Keeper roster.
var personality := ""
## Off duty in a huddle: absorbed in each other, they only notice Miro right on top of them.
var distracted := false
const DISTRACTED_SIGHT := 40.0
var conversation_hold := false
var turn_away_left := 0.0
var alert_barked := false
## Put to sleep by Miro's guitar (Level 5). Lootable, never counted as a kill, sleeps for the rest of the floor.
var asleep := false
## Spawned by a Level 5 wave or by Niro calling for help.
var wave_guard := false

## Difficulty (Settings): how far a Keeper sees, how fast he makes up his mind, and how hard he fights.
var sight := 165.0
var suspicion_rate := 1.0
var windup_time := 0.65
var attack_gap := 2.1
var chase_speed := 78.0
## True while a Keeper who lost sight of Miro is still running after him.
var pursuing := false
const BODY_SIGHT := 260.0
const HEARING_RANGE := 85.0
const BODY_NEARBY := 190.0
const HOP_SPEED := 300.0

func _ready() -> void:
	add_to_group("guards")
	health = 2
	movement_speed = 33.0 if sick_guard else 43.0
	var campaign = get_node_or_null("/root/Campaign")
	if campaign != null:
		var tuning: Dictionary = campaign.tuning()
		sight = float(tuning.sight)
		suspicion_rate = float(tuning.suspicion)
		windup_time = float(tuning.windup)
		attack_gap = float(tuning.attack_gap)
		chase_speed = float(tuning.chase)

func can_see_point(point: Vector2, distance_limit: float = 165.0) -> bool:
	var difference := point - global_position
	return difference.length() < distance_limit and absf(difference.y) < (80 if not is_on_floor() else (70 if absf(difference.x) < 40 else 45)) and difference.x * facing >= -8 and level.clear_sight(global_position + Vector2(0, -8), point + Vector2(0, -8))

func detect_player() -> bool:
	if is_dead or asleep or not level or level.player.is_dead or (level.player.is_concealed or level.player.in_hiding_spot):
		return false
	# Prisoners inside the locked cell are not escapees yet.
	if not level.door_open and level.player.global_position.x < level.get_node("Interactables/CellLock").global_position.x:
		return false
	return can_see_point(level.player.global_position, DISTRACTED_SIGHT if distracted else sight) or hears_player()

## Footsteps at a run: a Keeper who hears Miro pounding along close by, for about half a second,
## turns on him even unseen. A quick last step in for a pickpocket is too brief to be heard.
var heard_time := 0.0
func hears_player() -> bool:
	var p = level.player
	var difference: Vector2 = p.global_position - global_position
	if p.crouching or p.is_concealed or p.in_hiding_spot or absf(p.velocity.x) < p.movement_speed * 0.9 or absf(difference.x) >= HEARING_RANGE or absf(difference.y) >= 40.0:
		heard_time = 0.0
		return false
	heard_time += get_physics_process_delta_time()
	return heard_time > 0.5

func _physics_process(delta: float) -> void:
	time += delta
	queue_redraw()
	if not level or level.controls_locked():
		return
	if is_dead:
		return
	if asleep:
		sees_player = false
		velocity = Vector2(0, velocity.y + 850.0 * delta)
		move_and_slide()
		return
	invulnerability_left = maxf(0, invulnerability_left - delta)
	attack_timer = maxf(0.0, attack_timer - delta)
	turn_wait = maxf(0.0, turn_wait - delta)
	sees_player = detect_player()
	if sees_player:
		suspicion = minf(1.0, suspicion + delta * (3.0 if level.get("hunted") else 2.5) * suspicion_rate)
		last_known_position = level.player.global_position
		search_left = 5.0
		if suspicion >= 1.0:
			distracted = false
			alert_state = State.ALERT
			if not alert_barked and level.world_features:
				alert_barked = true
				level.world_features.bark(self, "alert")
		else:
			alert_state = State.SUSPICIOUS
	elif alert_state == State.ALERT or alert_state == State.SUSPICIOUS:
		# Losing sight of Miro mid-chase doesn't stop a Keeper: he runs on to where Miro was
		# heading, then searches. A suspicious Keeper just goes to look.
		pursuing = alert_state == State.ALERT
		if pursuing:
			var heading := signf(level.player.velocity.x)
			if heading == 0:
				heading = signf(last_known_position.x - global_position.x)
			last_known_position.x += heading * 140.0
		alert_state = State.SEARCH
		search_left = 8.0 if pursuing else 5.0
		suspicion = maxf(0.0, suspicion - delta)
	for body in level.guards():
		if body != self and body.is_dead and not seen_bodies.has(body.get_instance_id()) and notices_body(body.global_position):
			seen_bodies.append(body.get_instance_id())
			body_reported = true
			if not sees_player:
				investigate(body.global_position)
			level.notify("%s found %s. The Keepers are searching." % [guard_name, body.guard_name])
			if level.world_features:
				level.world_features.bark(self, "body")
	velocity.x = 0
	burst_timer -= delta
	if burst_left > 0 and burst_timer <= 0:
		if sees_player:
			shoot_weapon()
		else:
			burst_left = 0
	if windup > 0:
		windup -= delta
		if windup <= 0 and sees_player:
			burst_left = 1 if weapon_kind == "pistol" else 3
			shoot_weapon()
	elif alert_state == State.ALERT and sees_player:
		facing = signf(last_known_position.x - global_position.x)
		if global_position.distance_to(last_known_position) < 150:
			if attack_timer <= 0:
				windup = windup_time
				shot_direction = (level.player.global_position - global_position).normalized()
				attack_timer = attack_gap
		else:
			velocity.x = facing * chase_speed
	elif alert_state == State.SEARCH:
		search_left -= delta
		if absf(last_known_position.x - global_position.x) > 12:
			facing = signf(last_known_position.x - global_position.x)
			velocity.x = facing * (chase_speed if pursuing else 42.0)
		else:
			pursuing = false
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
				turn_wait = beat_wait(1.8 if sick_guard else 0.8)
			facing = 1
		elif global_position.x >= patrol_right:
			if facing > 0:
				turn_wait = beat_wait(1.0)
			facing = -1
		if turn_wait <= 0:
			velocity.x = facing * movement_speed * stride()
	# Do not walk off a floor or chase between tiers. Guards cannot climb.
	var foot := global_position + Vector2(signf(velocity.x) * 15, 12)
	var chasing := velocity.x != 0 and (alert_state == State.ALERT or pursuing)
	var hop_down := chasing and solid_between(foot, foot + Vector2(0, 48))
	if velocity.x != 0 and is_on_floor() and not level.has_floor_below(foot) and not hop_down:
		velocity.x = 0
		facing *= -1
		if alert_state == State.SEARCH:
			last_known_position.x = global_position.x
	# A chasing Keeper hops over anything one tile high instead of giving up at it.
	var hopping := chasing and is_on_floor() and can_hop()
	if hopping:
		velocity.y = -HOP_SPEED
	velocity.y += 850.0 * delta
	move_and_slide()
	if is_on_wall() and not hopping and not (chasing and not is_on_floor()):
		facing *= -1

func solid_between(from: Vector2, to: Vector2) -> bool:
	return not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, 1)).is_empty()

## Something knee-high directly ahead, with clear space above it to land on.
func can_hop() -> bool:
	var ahead := Vector2(facing * 20, 0)
	return solid_between(global_position + Vector2(0, 8), global_position + Vector2(0, 8) + ahead) and not solid_between(global_position + Vector2(0, -24), global_position + Vector2(0, -24) + ahead)

## Patrols keep time with the music: a Keeper turns at the end of his beat on a beat line
## (sick Keepers on every other beat) and leans into each step on the beat.
func music() -> Node:
	return get_node_or_null("/root/MusicDirector")

func beat_wait(minimum: float) -> float:
	var clock := music()
	if clock == null or clock.bpm() <= 0:
		return minimum
	var spb: float = clock.seconds_per_beat()
	var position: float = clock.beat_position()
	var every := 2.0 if sick_guard else 1.0
	var target := ceilf((position + minimum / spb) / every) * every
	return (target - position) * spb

## Averages 1.0 over a beat, so patrol timings are unchanged; the peak lands on the beat.
func stride() -> float:
	var clock := music()
	if clock == null or clock.bpm() <= 0:
		return 1.0
	var offset := fmod(clock.beat_position(), 1.0)
	return 0.7 + 0.6 * (1.0 - offset)

func shoot_weapon() -> void:
	burst_left -= 1
	burst_timer = 0.14
	var bullet := Node2D.new()
	bullet.set_script(load("res://scripts/weapon_projectile.gd"))
	bullet.level = level
	bullet.shooter = self
	bullet.enemy = true
	bullet.direction = shot_direction
	bullet.speed = 280.0
	bullet.remaining = 260.0
	bullet.position = position + Vector2(0, -4)
	level.add_child(bullet)
	get_node("/root/SoundFX").play_sound("shot", -25, 1.25 if weapon_kind == "smg" else 1.0)
	level.make_noise(global_position, 600)
	var casing := Node2D.new()
	casing.set_script(load("res://scripts/weapon_casing.gd"))
	casing.level = level
	casing.position = position
	casing.velocity = Vector2(-facing * 65, -100)
	level.add_child(casing)

func fall_asleep() -> void:
	if is_dead or asleep:
		return
	asleep = true
	alert_state = State.PATROL
	sees_player = false
	windup = 0
	burst_left = 0
	suspicion = 0

## A fallen Keeper is hard to miss: seen from further off than a sneaking prisoner, and
## noticed nearby even with his back turned.
func notices_body(point: Vector2) -> bool:
	var difference := point - global_position
	if absf(difference.y) >= 45 or not level.clear_sight(global_position + Vector2(0, -8), point + Vector2(0, -8)):
		return false
	return difference.length() < BODY_SIGHT and (difference.x * facing >= -8 or difference.length() < BODY_NEARBY)

func investigate(point: Vector2) -> void:
	if is_dead or asleep or sees_player:
		return
	distracted = false
	last_known_position = point
	search_left = 6.0
	alert_state = State.SEARCH
	suspicion = 0.3

func receive_shank() -> void:
	level.emit_effect("hit", global_position)
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
	level.emit_effect("blood", global_position + Vector2(0, 12))
	level.notify("A body remains. Other Keepers may discover it. [E] Loot")
	if level.has_method("on_keeper_killed"):
		level.on_keeper_killed(self)
	queue_redraw()

func _draw() -> void:
	var pale := Color("f2d3ab")
	draw_string(ThemeDB.fallback_font, Vector2(-18, -36), guard_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, pale)
	if asleep:
		draw_set_transform(Vector2(0, 6), PI / 2 * facing)
		draw_texture(KEEPER_IDLE, Vector2(-16, -16))
		draw_set_transform(Vector2.ZERO)
		draw_string(ThemeDB.fallback_font, Vector2(6, -14 - fmod(time * 6, 8)), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, pale)
		return
	if is_dead:
		# No dedicated death sheet yet: retain Julia's idle silhouette as a body.
		draw_set_transform(Vector2(0, 3), PI / 2)
		draw_texture(KEEPER_IDLE, Vector2(-16, -16))
		draw_set_transform(Vector2.ZERO)
		draw_carried_key()
		return
	if alert_state != State.PATROL or not sick_guard:
		var cone := PackedVector2Array([Vector2(0, -8), Vector2(facing * 150, -43), Vector2(facing * 150, 23)])
		draw_colored_polygon(cone, Color(0.78, 0.62, 0.65, 0.07 if alert_state != State.ALERT else 0.16))
	var coughing := sick_guard and illness_started and fmod(time, 4.0) < 1.4
	var moving: bool = absf(velocity.x) > 1 and level != null and not level.controls_locked()
	var texture: Texture2D = KEEPER_WALK if moving else KEEPER_IDLE
	var frame := int(time * 8) % 2 if moving else 0
	# Mirror the art, not the guard's collision, FOV or attached indicators.
	draw_set_transform(Vector2(0, 15), -facing * 0.12 if coughing else 0.0, Vector2(facing, 0.9 if coughing else 1.0))
	draw_texture_rect_region(texture, Rect2(-16, -31, 32, 32), Rect2(frame * 32, 0, 32, 32))
	draw_set_transform(Vector2.ZERO)
	draw_set_transform(Vector2(0, -4), 0, Vector2(facing, 1))
	draw_texture_rect(preload("res://scripts/weapon_art.gd").TEXTURES[weapon_kind], Rect2(0, -10, 24, 24), false)
	draw_set_transform(Vector2.ZERO)
	if windup > 0:
		draw_line(Vector2(facing * 9, 0), Vector2(facing * 27, -9), pale, 2)
	if coughing:
		draw_line(Vector2(facing * 8, 2), Vector2(facing * 6, -4), pale, 3)
		draw_circle(Vector2(facing * 14, -5 - fmod(time * 9, 12)), 1.5, Color("c69fa5"))
	if alert_state != State.PATROL:
		var reaction: Texture2D = preload("res://assets/library/alert.png") if alert_state == State.ALERT else preload("res://assets/library/question.png")
		draw_texture_rect(reaction, Rect2(-8, -35, 16, 16), false, pale)
	draw_carried_key()

func draw_carried_key() -> void:
	if sick_guard and not key_taken:
		draw_texture(KEY_TEXTURE, Vector2(-facing * 10 - 14, -12))
