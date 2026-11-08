extends Control
## Animated start screen behind the menu (node "Backdrop" in main_menu).
## Before the game is finished: the tower at dusk in the rain, its banner rippling in the wind,
## birds, drifting cloud, swaying grass and pines, lightning with matching thunder. After the game is finished
## (Campaign.game_completed()): the same view in daylight, the tower a broken, smoking stump.
## Draws the gothic title at the top centre; the menu sits below y = 100.
const C = preload("res://scripts/cinema.gd")
const TOWER_BASE := Vector2(470, 262)
var time := 0.0
var frame_count := 0
var completed := false
var draws_title := true
var audio: Node
## Lightning strikes every LIGHTNING_PERIOD seconds at LIGHTNING_AT into the cycle; the
## thunder clap is fired from _process on the same clock, so sound and flash stay in sync.
const LIGHTNING_PERIOD := 11.0
const LIGHTNING_AT := 9.0
var last_strike := -1

func _init() -> void:
	name = "Backdrop"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var campaign = get_node_or_null("/root/Campaign")
	completed = campaign != null and campaign.game_completed()
	audio = preload("res://scripts/cine_audio.gd").new()
	add_child(audio)
	audio.loop("wind_loop", -24.0, 3.0)
	if not completed:
		audio.loop("rain_loop", -34.0, 2.0)
	if completed:
		audio.at(4.0, func(): audio.play("gulls", -26.0))

func _process(delta: float) -> void:
	time += delta
	audio.tick(time)
	if not completed:
		var strike := int(floor((time - LIGHTNING_AT) / LIGHTNING_PERIOD))
		if strike >= 0 and strike != last_strike:
			last_strike = strike
			# Alternate a close crack and a rolling one so the loop doesn't feel canned.
			audio.play("thunder_near" if strike % 2 == 0 else "thunder_far", -25.0 if strike % 2 == 0 else -28.0, 0.95 + 0.05 * (strike % 3))
	queue_redraw()

func _draw() -> void:
	frame_count += 1
	var unit := size / C.FRAME
	draw_set_transform(Vector2.ZERO, 0, unit)
	if completed:
		draw_day()
	else:
		draw_dusk()
	C.vignette(self, 0.7)
	C.grain(self, frame_count / 3, 0.03)
	if draws_title:
		var shadow := Color(0, 0, 0, 0.5)
		C.title(self, Vector2(321, 62), "Miro", 54, shadow, 4)
		C.title(self, Vector2(320, 60), "Miro", 54, C.PAPER if not completed else Color("fff6e6"), 4)
		C.title(self, Vector2(320, 84), "Last Man Standing", 18, C.SAND if not completed else Color("ffe2b8"), 3)

## Wind strength 0.6..1.0, gusting.
func wind() -> float:
	return 0.8 + 0.2 * sin(time * 0.7) * sin(time * 1.9 + 1.0)

func draw_dusk() -> void:
	var flash := 0.0
	var cycle := fmod(time, LIGHTNING_PERIOD)
	if cycle > LIGHTNING_AT and cycle < LIGHTNING_AT + 0.35:
		var since := cycle - LIGHTNING_AT
		flash = (1.0 - since / 0.35) * (1.0 if since < 0.06 or since > 0.12 else 0.5)
	C.night_sky(self, Color("141428").lerp(Color("3a4270"), flash * 0.5), Color("6b3f5c").lerp(Color("9b7aa0"), flash * 0.4), Vector2(150, 70))
	# A low warm band where the sun went down.
	for i in range(6):
		draw_rect(Rect2(0, 200 + i * 8, 640, 9), Color(0.95, 0.55, 0.4, 0.07 * (6 - i)))
	C.storm_clouds(self, time * 0.6, flash * 0.5, 90)
	if flash > 0.3:
		C.bolt(self, Vector2(600, -10), Vector2(570, 180), 23, flash, 1.2)
	C.birds(self, time, Rect2(-20, 110, 680, 60), 7, Color("1b1b30"), 3.5)
	C.pines(self, 252, 70, 46, 0.15, -time * 2.0)
	C.tower(self, TOWER_BASE, 26, 64, time, 0, 0, 0.9)
	var top := Vector2(TOWER_BASE.x, TOWER_BASE.y - 26 * 5.5 - 10)
	# Flag time runs at about 40% speed: a slow, heavy ripple instead of a fast flutter.
	C.flag(self, top + Vector2(18, -28), 38, Vector2(34, 15), time * 0.4, Color("7a2e3a"), wind())
	sway_pines(292, 60, 50, 0.6, 2.0)
	ground(Color("0d1118"), Color("2a3324"))
	sway_pines(345, 230, 130, 1.0, 3.5)
	leaves(Color(0.35, 0.3, 0.4, 0.8))
	# Rain over everything, a little brighter while the lightning lights it up.
	C.rain(self, time, 0.22 + 0.25 * flash)

