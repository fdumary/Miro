extends RefCounted
## Shared look for every cutscene: letterbox bars, vignette, film grain, title cards and easing.
## All drawing is in a 640x360 frame; callers set draw_set_transform to scale it to the screen.
## Grain is deterministic (hashed from the frame number), so cutscenes look the same every run.
const FRAME := Vector2(640, 360)
const INK := Color("1b1b30")
const PAPER := Color("fbf5ef")
const ROSE := Color("c69fa5")
const SAND := Color("f2d3ab")
const PLUM := Color("8b6d9c")
const Type = preload("res://scripts/typeface.gd")
const EMBER := Color("ff9a3c")
const FLAME := Color("ffd27a")

static func ease_out(t: float) -> float:
	t = clampf(t, 0, 1)
	return 1.0 - pow(1.0 - t, 3)

static func ease_in_out(t: float) -> float:
	t = clampf(t, 0, 1)
	return t * t * (3.0 - 2.0 * t)

## 0..1 over [start, start + length].
static func phase(time: float, start: float, length: float) -> float:
	return clampf((time - start) / maxf(0.001, length), 0, 1)

## Bars slide in over `amount` 0..1 to a 2.35:1 frame.
static func letterbox(canvas: CanvasItem, amount: float) -> void:
	var bar := 44.0 * ease_out(amount)
	canvas.draw_rect(Rect2(0, 0, FRAME.x, bar), Color.BLACK)
	canvas.draw_rect(Rect2(0, FRAME.y - bar, FRAME.x, bar), Color.BLACK)

static func vignette(canvas: CanvasItem, strength := 0.55) -> void:
	# Four soft edge quads with per-vertex alpha: smooth, no banding.
	var dark := Color(0, 0, 0, clampf(strength * 0.75, 0, 1))
	var clear := Color(0, 0, 0, 0)
	var inset := Vector2(150, 90)
	var o := [Vector2.ZERO, Vector2(FRAME.x, 0), FRAME, Vector2(0, FRAME.y)]
	var i := [inset, Vector2(FRAME.x - inset.x, inset.y), FRAME - inset, Vector2(inset.x, FRAME.y - inset.y)]
	for side in range(4):
		var next := (side + 1) % 4
		canvas.draw_polygon(PackedVector2Array([o[side], o[next], i[next], i[side]]), PackedColorArray([dark, dark, clear, clear]))

## Smooth vertical gradient over a rect.
static func gradient(canvas: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	canvas.draw_polygon(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]), PackedColorArray([top, top, bottom, bottom]))

static func grain(canvas: CanvasItem, frame: int, amount := 0.05) -> void:
	var state := (frame * 7919) & 0x7fffffff
	for i in range(140):
		state = (state * 1103515245 + 12345) & 0x7fffffff
		var x := float(state % 640)
		state = (state * 1103515245 + 12345) & 0x7fffffff
		var y := float(state % 360)
		var light := (state >> 8) % 2 == 0
		canvas.draw_rect(Rect2(x, y, 1, 1), Color(1, 1, 1, amount) if light else Color(0, 0, 0, amount * 1.5))

static func fade(canvas: CanvasItem, alpha: float, color := Color.BLACK) -> void:
	if alpha > 0.001:
		canvas.draw_rect(Rect2(Vector2.ZERO, FRAME), Color(color.r, color.g, color.b, clampf(alpha, 0, 1)))

