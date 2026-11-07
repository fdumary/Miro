class_name IntroPlayer
extends BaseCharacter

var level: Node2D
var facing: float = 1.0
var is_concealed: bool = false
@export var stealth_duration := 5.0
@export var stealth_cooldown := 8.0
@export_range(0.1, 1.0) var stealth_speed_multiplier := 0.55
var stealth_remaining := 0.0
var stealth_cooldown_left := 0.0
var casualty_count: int = 0
var detection_state: String = "unseen"
var has_supplies: bool = false
var has_key: bool = false
var has_gun: bool = false
var suppressor_uses := 0
var in_hiding_spot := false
var ammunition: int = 0
var c4_count: int = 0
var attack_cooldown: float = 0.0
var dodge_left: float = 0.0
var dodge_cooldown: float = 0.0
var animation_time: float = 0.0
var climbing: bool = false
var attack_flash: float = 0.0
var footstep_left := 0.0
var mouse_aim := false
var aim_direction := Vector2.RIGHT
const IDLE = preload("res://assets/characters/miro_idle.png")
const WALK = preload("res://assets/characters/miro_walk.png")
const JUMP = preload("res://assets/characters/miro_jump.png")
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("player")
	movement_speed = 115.0

func _physics_process(delta: float) -> void:
	if not is_instance_valid(level):
		return
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	dodge_left = maxf(0.0, dodge_left - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	if level.controls_locked() or is_dead:
		velocity = Vector2.ZERO
		update_visual(delta)
		return
	if in_hiding_spot:
		velocity = Vector2.ZERO
		update_visual(delta)
		return
	stealth_cooldown_left = maxf(0, stealth_cooldown_left - delta)
	if is_concealed:
		stealth_remaining = maxf(0, stealth_remaining - delta)
		if stealth_remaining == 0:
			end_stealth()
	var direction := Input.get_axis("move_left", "move_right")
	var vertical := Input.get_axis("climb_up", "climb_down")
	var ladder = level.ladder_at(global_position)
	if ladder == null:
		climbing = false
	elif vertical != 0.0:
		climbing = true
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or climbing:
			velocity.y = -290.0
			climbing = false
	if direction != 0.0:
		facing = direction
	if Input.is_action_just_pressed("dodge") and dodge_cooldown <= 0.0:
		dodge_left = 0.22
		dodge_cooldown = 0.85
		end_stealth()
	var speed_multiplier := stealth_speed_multiplier if is_concealed else 1.0
	velocity.x = direction * movement_speed * speed_multiplier
	if dodge_left > 0.0:
		velocity.x = facing * 245.0
	if climbing:
		velocity.y = vertical * 85.0 * speed_multiplier
		if direction == 0.0:
			global_position.x = move_toward(global_position.x, ladder.global_position.x, delta * 120.0)
	else:
		velocity.y += 850.0 * delta
	var was_grounded := is_on_floor()
	var fall_speed := velocity.y
	move_and_slide()
	if not was_grounded and is_on_floor() and fall_speed > 100:
		level.emit_effect("dust", global_position + Vector2(0, 14))
	footstep_left = maxf(0, footstep_left - delta)
	if is_on_floor() and absf(velocity.x) > 20 and footstep_left <= 0:
		get_node("/root/SoundFX").play_sound("step", -25 if is_concealed else -19)
		footstep_left = 0.5 if is_concealed else 0.32
	if Input.is_action_just_pressed("cloak"):
		toggle_stealth()
	check_guard_contact()
	if Input.is_action_just_pressed("attack"):
		shank()
	if Input.is_action_just_pressed("explosive"):
		level.plant_c4()
	if Input.is_action_just_pressed("fire"):
		fire_gun()
	if global_position.y > 800:
		die()
	update_visual(delta)

func toggle_stealth() -> void:
	if level.controls_locked() or is_dead:
		return
	if not has_supplies:
		level.notify("Your blanket is on the bed. Search it with E.")
	elif is_concealed:
		end_stealth()
	elif stealth_cooldown_left > 0:
		level.notify("Stealth recharging: %.1fs" % stealth_cooldown_left)
	else:
		is_concealed = true
		stealth_remaining = stealth_duration
		check_guard_contact()

func end_stealth() -> void:
	if not is_concealed:
		return
	is_concealed = false
	stealth_remaining = 0
	stealth_cooldown_left = stealth_cooldown

func check_guard_contact() -> void:
	if not is_concealed:
		return
	var bounds := Rect2(global_position + Vector2(-7, -9), Vector2(14, 24))
	for guard in level.guards():
		if not guard.is_dead and bounds.intersects(Rect2(guard.global_position + Vector2(-7, -9), Vector2(14, 24))):
			end_stealth()
			guard.alert_state = IntroGuard.State.ALERT
			guard.suspicion = 1.0
			guard.sees_player = true
			guard.last_known_position = global_position
			level.notify("Cover blown — you touched a Keeper!")
			return

func stealth_status() -> String:
	if is_concealed:
		return "STEALTH %.1fs" % stealth_remaining
	if stealth_cooldown_left > 0:
		return "STEALTH %.1fs cooldown" % stealth_cooldown_left
	return "STEALTH READY [2]"

func shank() -> void:
	if in_hiding_spot or level.controls_locked() or is_dead:
		return
	if not has_supplies:
		level.notify("Search beneath the bed first. [E]")
		return
	if attack_cooldown > 0.0:
		return
	end_stealth()
	attack_cooldown = 0.5
	attack_flash = 0.16
	get_node("/root/SoundFX").play_sound("swing", -18)
	for guard in level.guards():
		var difference: Vector2 = guard.global_position - global_position
		if not guard.is_dead and absf(difference.y) < 24 and absf(difference.x) <= 46 and difference.x * facing >= -5:
			if level.can_melee_reach(global_position, guard.global_position):
				guard.receive_shank()
				break

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(level) or level.controls_locked() or is_dead or in_hiding_spot:
		return
	if event is InputEventMouseMotion:
		mouse_aim = true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		mouse_aim = true
		fire_gun()
		get_viewport().set_input_as_handled()

func fire_gun() -> void:
	if in_hiding_spot or level.controls_locked() or is_dead:
		return
	if not has_gun or ammunition <= 0:
		level.notify("No loaded weapon. A fallen Keeper may carry one.")
		return
	if attack_cooldown > 0:
		return
	ammunition -= 1
	attack_cooldown = 0.65
	attack_flash = 0.2
	var suppressed := suppressor_uses > 0
	if suppressed:
		suppressor_uses -= 1
	get_node("/root/SoundFX").play_sound("shot", -32 if suppressed else -20)
	end_stealth()
	if not suppressed:
		level.make_noise(global_position, 600.0)
	aim_direction = (get_global_mouse_position() - global_position).normalized() if mouse_aim else Vector2(facing, 0)
	if aim_direction.length_squared() < 0.1:
		aim_direction = Vector2(facing, 0)
	if absf(aim_direction.x) > 0.01:
		facing = signf(aim_direction.x)
	var bullet := Node2D.new()
	bullet.set_script(load("res://scripts/weapon_projectile.gd"))
	bullet.level = level
	bullet.shooter = self
	bullet.direction = aim_direction
	# Start at the body so a muzzle offset cannot spawn beyond a nearby wall.
	bullet.position = position + Vector2(0, -4)
	level.add_child(bullet)
	level.emit_effect("hit", global_position + aim_direction * 12)
	var casing := Node2D.new()
	casing.set_script(load("res://scripts/weapon_casing.gd"))
	casing.level = level
	casing.position = position + Vector2(0, -6)
	casing.velocity = Vector2(-facing * 65, -100)
	level.add_child(casing)

func take_damage(amount: int) -> void:
	if dodge_left > 0:
		return
	var previous_health := health
	super.take_damage(amount)
	if health < previous_health:
		in_hiding_spot = false
		get_node("/root/SoundFX").play_sound("hit", -16)
		level.emit_effect("hit", global_position)
	end_stealth()

func die() -> void:
	if is_dead:
		return
	super.die()
	level.notify("The tower keeps its prisoners. Press R to retry.", 20.0)

func update_visual(delta: float) -> void:
	if has_gun and mouse_aim and not level.controls_locked():
		aim_direction = (get_global_mouse_position() - global_position).normalized()
	animation_time += delta
	sprite.hframes = 1
	sprite.texture = IDLE
	if dodge_left > 0 or (not is_on_floor() and not climbing):
		sprite.texture = JUMP
	elif absf(velocity.x) > 1:
		sprite.texture = WALK
		sprite.hframes = 2
		sprite.frame = int(animation_time * 8) % 2
	sprite.flip_h = facing < 0
	sprite.modulate = Color("8b6d9c") if is_concealed else Color.WHITE
	sprite.modulate.a = 0.15 if in_hiding_spot else (0.42 if is_concealed else (0.5 if invulnerability_left > 0 and int(animation_time * 20) % 2 == 0 else 1.0))
	sprite.rotation = PI / 2 if is_dead else 0.0
	queue_redraw()

func _draw() -> void:
	if has_gun and not is_dead and not in_hiding_spot:
		var direction := aim_direction if mouse_aim else Vector2(facing, 0)
		draw_set_transform(Vector2(0, -4), direction.angle(), Vector2(1, -1 if direction.x < 0 else 1))
		draw_texture_rect(preload("res://assets/weapons/pistol.svg"), Rect2(0, -10, 24, 24), false)
		draw_set_transform(Vector2.ZERO)
	if attack_flash > 0:
		draw_line(Vector2(facing * 9, -2), Vector2(facing * 35, -7), Color("fbf5ef"), 2)
	if is_concealed:
		draw_arc(Vector2(0, -20), 5, 0, PI, 8, Color("c69fa5"), 1)
