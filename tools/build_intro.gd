extends SceneTree
## Run explicitly to regenerate the initial layout. The saved scene is editor-editable.
var level: Node2D
var areas: Node2D
var guards_node: Node2D
var blueprint_path := "res://data/levels/level_01.json"
var output_path := "res://scenes/intro.tscn"
var controller_path := "res://scripts/intro_level.gd"
var art_path := "res://scripts/prison_art.gd"
var build_and_quit := true

func _initialize() -> void:
	call_deferred("build")

func attach(node: Node, parent: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = level
	return node

func solid(node_name: String, position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = position
	attach(body, level, node_name)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	attach(shape, body, "CollisionShape2D")

func area(node_name: String, kind: String, position: Vector2, size: Vector2) -> void:
	var templates := {"cover": "cover_zone", "ladder": "ladder", "sigil": "sigil_anchor", "exit": "level_exit", "bed": "prison_bed", "door": "cell_lock", "brother": "voice_gate", "note": "story_note"}
	var node: Area2D
	if templates.has(kind):
		node = load("res://scenes/%s.tscn" % templates[kind]).instantiate()
	else:
		node = Area2D.new()
		node.set_script(load("res://scripts/intro_area.gd"))
		var collision := CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		node.add_child(collision)
	node.kind = kind
	node.area_size = size
	node.position = position
	node.collision_layer = 0
	node.collision_mask = 2
	attach(node, areas, node_name)
	var rect := RectangleShape2D.new()
	rect.size = size
	node.get_node("CollisionShape2D").shape = rect
	if not templates.has(kind):
		node.get_node("CollisionShape2D").owner = level

func guard(node_name: String, position: Vector2, left: float, right: float, sick: bool = false) -> void:
	var node = load("res://scenes/guard.tscn").instantiate()
	node.position = position
	node.patrol_left = left
	node.patrol_right = right
	node.sick_guard = sick
	attach(node, guards_node, node_name)

func build() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(blueprint_path))
	if not parsed is Dictionary:
		push_error("Invalid Level 1 blueprint: " + blueprint_path)
		quit(1)
		return
	var blueprint: Dictionary = parsed
	level = Node2D.new()
	level.name = str(blueprint.title).replace(" ", "")
	level.set_meta("blueprint", blueprint_path)
	level.set_meta("chapter", blueprint.title)
	level.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	level.set_script(load(controller_path))
	var art := Node2D.new()
	art.set_script(load(art_path))
	attach(art, level, "Architecture")
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(int(blueprint.tile_size[0]), int(blueprint.tile_size[1]))
	tileset.add_physics_layer()
	tileset.set_physics_layer_collision_layer(0, 1)
	tileset.set_physics_layer_collision_mask(0, 6)
	var files := ["standard_tile", "cracked_tile", "connector"]
	for i in range(3):
		var atlas := TileSetAtlasSource.new()
		atlas.texture = load("res://assets/environment/%s.png" % files[i])
		atlas.texture_region_size = Vector2i(28, 27)
		atlas.create_tile(Vector2i.ZERO)
		tileset.add_source(atlas, i)
		var data := atlas.get_tile_data(Vector2i.ZERO, 0)
		data.set_collision_polygons_count(0, 1)
		data.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-14, -14), Vector2(14, -14), Vector2(14, 14), Vector2(-14, 14)]))
	ResourceSaver.save(tileset, "res://assets/environment/prison_tiles.tres")
	tileset.take_over_path("res://assets/environment/prison_tiles.tres")
	var floor := TileMapLayer.new()
	floor.tile_set = tileset
	attach(floor, level, "StoneFloors")
	for band in blueprint.floor_rows:
		for x in range(int(band.first_column), int(band.last_column) + 1):
			if float(x) in band.gaps:
				continue
			var source := 0
			if int(band.crack_every) > 0 and x % int(band.crack_every) == 0:
				source = 1
			elif int(band.connector_every) > 0 and x % int(band.connector_every) == 0:
				source = 2
			floor.set_cell(Vector2i(x, int(band.row)), source, Vector2i.ZERO)
	for cell in blueprint.shelves:
		floor.set_cell(Vector2i(int(cell[0]), int(cell[1])), 1 if int(cell[0]) % 3 == 0 else 0, Vector2i.ZERO)
	# Authored layouts (tools/level_layouts.py) list every tile: [column, row, source].
	for cell in blueprint.get("tiles", []):
		floor.set_cell(Vector2i(int(cell[0]), int(cell[1])), int(cell[2]), Vector2i.ZERO)
	for wall in blueprint.solids:
		solid(wall.name, point(wall.position), point(wall.size))
	areas = Node2D.new()
	attach(areas, level, "Interactables")
	for item in blueprint.interactables:
		area(item.name, item.kind, point(item.position), point(item.size))
	var gates := Node2D.new()
	attach(gates, level, "Gates")
	for item in blueprint.get("gates", []):
		var gate = load("res://scenes/progress_gate.tscn").instantiate()
		gate.position = point(item.position)
		gate.gate_size = point(item.size)
		gate.unlock_milestone = item.unlock_milestone
		attach(gate, gates, item.name)
	var props := Node2D.new()
	attach(props, level, "StoryProps")
	for item in blueprint.get("props", []):
		var prop = load("res://scenes/story_prop.tscn").instantiate()
		prop.position = point(item.position)
		prop.kind = item.kind
		attach(prop, props, item.name)
	if blueprint.has("stations"):
		for station in blueprint.stations:
			var label := Label.new()
			label.text = station.title
			label.position = point(station.position) + Vector2(-50, -65)
			label.size = Vector2(100, 32)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 9)
			label.add_theme_color_override("font_color", Color("c69fa5"))
			attach(label, level, "Label_" + station.id)
	guards_node = Node2D.new()
	attach(guards_node, level, "Guards")
	for keeper in blueprint.guards:
		guard(keeper.name, point(keeper.position), keeper.patrol_left, keeper.patrol_right, keeper.sick)
	var markers := Node2D.new()
	attach(markers, level, "LevelPlan")
	var spawn := Marker2D.new()
	spawn.position = point(blueprint.spawn)
	attach(spawn, markers, "PlayerSpawn")
	for beat in blueprint.beats:
		var marker := Marker2D.new()
		marker.position = point(beat.position)
		marker.set_meta("purpose", beat.purpose)
		attach(marker, markers, beat.name)
	var player = load("res://scenes/intro_player.tscn").instantiate()
	player.position = point(blueprint.spawn)
	player.get_node("Camera2D").limit_right = int(blueprint.world_size[0])
	player.get_node("Camera2D").limit_bottom = int(blueprint.world_size[1])
	attach(player, level, "Player")
	var packed := PackedScene.new()
	var result := packed.pack(level)
	if result != OK:
		push_error("Could not pack level: %s" % result)
		quit(1)
		return
	result = ResourceSaver.save(packed, output_path)
	level.free()
	print("BUILD_RESULT ", output_path, " = ", result)
	if build_and_quit:
		quit(0 if result == OK else 1)

func point(values: Array) -> Vector2:
	return Vector2(float(values[0]), float(values[1]))