## Letter-spaced title text, centred on `center`.
static func title(canvas: CanvasItem, center: Vector2, text: String, size: int, color: Color, spacing := 4.0, gothic := true) -> void:
	var font: Font = Type.title() if gothic else Type.body()
	var width := 0.0
	for character in text:
		width += font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + spacing
	var x := center.x - (width - spacing) / 2
	for character in text:
		canvas.draw_string(font, Vector2(x, center.y), character, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
		x += font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + spacing

## A subtitle line in the lower bar.
static func subtitle(canvas: CanvasItem, text: String, alpha := 1.0) -> void:
	if text.is_empty() or alpha <= 0:
		return
	canvas.draw_multiline_string(Type.body(), Vector2(60, 334), text, HORIZONTAL_ALIGNMENT_CENTER, 520, 13, 2, Color(PAPER.r, PAPER.g, PAPER.b, alpha))

## The tower's emblem: a circle around a rising triangle (also the sigil Miro leaves).
static func emblem(canvas: CanvasItem, center: Vector2, radius: float, color: Color, width := 2.0) -> void:
	canvas.draw_arc(center, radius, 0, TAU, 32, color, width)
	var r := radius * 0.8
	canvas.draw_polyline(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r * 0.87, r * 0.5), center + Vector2(-r * 0.87, r * 0.5), center + Vector2(0, -r)]), color, width)
	canvas.draw_line(center + Vector2(0, -r * 1.25), center + Vector2(0, r * 1.15), color, width)

## Night sky gradient with a moon and fixed stars.
static func night_sky(canvas: CanvasItem, top: Color, bottom: Color, moon := Vector2(470, 70)) -> void:
	gradient(canvas, Rect2(-100, -100, 840, 560), top, bottom)
	for i in range(40):
		var point := Vector2(float((i * 151) % 640), float((i * 97) % 170))
		canvas.draw_rect(Rect2(point, Vector2(1, 1)), Color(1, 1, 1, 0.25 + (i % 3) * 0.15))
	for ring in range(6):
		canvas.draw_circle(moon, 26.0 + ring * 10, Color(0.95, 0.9, 0.85, 0.035))
	canvas.draw_circle(moon, 22, Color("e9dfe6"))
	canvas.draw_circle(moon + Vector2(7, -4), 20, top.lerp(bottom, 0.25))

## A row of pines; `depth` 0 (far, pale) .. 1 (near, black). `shift` is parallax offset.
static func pines(canvas: CanvasItem, baseline: float, height: float, spacing: float, depth: float, shift: float) -> void:
	var color := Color("3b4a63").lerp(Color("0d1118"), depth)
	var x := -spacing + fmod(shift, spacing)
	var index := 0
	while x < 640 + spacing:
		var h := height * (0.75 + 0.25 * float((index * 37) % 5) / 4.0)
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - spacing * 0.45, baseline), Vector2(x + spacing * 0.45, baseline), Vector2(x, baseline - h)]), color)
		x += spacing
		index += 1
	canvas.draw_rect(Rect2(0, baseline, 640, 360 - baseline), color)

## Diagonal rain streaks, deterministic per frame.
static func rain(canvas: CanvasItem, time: float, alpha := 0.25) -> void:
	for i in range(90):
		var x := fmod(float(i * 53) + time * 160.0, 700.0) - 30
		var y := fmod(float(i * 89) + time * 520.0, 400.0) - 20
		canvas.draw_line(Vector2(x, y), Vector2(x - 4, y + 12), Color(0.75, 0.8, 0.95, alpha), 1)

