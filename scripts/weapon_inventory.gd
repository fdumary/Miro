extends Control
var player: IntroPlayer

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(player):
		return
	var items: Array[String] = ["shank", "blanket", "c4"]
	items.append_array(player.guns)
	if player.has_gun and player.guns.is_empty():
		items.append(player.equipped_gun)
	for i in range(items.size()):
		var item := items[i]
		var available := player.has_supplies if i < 2 else (player.c4_count > 0 if i == 2 else true)
		var rect := Rect2(i * 47, 0, 44, 31)
		draw_style_box(panel_style(item == player.equipped_gun and i >= 3), rect)
		draw_texture_rect(preload("res://scripts/weapon_art.gd").TEXTURES[item], Rect2(i * 47 + 2, 2, 24, 24), false, Color.WHITE if available else Color(1, 1, 1, 0.25))
		var text := str(i + 1) if i < 2 else (str(player.c4_count) if i == 2 else str(player.ammunition if item == player.equipped_gun else player.gun_ammo.get(item, 0)))
		draw_string(ThemeDB.fallback_font, Vector2(i * 47 + 27, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	if player.has_gun:
		draw_string(ThemeDB.fallback_font, Vector2(0, 43), "[Q] switch • mouse aim / fire • suppressor: pistol only", HORIZONTAL_ALIGNMENT_LEFT, -1, 10)

	if is_instance_valid(player.pending_guard):
		draw_style_box(panel_style(true), Rect2(120, 75, 372, 86))
		draw_string(ThemeDB.fallback_font, Vector2(136, 96), "Take %s? Carry limit: two guns." % player.pending_guard.weapon_kind.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
		draw_string(ThemeDB.fallback_font, Vector2(136, 119), "[Z] Replace %s   [X] Replace %s" % [player.guns[0], player.guns[1]], HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_string(ThemeDB.fallback_font, Vector2(136, 145), "[Esc] Keep current guns", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

func panel_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.26, 0.9)
	style.border_color = Color("f2d3ab") if selected else Color("52566b")
	style.set_border_width_all(1)
	return style