func draw_day() -> void:
	C.day_sky(self, Color("5c93d1"), Color("cfe4f0"), Vector2(150, 70), time, Color("fff6d8"))
	C.birds(self, time, Rect2(-20, 100, 680, 70), 8, Color("3a3550"), 3.5)
	C.pines(self, 252, 70, 46, 0.0, -time * 2.0)
	C.ruins(self, TOWER_BASE, 32, 80, time)
	sway_pines(292, 60, 50, 0.35, 2.0)
	ground(Color("3f5a3a"), Color("7fa065"))
	sway_pines(345, 230, 130, 0.75, 3.5)
	leaves(Color(0.55, 0.7, 0.4, 0.8))

## Pines that lean with the wind: tips move, bases stay put.
func sway_pines(baseline: float, height: float, spacing: float, depth: float, phase_speed: float) -> void:
	var color := Color("3b4a63").lerp(Color("0d1118"), depth)
	if completed:
		color = Color("4f6b55").lerp(Color("1f2e24"), depth)
	var x := -spacing * 0.5
	var index := 0
	while x < 640 + spacing:
		var h := height * (0.75 + 0.25 * float((index * 37) % 5) / 4.0)
		var lean := sin(time * phase_speed * 0.5 + index * 0.9) * h * 0.03 * wind() + h * 0.02
		# Leave the tower in the clear.
		if height > 100 and absf(x - TOWER_BASE.x) < 120:
			x += spacing
			index += 1
			continue
		draw_colored_polygon(PackedVector2Array([Vector2(x - spacing * 0.45, baseline), Vector2(x + spacing * 0.45, baseline), Vector2(x + lean, baseline - h)]), color)
		x += spacing
		index += 1
	draw_rect(Rect2(0, baseline, 640, 360 - baseline), color)

func ground(base: Color, grass: Color) -> void:
	draw_rect(Rect2(0, 330, 640, 30), base)
	for i in range(120):
		var x := C.hash01(i, 201) * 640.0
		var h := 4.0 + C.hash01(i, 202) * 8.0
		var bend := (sin(time * 2.4 + x * 0.03) * 0.5 + 0.8) * wind() * h * 0.6
		draw_line(Vector2(x, 332), Vector2(x + bend, 332 - h), grass, 1.0)

## Leaves blown across the screen.
func leaves(color: Color) -> void:
	for i in range(12):
		var life := fmod(time * (0.12 + C.hash01(i, 211) * 0.1) + C.hash01(i, 212), 1.0)
		var x := -20.0 + life * 680.0
		var y := 150.0 + C.hash01(i, 213) * 180.0 + sin(life * 12.0 + i) * 12.0
		var spin := time * 4.0 + i
		draw_set_transform(Vector2(x, y) * (size / C.FRAME), spin, size / C.FRAME)
		draw_rect(Rect2(-1.5, -0.8, 3, 1.6), color)
	draw_set_transform(Vector2.ZERO, 0, size / C.FRAME)
