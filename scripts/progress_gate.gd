@tool
extends StaticBody2D
const LIBRARY = preload("res://scripts/visual_assets.gd")
## Physical milestone gate. See mirospec.md floors 3/4 and class.md Door.
@export var unlock_milestone := ""
@export var gate_size := Vector2(18, 252):
	set(value):
		gate_size = value
		update_shape()
		queue_redraw()
var is_open := false

func _ready() -> void:
	update_shape()

func update_shape() -> void:
	var collision := get_node_or_null("CollisionShape2D")
	if collision:
		var rectangle := RectangleShape2D.new()
		rectangle.size = gate_size
		collision.shape = rectangle

func unlock() -> void:
	if is_open:
		return
	is_open = true
	if not Engine.is_editor_hint():
		get_node("/root/SoundFX").play_sound("gate", -17)
	collision_layer = 0
	$CollisionShape2D.set_deferred("disabled", true)
	queue_redraw()

func _draw() -> void:
	var rectangle := Rect2(-gate_size / 2, gate_size)
	draw_rect(rectangle, Color("494d7e"), false, 2)
	if is_open:
		draw_rect(Rect2(rectangle.position, Vector2(gate_size.x, 10)), Color("c69fa5"))
	else:
		var segment := gate_size.x
		for y in range(int(-gate_size.y / 2), int(gate_size.y / 2), int(segment)):
			var height := minf(segment, gate_size.y / 2 - y)
			draw_texture_rect(LIBRARY.texture("vent"), Rect2(-gate_size.x / 2, y, gate_size.x, height), false, Color("c69fa5"))
		draw_texture_rect(LIBRARY.texture("hazard"), Rect2(-12, gate_size.y / 2 - 50, 24, 24), false)