## The tower from outside: five floors stacked on a rock, narrow lit windows, the emblem on top.
## `ignite` (0..5) lights a sigil on that many floors from the bottom; `collapse` 0..1 drops them.
static func tower(canvas: CanvasItem, base: Vector2, floor_height: float, width: float, time: float, ignite := 0.0, collapse := 0.0, lit := 1.0) -> void:
	var stone := Color("2e3150")
	var edge := Color("494d7e")
	canvas.draw_colored_polygon(PackedVector2Array([base + Vector2(-width * 0.8, 0), base + Vector2(width * 0.8, 0), base + Vector2(width * 0.55, -floor_height * 0.5), base + Vector2(-width * 0.55, -floor_height * 0.5)]), Color("20223a"))
	for level in range(5):
		var drop := collapse * collapse * (level * 0.6 + 1.0) * floor_height * 1.6
		var sway := sin(level * 2.3) * collapse * width * 0.35
		var y := base.y - floor_height * 0.5 - (level + 1) * floor_height + drop
		var w := width * (1.0 - level * 0.06)
		var rect := Rect2(base.x - w / 2 + sway, y, w, floor_height - 2)
		if collapse > 0.0 and rect.position.y > base.y:
			continue
		canvas.draw_rect(rect, stone)
		canvas.draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), edge)
		canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), edge)
		for window in range(3):
			var flicker := 0.5 + 0.5 * sin(time * 3.0 + level * 1.7 + window * 2.1)
			var glow := Color(0.95, 0.83, 0.55, (0.35 + 0.35 * flicker) * lit * (1.0 - collapse))
			canvas.draw_rect(Rect2(rect.position.x + w * (0.2 + window * 0.27), rect.position.y + floor_height * 0.3, 4, floor_height * 0.4), glow)
		var burning := clampf(ignite - (4 - level), 0, 1)
		if burning > 0.0 and collapse < 0.95:
			var center := rect.get_center()
			for ring in range(4):
				canvas.draw_circle(center, 6 + ring * 6 * burning, Color(0.95, 0.83, 0.67, 0.08 * burning))
			emblem(canvas, center, 7, Color(SAND.r, SAND.g, SAND.b, burning), 1.5)
	if collapse < 0.2:
		var top := Vector2(base.x, base.y - floor_height * 5.5 - 10)
		canvas.draw_rect(Rect2(top.x - 1, top.y - 16, 2, 16), edge)
		emblem(canvas, top - Vector2(0, 22), 6, Color(ROSE.r, ROSE.g, ROSE.b, 0.8), 1.5)

## Dust plumes rolling out from the base during a collapse.
static func dust(canvas: CanvasItem, base: Vector2, amount: float) -> void:
	if amount <= 0:
		return
	for i in range(14):
		var side := -1.0 if i % 2 == 0 else 1.0
		var reach := amount * (40 + (i * 23) % 90)
		var rise := amount * (10 + (i * 31) % 60)
		canvas.draw_circle(base + Vector2(side * reach, -rise), 10 + amount * (12 + i % 5 * 4), Color(0.7, 0.66, 0.72, 0.12 * (1.2 - amount)))

## Miro in silhouette, facing right; `bow` 0..1 lowers his head.
static func miro(canvas: CanvasItem, feet: Vector2, scale_factor: float, bow := 0.0, color := Color("2a2440"), rim := Color(0.9, 0.85, 0.95, 0.35)) -> void:
	# Moonlight rim on his left edge, so the silhouette reads against dark trees.
	if rim.a > 0:
		miro(canvas, feet + Vector2(-1.5, -1), scale_factor, bow, rim, Color(0, 0, 0, 0))
	var s := scale_factor
	canvas.draw_rect(Rect2(feet + Vector2(-5, -30) * s, Vector2(10, 30) * s), color)
	canvas.draw_colored_polygon(PackedVector2Array([feet + Vector2(-7, -8) * s, feet + Vector2(7, -8) * s, feet + Vector2(5, -26) * s, feet + Vector2(-5, -26) * s]), color)
	var head := feet + Vector2(1 + bow * 3, -37 + bow * 4) * s
	canvas.draw_circle(head, 6.5 * s, color)
	canvas.draw_rect(Rect2(feet + Vector2(4, -22) * s, Vector2(8, 3) * s), color)

# ---------------------------------------------------------------------------------------------
# Weather, fire and the world outside the tower. Everything is deterministic: the same `time`
# always draws the same frame, so stills, skips and tests stay stable.

static var _textures: Dictionary = {}

static func tex(id: String) -> Texture2D:
	if not _textures.has(id):
		_textures[id] = load("res://assets/library/%s.png" % id)
	return _textures[id]

