@tool
extends Node2D
## Background-only library dressing. No collision or interaction shapes.
const ART = preload("res://scripts/visual_assets.gd")
var chapter := 1

func _ready() -> void:
	var level := get_parent().get_parent()
	chapter = str(level.get_meta("blueprint", "level_01")).get_file().get_basename().trim_prefix("level_").to_int()
	var palette := ShaderMaterial.new()
	palette.shader = preload("res://scripts/library_palette.gdshader")
	material = palette
	queue_redraw()

func stamp(id: String, point: Vector2, dimensions := Vector2(32, 32)) -> void:
	draw_texture_rect(ART.texture(id), Rect2(point, dimensions), false)

func _draw() -> void:
	# Authored layouts (Levels 2-4) are dressed by scaffold_art.gd across the whole world.
	var path := str(get_parent().get_parent().get_meta("blueprint", ""))
	if chapter in [2, 3, 4] and FileAccess.file_exists(path) and FileAccess.get_file_as_string(path).contains("\"tiles\""):
		return
	# Chains remain above the movement lanes; Julia's masonry and platforms stay visible.
	for x in [110, 1010]:
		stamp("chain_top", Vector2(x, 38))
		for y in [70, 102, 134]:
			stamp("chain", Vector2(x, y))
		stamp("chain_end", Vector2(x, 166))
	for point in [Vector2(190, 315), Vector2(1030, 535)]:
		stamp("bars", point, Vector2(40, 40))
	if chapter in [3, 4]:
		for x in [68, 1050]:
			for y in range(82, 228, 28):
				stamp("pipe", Vector2(x, y), Vector2(28, 28))
			stamp("pipe_corner", Vector2(x, 54), Vector2(28, 28))
		for point in [Vector2(350, 100), Vector2(900, 310), Vector2(510, 540)]:
			stamp("vent", point, Vector2(32, 48))
			stamp("hazard", point + Vector2(38, 10), Vector2(24, 24))
		stamp("control", Vector2(740, 115), Vector2(32, 48))
		stamp("warning", Vector2(780, 135))
		stamp("beacon_blue" if chapter == 4 else "beacon", Vector2(830, 140))
	if chapter == 4:
		for point in [Vector2(820, 398), Vector2(846, 398)]:
			stamp("flask", point, Vector2(20, 20))
		stamp("cabinet", Vector2(935, 396), Vector2(28, 48))
		stamp("medical_case", Vector2(950, 600), Vector2(32, 24))
		stamp("record", Vector2(270, 170), Vector2(20, 28))
