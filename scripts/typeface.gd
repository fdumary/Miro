extends Node
## Gothic look for all game text. Pirata One (readable blackletter) is the body face for every
## Control and every draw_string that uses ThemeDB.fallback_font; Unifraktur Maguntia is the
## Dracula-style face for titles (start, end, credits and cutscene cards).
const BODY_PATH := "res://assets/fonts/PirataOne-Regular.ttf"
const TITLE_PATH := "res://assets/fonts/UnifrakturMaguntia-Book.ttf"
static var body_font: Font
static var title_font: Font

func _enter_tree() -> void:
	ThemeDB.fallback_font = body()

static func body() -> Font:
	if body_font == null:
		body_font = load(BODY_PATH)
	return body_font

static func title() -> Font:
	if title_font == null:
		title_font = load(TITLE_PATH)
	return title_font