## Cheap deterministic hash in 0..1 for (index, salt).
static func hash01(index: int, salt := 0) -> float:
	var h := (index * 374761393 + salt * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 10000) / 10000.0

## A soft puff using the Kenney smoke sprite, tinted.
static func puff(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.5 or color.a <= 0.003:
		return
	canvas.draw_texture_rect(tex("smoke"), Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2), false, color)

## A forked lightning bolt from `from` to `to`; `alpha` fades it out after the strike.
static func bolt(canvas: CanvasItem, from: Vector2, to: Vector2, seed: int, alpha: float, width := 2.0) -> void:
	if alpha <= 0.01:
		return
	var points := PackedVector2Array([from])
	var steps := 11
	var side := (to - from).orthogonal().normalized()
	for i in range(1, steps):
		var t := float(i) / steps
		points.append(from.lerp(to, t) + side * (hash01(i, seed) - 0.5) * 34.0)
	points.append(to)
	var glow := Color(0.7, 0.75, 1.0, 0.18 * alpha)
	canvas.draw_polyline(points, glow, width * 5)
	canvas.draw_polyline(points, Color(0.85, 0.88, 1.0, 0.6 * alpha), width * 2)
	canvas.draw_polyline(points, Color(1, 1, 1, alpha), width)
	# Two branches peel off the upper half.
	for b in range(2):
		var start := points[3 + b * 3]
		var branch := PackedVector2Array([start])
		var dir := Vector2((hash01(b, seed + 7) - 0.5) * 2.0, 1.0).normalized()
		for j in range(1, 5):
			branch.append(start + dir * j * 14.0 + side * (hash01(j + b * 10, seed + 3) - 0.5) * 12.0)
		canvas.draw_polyline(branch, Color(0.85, 0.88, 1.0, 0.45 * alpha), width * 0.8)

## Heavy rain: two depths of streaks plus splashes on `ground` (skip splashes with ground < 0).
static func storm_rain(canvas: CanvasItem, time: float, alpha := 0.3, ground := -1.0, wind := 4.0) -> void:
	for layer in range(2):
		var speed := 560.0 + layer * 240.0
		var length := 10.0 + layer * 8.0
		var a := alpha * (0.55 + layer * 0.45)
		for i in range(110 - layer * 40):
			var x := fmod(float(i * 53 + layer * 211) + time * wind * 40.0, 700.0) - 30
			var y := fmod(float(i * 89 + layer * 37) + time * speed, 400.0) - 20
			canvas.draw_line(Vector2(x, y), Vector2(x - wind, y + length), Color(0.72, 0.78, 0.95, a), 1.0 + layer * 0.5)
	if ground >= 0:
		for i in range(26):
			var cycle := fmod(time * 3.0 + hash01(i, 5) * 7.0, 1.0)
			var x := hash01(i, 9) * 640.0
			var spread := cycle * 6.0
			canvas.draw_arc(Vector2(x, ground + hash01(i, 2) * 20.0), spread, PI, TAU, 6, Color(0.8, 0.85, 1.0, alpha * (1.0 - cycle)), 1.0)

## A cloud ceiling that rolls by; lit from inside by `flash`.
static func storm_clouds(canvas: CanvasItem, time: float, flash := 0.0, height := 120.0) -> void:
	for i in range(14):
		var x := fmod(hash01(i, 1) * 820.0 + time * (6.0 + hash01(i, 2) * 6.0), 820.0) - 90
		var y := hash01(i, 3) * height * 0.7
		var r := 60.0 + hash01(i, 4) * 70.0
		var base := Color("161a2e").lerp(Color("2b3150"), hash01(i, 5))
		puff(canvas, Vector2(x, y), r, base.lerp(Color(0.8, 0.82, 1.0), flash * 0.6))

