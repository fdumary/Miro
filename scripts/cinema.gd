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
	for ring in range(10):
		var inset := ring * 9.0
		var alpha := strength * pow(1.0 - ring / 10.0, 2.2) * 0.22
		var rect := Rect2(Vector2(inset, inset * 0.6), FRAME - Vector2(inset * 2, inset * 1.2))
		canvas.draw_rect(rect, Color(0, 0, 0, alpha), false, 10.0)

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
static func title(canvas: CanvasItem, center: Vector2, text: String, size: int, color: Color, spacing := 4.0) -> void:
	var font := ThemeDB.fallback_font
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
	canvas.draw_multiline_string(ThemeDB.fallback_font, Vector2(60, 334), text, HORIZONTAL_ALIGNMENT_CENTER, 520, 12, 2, Color(PAPER.r, PAPER.g, PAPER.b, alpha))

## The tower's emblem: a circle around a rising triangle (also the sigil Miro leaves).
static func emblem(canvas: CanvasItem, center: Vector2, radius: float, color: Color, width := 2.0) -> void:
	canvas.draw_arc(center, radius, 0, TAU, 32, color, width)
	var r := radius * 0.8
	canvas.draw_polyline(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r * 0.87, r * 0.5), center + Vector2(-r * 0.87, r * 0.5), center + Vector2(0, -r)]), color, width)
	canvas.draw_line(center + Vector2(0, -r * 1.25), center + Vector2(0, r * 1.15), color, width)

## Night sky gradient with a moon and fixed stars.
static func night_sky(canvas: CanvasItem, top: Color, bottom: Color, moon := Vector2(470, 70)) -> void:
	for band in range(18):
		var t := band / 17.0
		canvas.draw_rect(Rect2(0, band * 20, 640, 21), top.lerp(bottom, t))
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
