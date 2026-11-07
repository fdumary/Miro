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