## A fireball, shock ring, flying debris with gravity, embers and a smoke column.
## `age` is seconds since detonation; `ground` is the y the debris lands on.
static func explosion(canvas: CanvasItem, origin: Vector2, age: float, scale := 1.0, seed := 0, ground := 300.0) -> void:
	if age < 0:
		return
	# Smoke column: dark puffs rising, drawn first so the fire sits in front.
	for i in range(16):
		var born := hash01(i, seed + 11) * 1.4
		var life := age - born
		if life <= 0:
			continue
		var drift := Vector2((hash01(i, seed + 12) - 0.5) * 60.0 + life * 8.0, -life * (30.0 + hash01(i, seed + 13) * 30.0)) * scale
		var radius := (18.0 + life * 16.0) * scale
		var shade := Color(0.12, 0.1, 0.12, clampf(0.75 - life * 0.09, 0, 0.75))
		puff(canvas, origin + drift, radius, shade)
	# Shock ring and ground dust.
	var ring := clampf(age / 0.7, 0, 1)
	if ring < 1.0:
		canvas.draw_arc(origin, ring * 260.0 * scale, 0, TAU, 48, Color(1, 0.95, 0.85, 0.5 * (1.0 - ring)), maxf(1.0, 6.0 * (1.0 - ring)))
		canvas.draw_arc(origin, ring * 190.0 * scale, 0, TAU, 40, Color(1, 0.8, 0.5, 0.25 * (1.0 - ring)), 2.0)
	var dust_reach := ease_out(age / 2.0) * 220.0 * scale
	for side in [-1.0, 1.0]:
		for k in range(4):
			puff(canvas, Vector2(origin.x + side * dust_reach * (0.4 + k * 0.2), ground - 6.0 * scale), (20.0 + k * 8.0) * scale, Color(0.55, 0.45, 0.45, 0.35 * clampf(1.6 - age * 0.35, 0, 1)))
	# Fireball: puffs flung outward that rise, cool from white to orange to red, then go dark.
	for i in range(22):
		var angle := -PI * (0.05 + 0.9 * hash01(i, seed + 21))
		var speed := (60.0 + hash01(i, seed + 22) * 120.0) * scale
		var t := minf(age, 2.6)
		var travel := speed * (1.0 - exp(-t * 2.2)) / 2.2
		var pos := origin + Vector2(cos(angle), sin(angle)) * travel + Vector2(0, -t * t * 14.0 * scale)
		var heat := clampf(1.0 - age / (1.2 + hash01(i, seed + 23) * 1.4), 0, 1)
		var color := Color(0.25, 0.08, 0.06).lerp(EMBER, clampf(heat * 1.6, 0, 1)).lerp(FLAME, clampf(heat * 1.6 - 0.6, 0, 1)).lerp(Color.WHITE, clampf(heat * 2.0 - 1.6, 0, 1))
		color.a = clampf(heat * 1.3, 0, 0.95)
		puff(canvas, pos, (14.0 + t * 20.0 + hash01(i, seed + 24) * 10.0) * scale, color)
	# The white core of the blast.
	var core := clampf(1.0 - age / 0.5, 0, 1)
	if core > 0:
		canvas.draw_circle(origin, (20.0 + age * 140.0) * scale, Color(1, 0.97, 0.88, 0.85 * core))
		canvas.draw_circle(origin, (12.0 + age * 60.0) * scale, Color(1, 1, 1, core))
	# Debris: chunks of masonry on ballistic arcs that land and stop; some still burning.
	for i in range(30):
		var angle := -PI * (0.08 + 0.84 * hash01(i, seed + 31))
		var speed := (120.0 + hash01(i, seed + 32) * 260.0) * scale
		var velocity := Vector2(cos(angle), sin(angle)) * speed
		var gravity := 320.0 * scale
		var t := age
		var pos := origin + velocity * t + Vector2(0, 0.5 * gravity * t * t)
		var landed := pos.y > ground
		if landed:
			# Solve for the landing time so the chunk rests where it hit.
			var a := 0.5 * gravity
			var b := velocity.y
			var c := origin.y - ground
			var land_t := (-b + sqrt(maxf(0.0, b * b - 4.0 * a * c))) / (2.0 * a)
			pos = origin + velocity * land_t + Vector2(0, 0.5 * gravity * land_t * land_t)
			pos.y = ground - hash01(i, seed + 35) * 3.0
		var size := (2.0 + hash01(i, seed + 33) * 4.5) * scale
		var spin := (hash01(i, seed + 34) - 0.5) * 16.0 * (0.0 if landed else t)
		var corners := PackedVector2Array()
		for k in range(4):
			var r := size * (0.7 + 0.3 * hash01(k + i * 4, seed + 36))
			corners.append(pos + Vector2(cos(spin + k * PI / 2), sin(spin + k * PI / 2)) * r)
		var burning := i % 3 == 0 and age < 3.5
		if burning and not landed:
			var trail := velocity + Vector2(0, gravity * t)
			canvas.draw_line(pos, pos - trail.normalized() * 10.0 * scale, Color(EMBER.r, EMBER.g, EMBER.b, 0.7), 2.0 * scale)
		canvas.draw_colored_polygon(corners, Color("2b2236") if not burning else Color("5a2a22"))
	# Embers riding the heat up.
	for i in range(40):
		var born := hash01(i, seed + 41) * 2.5
		var life := age - born
		if life <= 0 or life > 4.0:
			continue
		var x := origin.x + (hash01(i, seed + 42) - 0.5) * 200.0 * scale + sin(life * 3.0 + i) * 10.0
		var y := origin.y - life * (30.0 + hash01(i, seed + 43) * 40.0) * scale
		var flicker := 0.5 + 0.5 * sin(life * 20.0 + i)
		canvas.draw_rect(Rect2(x, y, 1.5 * scale, 1.5 * scale), Color(FLAME.r, FLAME.g, FLAME.b, (1.0 - life / 4.0) * flicker))

