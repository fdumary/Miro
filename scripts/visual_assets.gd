extends RefCounted
## Shared library skin; Julia's art is never recolored by this class.
static var textures: Dictionary = {}

static func texture(id: String) -> Texture2D:
	if not textures.has(id):
		textures[id] = load("res://assets/library/%s.png" % id)
	return textures[id]

static func panel_style(hover := false) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture("panel_hover" if hover else "panel")
	style.modulate_color = Color("8b6d9c")
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		style.set_texture_margin(side, 6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func ui_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = preload("res://scripts/typeface.gd").body()
	theme.default_font_size = 12
	for type in ["Button", "LineEdit", "OptionButton"]:
		theme.set_color("font_color", type, Color("fbf5ef"))
		theme.set_color("font_hover_color", type, Color("f2d3ab"))
		for state in ["normal", "pressed", "disabled"]:
			var style := panel_style()
			if state != "normal":
				style.modulate_color = Color("494d7e")
			style.content_margin_top = 3
			style.content_margin_bottom = 3
			style.content_margin_left = 8
			style.content_margin_right = 8
			theme.set_stylebox(state, type, style)
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = Color("f2d3ab")
		focus.set_border_width_all(1)
		theme.set_stylebox("focus", type, focus)
		var hover := panel_style(true)
		hover.content_margin_top = 3
		hover.content_margin_bottom = 3
		theme.set_stylebox("hover", type, hover)
	theme.set_color("font_color", "Label", Color("f2d3ab"))
	return theme

static func hint_texture(text: String) -> Texture2D:
	for entry in [["[E]", "key_e"], ["[1]", "key_1"], ["[2]", "key_2"], ["[3]", "key_3"], ["[4]", "key_4"], ["[W / S]", "key_w"]]:
		if str(entry[0]) in text:
			return texture(entry[1])
	return null
