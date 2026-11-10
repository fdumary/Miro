extends SceneTree
const BULLET = preload("res://scripts/weapon_projectile.gd")
const FX = preload("res://scripts/visual_effects.gd")
var failures: Array[String] = []
var checks := 0
class Target extends IntroGuard:
	var hits: Array = []
	func take_damage(amount: int, _ignore := false) -> void: hits.append(amount)
class Fixture extends Node2D:
	var targets: Array[Node] = []
	var impact := Vector2.INF
	func guards() -> Array[Node]: return targets
	func emit_effect(_cue: String, point: Vector2) -> void: impact = point
	func controls_locked() -> bool: return false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("PASS: " if ok else "FAIL: ",message)
func legacy(bullet, fixture, from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1,ceili(from.distance_to(to)/2.0))
	for step in range(steps+1):
		var point := from.lerp(to,float(step)/steps)
		for guard in fixture.guards():
			if not is_instance_valid(guard) or guard.is_dead or guard == bullet.shooter or not guard is IntroGuard: continue
			var local: Vector2 = point-guard.global_position
			var body := Rect2(-10.0-(14.0 if guard.facing < 0 else 0.0),-22.0,34.0,40.0)
			var head := Rect2(-9,-30,18,14)
			if head.has_point(local) or body.has_point(local):
				if head.has_point(local) and not guard.has_method("begin_recovery"): guard.invulnerability_left=0
				guard.take_damage(bullet.guard_damage(guard,point),true)
				fixture.emit_effect("hit",point)
				return true
	return false
func snapshot(fixture) -> Array:
	var result: Array = [fixture.impact]
	for guard in fixture.targets: result.append(guard.hits.duplicate())
	return result
func clear_hits(fixture) -> void:
	fixture.impact=Vector2.INF
	for guard in fixture.targets: guard.hits.clear()
func run() -> void:
	var fixture := Fixture.new()
	root.add_child(fixture)
	var bullet = BULLET.new()
	bullet.level=fixture
	for i in range(12):
		var target := Target.new()
		target.set_physics_process(false)
		fixture.add_child(target)
		fixture.targets.append(target)
	var target = fixture.targets[0]
	target.asleep=true
	check(target.is_in_group("discoverable_guards"),"Sleeping state enters body registry immediately")
	target.asleep=false
	check(not target.is_in_group("discoverable_guards"),"Waking removes body registry entry")
	target.is_dead=true
	check(target.is_in_group("discoverable_guards"),"Direct death assignment registers body immediately")
	target.is_dead=false
	check(not target.is_in_group("discoverable_guards"),"Revival removes stale body entry")
	var random := RandomNumberGenerator.new()
	random.seed=97005070
	var equal := true
	for trial in range(1500):
		for guard in fixture.targets:
			guard.position=Vector2(random.randf_range(-160,160),random.randf_range(-70,70))
			guard.facing=-1 if random.randi()%2 == 0 else 1
			guard.is_dead=random.randi()%7 == 0
		var from := Vector2(random.randf_range(-180,180),random.randf_range(-90,90))
		var to := from+Vector2(random.randf_range(-75,75),random.randf_range(-50,50))
		bullet.shooter=fixture.targets[trial%12]
		clear_hits(fixture)
		var expected := legacy(bullet,fixture,from,to)
		var expected_state := snapshot(fixture)
		clear_hits(fixture)
		var actual: bool=bullet.strike_guard(from,to)
		if expected != actual or expected_state != snapshot(fixture):
			equal=false
			print("DIFFERENCE trial=",trial," from=",from," to=",to)
			break
	check(equal,"1500 seeded swept-shot cases match legacy targets, damage and impact positions")
	var fx = FX.new()
	fx.level=fixture
	fixture.add_child(fx)
	fx.particles.assign([{"position":Vector2.ZERO,"origin_y":2.0,"velocity":Vector2(2,-4),"life":0.01,"duration":1.0,"size":5.0,"id":"dust","color":Color.WHITE},{"position":Vector2.ZERO,"origin_y":2.0,"velocity":Vector2(2,-4),"life":1.0,"duration":1.0,"size":5.0,"id":"dust","color":Color.WHITE}])
	fx._process(0.02)
	check(fx.particles.size()==1 and is_equal_approx(fx.particles[0].life,0.98),"In-place effects compaction removes expired particles and preserves survivors")
	fx.particles.clear()
	fx._process(0.016)
	check(fx.particles.is_empty(),"Empty VFX update remains idle")
	bullet.free()
	fixture.free()
	await process_frame
	print("PERFORMANCE_REGRESSIONS_RESULT: ",checks-failures.size(),"/",checks," passed")
	quit(0 if failures.is_empty() else 1)