## Flickering flames along a base line; `intensity` 0..1 scales the height.
static func flames(canvas: CanvasItem, base: Vector2, width: float, height: float, time: float, intensity := 1.0, seed := 0) -> void:
	if intensity <= 0.01:
		return
	var tongues := maxi(3, int(width / 9.0))
	for layer in range(3):
		var color: Color = [Color(0.7, 0.15, 0.08, 0.75), EMBER, FLAME][layer]
		var scale_h: float = [1.0, 0.72, 0.42][layer]
		for i in range(tongues):
			var x := base.x - width / 2 + (i + 0.5) * width / tongues
			var flick := 0.65 + 0.35 * sin(time * (9.0 + hash01(i, seed) * 6.0) + i * 1.7) * sin(time * 5.3 + i)
			var h := height * intensity * scale_h * flick * (0.6 + 0.4 * hash01(i, seed + 1))
			var w := width / tongues * (1.25 - layer * 0.25)
			var lean := sin(time * 3.0 + i) * w * 0.4
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - w / 2, base.y), Vector2(x + w / 2, base.y), Vector2(x + lean * 0.5 + w * 0.15, base.y - h * 0.55), Vector2(x + lean, base.y - h), Vector2(x + lean * 0.5 - w * 0.15, base.y - h * 0.55)]), color)

