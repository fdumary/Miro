extends Control
var player: IntroPlayer
const ART = preload("res://scripts/weapon_art.gd")
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(player) or not is_instance_valid(player.controls):
		return
	var controls = player.controls
	var bindings = get_node("/root/InputBindings")
	for i in range(4):
		var item: String = controls.slots[i]
		var x := i * 53.0
		draw_style_box(panel_style(controls.active == item and item != ""), Rect2(x, 0, 50, 38))
		var slot_caption: String = controls.controller_settings.prompt("R1" if item=="shank" else "") if controls.pad_prompts else (bindings.label("slot_%d" % (i+1)) + ("/"+bindings.label("melee") if item=="shank" else ""))
		draw_string(ThemeDB.fallback_font, Vector2(x + 4, 11), slot_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
		if item != "":
			var available: bool = controls.has_remote if item == "remote" else (player.has_supplies if item in ["shank", "c4"] else true)
			draw_texture_rect(ART.TEXTURES[item], Rect2(x + 17, 2, 27, 27), false, Color.WHITE if available else Color(1, 1, 1, 0.25))
			var count := ""
			if item == "c4":
				count = "×%d" % player.c4_count
			elif item in player.guns:
				count = "%d / %d" % [player.ammunition if item == player.equipped_gun else player.gun_ammo.get(item, 0), controls.reserves.get(item, 0)]
			draw_string(ThemeDB.fallback_font, Vector2(x + 12, 35), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	var quick := [["blanket", "blanket", "L1"], ["remote", "mp3", "D-pad Down"]]
	for i in range(2):
		var x := 220.0 + i * 53.0
		var item: String = quick[i][0]
		draw_style_box(panel_style(item == "blanket" and player.is_concealed), Rect2(x, 0, 50, 38))
		var caption: String = controls.controller_settings.prompt(quick[i][2]) if controls.pad_prompts else bindings.label(quick[i][1])
		draw_string(ThemeDB.fallback_font, Vector2(x + 3, 10), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		draw_texture_rect(ART.TEXTURES[item], Rect2(x + 17, 7, 25, 25), false, Color.WHITE if item != "remote" or controls.has_remote else Color(1,1,1,0.25))
	draw_string(ThemeDB.fallback_font, Vector2(335, 14), controls.controller_settings.prompt("Triangle Weapons · Touchpad Inventory") if controls.pad_prompts else bindings.keyboard_prompt("[N] Inventory"), HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	var hint := "Left click: use"
	if controls.active == "c4":
		hint = "Right click: place · Left click: detonate · E: recover"
	elif controls.active in player.guns:
		hint = "Left click: fire · Right click: focus · R: reload"
	elif controls.active == "guitar":
		hint = "Left click: strum (puts Keepers to sleep; hurts Niro when exposed) · on the beat reaches further"
	elif controls.active == "remote":
		hint = "Left click: open MP3 · [V] previous · [B] next · [H] shuffle"
	if controls.pad_prompts:
		hint = hint.replace("Left click", "R2").replace("Right click", "L2").replace("E: recover", "Cross: recover").replace("R: reload", "Square: reload")
	hint = controls.controller_settings.prompt(hint)
	draw_string(ThemeDB.fallback_font, Vector2(0, 51), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
	if controls.reload_left > 0:
		var center := Vector2(340, 32)
		draw_arc(center, 9, -PI / 2, -PI / 2 + TAU * controls.progress, 24, Color(1, 1, 1, 0.75), 2)
		draw_string(ThemeDB.fallback_font, Vector2(355, 35), "Reloading", HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
## Placeholder guitar icon. Hook: drop art at res://assets/weapons/guitar.png and it is used instead.
func draw_guitar(center: Vector2, color: Color) -> void:
	if ResourceLoader.exists("res://assets/weapons/guitar.png"):
		draw_texture_rect(ART.TEXTURES.guitar, Rect2(center - Vector2(13, 13), Vector2(27, 27)), false)
		return
	draw_circle(center + Vector2(-4, 5), 6, color)
	draw_circle(center + Vector2(-1, -1), 4.5, color)
	draw_circle(center + Vector2(-4, 5), 2, Color("272744"))
	draw_line(center + Vector2(0, -3), center + Vector2(9, -13), Color("8b6d9c"), 2)
	draw_rect(Rect2(center + Vector2(8, -15), Vector2(4, 4)), Color("8b6d9c"))

func panel_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.26, 0.92)
	style.border_color = Color("f2d3ab") if selected else Color("52566b")
	style.set_border_width_all(1)
	return style
