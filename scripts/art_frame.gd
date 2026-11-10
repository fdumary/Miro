extends Node2D
## A reactive gallery frame (artspec.md §5). The painting is picked once per visit by
## scripts/inner_conflict.gd; until then, or when no cleared image exists, a sheet covers it.
## Position is the standing point in front of the frame; the frame hangs on the wall above.
const INK := Color("272744")
const WOOD := Color("5b3b38")
const GILT := Color("c4a265")
const PALE := Color("c69fa5")
const CANVAS := Vector2(46, 34)
var slot_id := ""
## Catalog entry for the painting on the wall (empty until assigned).
var art: Dictionary = {}
var art_id := ""
var branch := ""
var texture: Texture2D
var thumbnail: Texture2D
var assigned := false
var inspected := false
var time := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)

func _process(delta: float) -> void:
	time += delta
	if inspected or not assigned or thumbnail != null:
		return
	queue_redraw()

## Shows the painting. The in-world copy is downscaled to a few dozen pixels so it sits in the
## pixel-art tower; the full image is shown when Miro looks closer.
func hang(entry: Dictionary, image: Texture2D, chosen_branch: String) -> void:
	art = entry
	art_id = str(entry.get("id", ""))
	branch = chosen_branch
	texture = image
	thumbnail = null
	assigned = true
	var small_path := "res://assets/art/thumbnails/%s.png" % art_id
	if image != null and ResourceLoader.exists(small_path):
		thumbnail = load(small_path)
	else:
		if image != null:
			var picture := image.get_image()
			if picture != null:
				if picture.is_compressed():
					picture.decompress()
				var fit := minf(CANVAS.x / picture.get_width(), CANVAS.y / picture.get_height())
				picture.resize(maxi(4, int(picture.get_width() * fit)), maxi(4, int(picture.get_height() * fit)), Image.INTERPOLATE_LANCZOS)
				thumbnail = ImageTexture.create_from_image(picture)
	set_process(not inspected and thumbnail == null)
	queue_redraw()

func covered() -> bool:
	return thumbnail == null

func canvas_rect() -> Rect2:
	var size := CANVAS if thumbnail == null else thumbnail.get_size()
	return Rect2(Vector2(-size.x / 2, -44 - size.y / 2), size)

func _draw() -> void:
	var canvas := canvas_rect()
	# Low-key light from above, a dark antique frame, a mat, then the work itself.
	for ring in range(4, 0, -1):
		draw_circle(canvas.get_center() + Vector2(0, -6), 18.0 + ring * 7, Color(0.95, 0.83, 0.67, 0.018))
	draw_rect(canvas.grow(6), INK)
	draw_rect(canvas.grow(5), WOOD)
	draw_rect(canvas.grow(5), GILT.darkened(0.35), false, 1)
	draw_rect(canvas.grow(2), Color("e9dcc8").darkened(0.45))
	if thumbnail != null:
		draw_texture_rect(thumbnail, canvas, false)
		# Picture-light glint along the top of the canvas.
		draw_line(canvas.position + Vector2(2, 1), canvas.position + Vector2(canvas.size.x - 2, 1), Color(1, 0.95, 0.85, 0.18), 1)
	else:
		# A dust sheet hangs over the frame: the tower hasn't let Miro see this one yet.
		draw_rect(canvas, Color("3a3557"))
		var sway := sin(time * 1.3) * 1.5
		var sheet := PackedVector2Array([canvas.position + Vector2(-4, -3), canvas.position + Vector2(canvas.size.x + 4, -3), canvas.end + Vector2(3 + sway, 4), canvas.position + Vector2(canvas.size.x * 0.55, canvas.size.y + 1), canvas.position + Vector2(-3 + sway, canvas.size.y + 5)])
		draw_colored_polygon(sheet, Color("d9cbbd").darkened(0.25))
		for index in range(3):
			var x := canvas.position.x + canvas.size.x * (0.25 + index * 0.25)
			draw_line(Vector2(x, canvas.position.y - 2), Vector2(x + sway, canvas.end.y + 2), Color("8b6d9c").darkened(0.2), 1)
	# Brass plate under the frame.
	draw_rect(Rect2(Vector2(-9, canvas.end.y + 8), Vector2(18, 4)), GILT.darkened(0.15))
	if inspected:
		draw_rect(Rect2(Vector2(-9, canvas.end.y + 8), Vector2(18, 4)), PALE, false, 1)