## Warm glow halo, e.g. fire light on the sky.
static func glow(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	for ring in range(6):
		var r := radius * (1.0 - ring / 6.0)
		canvas.draw_circle(center, r, Color(color.r, color.g, color.b, color.a / 6.0))

## Birds flying across `area`; wings flap. `count` birds, wrapping horizontally.
static func birds(canvas: CanvasItem, time: float, area: Rect2, count := 6, color := Color("1b1b30"), size := 4.0) -> void:
	for i in range(count):
		var speed := 18.0 + hash01(i, 61) * 22.0
		var x := area.position.x + fmod(hash01(i, 62) * area.size.x + time * speed, area.size.x + 40.0) - 20.0
		var y := area.position.y + hash01(i, 63) * area.size.y + sin(time * 0.9 + i) * 6.0
		var flap := sin(time * (7.0 + hash01(i, 64) * 3.0) + i * 2.0)
		var s := size * (0.7 + 0.5 * hash01(i, 65))
		var wing := Vector2(s, -flap * s * 0.8)
		canvas.draw_polyline(PackedVector2Array([Vector2(x, y) + Vector2(-wing.x, wing.y), Vector2(x, y + s * 0.2), Vector2(x, y) + wing]), color, 1.2)

## A banner on a pole, rippling in the wind toward +x. `pole_top` is the top of the pole.
static func flag(canvas: CanvasItem, pole_top: Vector2, pole_height: float, cloth: Vector2, time: float, color: Color, wind := 1.0) -> void:
	canvas.draw_line(pole_top, pole_top + Vector2(0, pole_height), Color("494d7e"), 1.5)
	var segments := 10
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	for i in range(segments + 1):
		var u := float(i) / segments
		var wave := sin(time * 7.0 * wind - u * 5.0) * cloth.y * 0.28 * u * wind
		var droop := (1.0 - wind) * u * cloth.y * 0.5
		var x := pole_top.x + u * cloth.x * (0.92 + 0.08 * cos(time * 7.0 - u * 5.0))
		top.append(Vector2(x, pole_top.y + 1 + wave + droop))
		bottom.append(Vector2(x, pole_top.y + 1 + cloth.y + wave * 1.1 + droop))
	for i in range(segments):
		var slope := (top[i + 1].y - top[i].y) / maxf(0.1, top[i + 1].x - top[i].x)
		var shade := color.darkened(clampf(0.25 + slope * 0.4, 0.0, 0.5))
		canvas.draw_colored_polygon(PackedVector2Array([top[i], top[i + 1], bottom[i + 1], bottom[i]]), shade)
	# The tower's emblem stitched on the cloth.
	var middle := (top[segments / 2] + bottom[segments / 2]) / 2
	emblem(canvas, middle, cloth.y * 0.28, Color(SAND.r, SAND.g, SAND.b, 0.8), 1.0)

## Daytime sky with a sun and slow clouds.
static func day_sky(canvas: CanvasItem, top: Color, bottom: Color, sun: Vector2, time := 0.0, sun_color := Color("fff2c8")) -> void:
	gradient(canvas, Rect2(-100, -100, 840, 560), top, bottom)
	glow(canvas, sun, 120, Color(sun_color.r, sun_color.g, sun_color.b, 0.35))
	canvas.draw_circle(sun, 20, sun_color)
	for i in range(7):
		var x := fmod(hash01(i, 71) * 760.0 + time * (4.0 + hash01(i, 72) * 4.0), 760.0) - 60
		var y := 30.0 + hash01(i, 73) * 110.0
		puff(canvas, Vector2(x, y), 30.0 + hash01(i, 74) * 40.0, Color(1, 1, 1, 0.35))

## What is left of the tower after the ending: a broken stump, rubble, thin smoke, first grass.
static func ruins(canvas: CanvasItem, base: Vector2, floor_height: float, width: float, time: float) -> void:
	var stone := Color("4a4c6e")
	var dark := Color("2e3150")
	canvas.draw_colored_polygon(PackedVector2Array([base + Vector2(-width * 0.9, 0), base + Vector2(width * 0.9, 0), base + Vector2(width * 0.55, -floor_height * 0.5), base + Vector2(-width * 0.55, -floor_height * 0.5)]), Color("3a3550"))
	var top := base.y - floor_height * 0.5
	# The stump: one and a half floors with a jagged break line.
	var edge := PackedVector2Array([Vector2(base.x - width / 2, top)])
	for i in range(9):
		var u := float(i) / 8.0
		var height := floor_height * (0.9 + 0.8 * hash01(i, 81)) * (1.0 - absf(u - 0.35) * 0.9)
		edge.append(Vector2(base.x - width / 2 + u * width, top - height))
	edge.append(Vector2(base.x + width / 2, top))
	canvas.draw_colored_polygon(edge, dark)
	canvas.draw_rect(Rect2(base.x - width / 2, top - floor_height * 0.45, width, 2), stone)
	for window in range(3):
		canvas.draw_rect(Rect2(base.x - width / 2 + width * (0.2 + window * 0.27), top - floor_height * 0.4, 4, floor_height * 0.3), Color("1b1b30"))
	# Bent beams sticking out of the break.
	for i in range(3):
		var from := Vector2(base.x - width * 0.3 + i * width * 0.28, top - floor_height * 0.9)
		canvas.draw_line(from, from + Vector2((hash01(i, 82) - 0.5) * 30.0, -12.0 - hash01(i, 83) * 16.0), Color("6b5a73"), 2.0)
	# Rubble heaps.
	for i in range(16):
		var x := base.x + (hash01(i, 84) - 0.5) * width * 2.6
		var s := 4.0 + hash01(i, 85) * 9.0
		canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - s, base.y), Vector2(x + s, base.y), Vector2(x + s * 0.3, base.y - s * 0.9)]), stone.darkened(hash01(i, 86) * 0.4))
	# Thin smoke still curling up, long after.
	for i in range(8):
		var life := fmod(time * 0.25 + i / 8.0, 1.0)
		puff(canvas, Vector2(base.x + sin(life * 4.0 + i) * 10.0 + life * 30.0, top - floor_height - life * 120.0), 8.0 + life * 26.0, Color(0.85, 0.85, 0.9, 0.22 * (1.0 - life)))
	# First grass at the foot.
	for i in range(40):
		var x := base.x + (hash01(i, 87) - 0.5) * width * 3.2
		var sway := sin(time * 2.0 + i) * 1.5
		canvas.draw_line(Vector2(x, base.y), Vector2(x + sway, base.y - 3.0 - hash01(i, 88) * 5.0), Color("6b8f5a"), 1.0)

