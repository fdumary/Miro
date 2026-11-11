extends "res://tools/test_intro.gd"
func run() -> void:
	await fresh()
	level.finish_dialogue()
	for guard in level.guards():
		guard.set_physics_process(false)
		guard.position = Vector2(-500, -500)
	var player = level.player
	player.has_supplies = true
	player.position = Vector2(350, 236)
	player.pad_crouch = true
	await frames(5)
	player.set_physics_process(false)
	player.invulnerability_left = 0
	player.health = 20
	var shooter = level.guards()[0]
	shooter.position = Vector2(390, 236)
	shooter.shot_direction = Vector2.LEFT
	shooter.shoot_weapon()
	await frames(60)
	check(player.crouching, "Fixture uses the actual crouched hitbox")
	check(player.health < 20, "A visible crouched Miro can be hit by a guard shot")
	var script = load("res://scripts/weapon_projectile.gd")
	for crouched in [false, true]:
		player.pad_crouch = crouched
		player.update_crouch()
		await frames(2)
		var damages: Array = []
		for y in ([-7, 4, 12] if crouched else [-20, 0, 12]):
			player.health = 100
			player.invulnerability_left = 0
			var point: Vector2 = player.global_position + Vector2(0, y)
			await fire_at(point, shooter, true)
			damages.append(100 - player.health)
		check(damages[0] > damages[1] and damages[1] > damages[2] and damages[2] > 0, "Miro head/body/leg damage is ordered while " + ("crouching" if crouched else "standing") + ": " + str(damages))
	var guard = level.guards()[1]
	guard.position = Vector2(350, 236)
	player.position = Vector2(300, 236)
	var guard_damage: Array = []
	for y in [-23, 0, 12]:
		guard.health = 200
		guard.invulnerability_left = 0
		await fire_at(guard.global_position + Vector2(0, y), player, false)
		guard_damage.append(200 - guard.health)
	check(guard_damage[0] > guard_damage[1] and guard_damage[1] > guard_damage[2] and guard_damage[2] > 0, "Guard head/body/leg damage is ordered: " + str(guard_damage))
	guard.position = Vector2(-500, -500)
	var boss = load("res://scenes/brother_boss.tscn").instantiate()
	boss.level = level
	boss.position = Vector2(350, 236)
	boss.engagement = 4
	level.get_node("Guards").add_child(boss)
	boss.set_physics_process(false)
	var boss_damage: Array = []
	for y in [-23, 0, 12]:
		boss.health = 12
		boss.invulnerability_left = 0
		boss.begin_recovery()
		await fire_at(boss.global_position + Vector2(0, y), player, false)
		boss_damage.append(12 - boss.health)
	check(boss_damage[0] > boss_damage[1] and boss_damage[1] > boss_damage[2] and boss_damage[2] > 0, "Niro head/body/leg damage is ordered: " + str(boss_damage))
	boss.health = 12
	boss.is_vulnerable = false
	boss.current_phase = boss.Phase.TELEGRAPH
	boss.invulnerability_left = 0
	await fire_at(boss.global_position + Vector2(0, -23), player, false)
	check(boss.health == 12, "Headshots do not bypass Niro's guarded phase")
	boss.engagement = 1
	boss.health = 10
	boss.invulnerability_left = 0
	boss.begin_recovery()
	await fire_at(boss.global_position + Vector2(0, -23), player, false)
	check(boss.health == 9 and boss.current_phase == boss.Phase.RETREAT, "Extra headshot damage stops at Niro's authored retreat threshold")
	boss.queue_free()
	player.position = Vector2(280, 236)
	player.health = 100
	player.invulnerability_left = 0
	var bullet := Node2D.new()
	bullet.set_script(script)
	bullet.level = level
	bullet.shooter = shooter
	bullet.enemy = true
	bullet.position = Vector2(220, 232)
	bullet.direction = Vector2.RIGHT
	bullet.remaining = 100
	level.add_child(bullet)
	await frames(18)
	check(player.health == 100, "A wall still blocks shots at crouched Miro")
	print("COMBAT_ZONES_RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)

func fire_at(point: Vector2, source: CollisionObject2D, enemy_shot: bool) -> void:
	var bullet := Node2D.new()
	bullet.set_script(load("res://scripts/weapon_projectile.gd"))
	bullet.level = level
	bullet.shooter = source
	bullet.enemy = enemy_shot
	bullet.damage = 4
	bullet.position = point - Vector2(60, 0)
	bullet.direction = Vector2.RIGHT
	bullet.remaining = 100
	level.add_child(bullet)
	await frames(18)
