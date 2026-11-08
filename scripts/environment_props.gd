@tool
extends Node2D
## Native-size Julia props, aligned to the actual top of raised floor tiles.
const CRATE = preload("res://assets/environment/crate.png")
const SHROOMS = preload("res://assets/environment/shrooms.png")

func _ready() -> void:
	if has_node("LibraryDressing"):
		return
	var dressing := Node2D.new()
	dressing.name = "LibraryDressing"
	dressing.set_script(preload("res://scripts/level_dressing.gd"))
	add_child(dressing)

## A window sill Miro can stand on: one-way (jump up through it, drop through with down),
## on its own physics layer (6) so Keepers' sight lines and patrols ignore it.
func add_ledge(rect: Rect2) -> void:
	if Engine.is_editor_hint():
		return
	var body := StaticBody2D.new()
	body.name = "Ledge%d" % get_child_count()
	body.collision_layer = 0
	body.set_collision_layer_value(6, true)
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = true
	body.add_child(shape)
	add_child(body)

const TORCH := preload("res://assets/environment/torch_animation.png")
var torch_frame := 0

func draw_torch(rect: Rect2) -> void:
	draw_texture_rect_region(TORCH, rect, Rect2(torch_frame * 32, 0, 32, 32))

func tick_torches() -> void:
	var frame := int(Time.get_ticks_msec() / 450.0) % 2
	if frame != torch_frame:
		torch_frame = frame
		queue_redraw()

func draw_grounded(texture: Texture2D, point: Vector2) -> void:
	var tiles := get_parent().get_node_or_null("StoneFloors") as TileMapLayer
	if tiles:
		for step in range(8):
			var intersects_tile := false
			for offset in [-texture.get_width() / 2.0 + 2, 0.0, texture.get_width() / 2.0 - 2]:
				var cell := tiles.local_to_map(tiles.to_local(to_global(point + Vector2(offset, -1))))
				intersects_tile = intersects_tile or tiles.get_cell_source_id(cell) >= 0
			if not intersects_tile:
				break
			point.y -= tiles.tile_set.tile_size.y
	draw_texture(texture, point - Vector2(texture.get_width() / 2.0, texture.get_height()))