## Miro sitting on the sand, legs out toward +x, leaning back on his hands, earbuds in.
static func miro_sitting(canvas: CanvasItem, seat: Vector2, s: float, color := Color("2a2440"), breathe := 0.0) -> void:
	var lean := Vector2(-4, 0) * s
	canvas.draw_colored_polygon(PackedVector2Array([seat + Vector2(-5, 0) * s, seat + Vector2(5, 0) * s, seat + Vector2(2, -22 - breathe) * s + lean, seat + Vector2(-7, -21 - breathe) * s + lean]), color)
	var head := seat + Vector2(-2.5, -29 - breathe) * s + lean
	canvas.draw_circle(head, 6.0 * s, color)
	# Legs: one straight, one knee up.
	canvas.draw_line(seat + Vector2(3, -2) * s, seat + Vector2(26, -1) * s, color, 4.5 * s)
	canvas.draw_line(seat + Vector2(3, -3) * s, seat + Vector2(13, -13) * s, color, 4.5 * s)
	canvas.draw_line(seat + Vector2(13, -13) * s, seat + Vector2(20, -1) * s, color, 4.0 * s)
	# Arm propped behind.
	canvas.draw_line(seat + Vector2(-5, -18) * s + lean, seat + Vector2(-13, 0) * s, color, 3.0 * s)
	# The earbud wire down to the MP3 on his lap: just a music player now.
	canvas.draw_line(head + Vector2(3, 2) * s, seat + Vector2(9, -6) * s, Color(SAND.r, SAND.g, SAND.b, 0.7), 1.0)
	canvas.draw_rect(Rect2(seat + Vector2(8, -8) * s, Vector2(3, 4) * s), Color("494d7e"))
