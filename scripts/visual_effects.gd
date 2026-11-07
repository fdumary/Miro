extends Node2D
## Bounded cosmetic effects; no collision, noise events or gameplay RNG changes.
const ART = preload("res://scripts/visual_assets.gd")
var level: Node
var particles: Array[Dictionary] = []
var random := RandomNumberGenerator.new()

func _ready() -> void:
	z_index = 5
	random.randomize()

func emit_burst(cue: String, point: Vector2) -> void:
	var amount := 12 if cue == "breach" else (1 if cue == "blood" else 6)
	for index in range(amount):
		if particles.size() >= 128:
			break
		var id := "smoke" if cue == "breach" else ("splat" if cue == "blood" else ("spark" if cue == "hit" else "dust"))
		var life := 8.0 if cue == "blood" else random.randf_range(0.35, 1.2 if cue == "breach" else 0.65)
		var size := random.randf_range(10, 20) if cue in ["breach", "blood"] else random.randf_range(3, 7)
		particles.append({"position": to_local(point), "origin_y": to_local(point).y,
			"velocity": Vector2.ZERO if cue == "blood" else Vector2(random.randf_range(-38, 38), random.randf_range(-60, -15)),
			"life": life, "duration": life, "size": size, "id": id,
			"color": Color("d32632") if cue == "blood" else Color("f2d3ab")})
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(level) or level.controls_locked():
		return
	for particle in particles:
		particle.life -= delta
		if particle.id != "splat":
			particle.position += particle.velocity * delta
			particle.velocity.y += delta * (12 if particle.id == "smoke" else 90)
			if particle.position.y > particle.origin_y:
				particle.position.y = particle.origin_y
	particles = particles.filter(func(particle): return particle.life > 0)
	queue_redraw()

func _draw() -> void:
	for particle in particles:
		var color: Color = particle.color
		color.a = minf(0.65, particle.life / particle.duration)
		var extent := Vector2(particle.size, particle.size * (0.4 if particle.id == "splat" else 1.0))
		draw_texture_rect(ART.texture(particle.id), Rect2(particle.position - extent / 2, extent), false, color)
