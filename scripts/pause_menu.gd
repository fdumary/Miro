extends CanvasLayer
## Esc on a floor: Resume, Restart floor, Controls, Settings, Level select, Main menu.
## Lives on the level (process mode inherited as ALWAYS) so its buttons work while the tree is paused.
const SCREENS = preload("res://scripts/menu_screens.gd")
var level: Node
var shade: ColorRect
var menu: VBoxContainer
var side: Control
var side_id := ""
var now_playing: Label
var was_open := false
var last_pad_mode := false

func _ready() -> void:
	layer = 40
	name = "PauseMenu"
	shade = ColorRect.new()
	shade.color = Color(0.06, 0.05, 0.1, 0.86)
	shade.size = Vector2(640, 360)
	add_child(shade)
	var root := Control.new()
	root.size = Vector2(640, 360)
	root.theme = preload("res://scripts/visual_assets.gd").ui_theme()
	shade.add_child(root)
	var title := SCREENS.heading(root, "PAUSED", 22)
	title.position = Vector2(30, 34)
	title.size = Vector2(170, 30)
	menu = VBoxContainer.new()
	menu.position = Vector2(40, 78)
	menu.size = Vector2(150, 200)
	menu.add_theme_constant_override("separation", 5)
	root.add_child(menu)
	var resume := SCREENS.button(menu, "Resume  [Esc]", resume_game)
	resume.name = "Resume"
	SCREENS.button(menu, "Restart floor", restart).name = "Restart"
	SCREENS.button(menu, "Controls", func(): toggle_side("controls")).name = "Controls"
	SCREENS.button(menu, "Settings", func(): toggle_side("settings")).name = "Settings"
	SCREENS.button(menu, "Level select", func(): leave("levels")).name = "LevelSelect"
	SCREENS.button(menu, "Main menu", func(): leave("title")).name = "MainMenu"
	now_playing = SCREENS.note(root, "", 9)
	now_playing.position = Vector2(20, 300)
	now_playing.size = Vector2(190, 40)
	side = Control.new()
	side.mouse_filter = Control.MOUSE_FILTER_IGNORE
	side.size = Vector2(640, 360)
	root.add_child(side)
	shade.visible = false

func _process(_delta: float) -> void:
	if not is_instance_valid(level):
		return
	var open: bool = level.paused and not level.completed and not level.player.is_dead
	shade.visible = open
	var pad_mode: bool = get_node("/root/ControllerSettings").using_controller
	if open and (not was_open or pad_mode != last_pad_mode):
		toggle_side("controls", true)
		menu.get_node("Resume").grab_focus()
	was_open = open
	last_pad_mode = pad_mode
	menu.get_node("Resume").text = ("Resume  [Options]" if get_node("/root/ControllerSettings").playstation() else "Resume  [Menu]") if pad_mode else "Resume  [Esc]"
	if open:
		var music = get_node("/root/MusicDirector")
		var title: String = music.catalog.get(music.track_id, {}).get("title", "silence")
		now_playing.text = get_node("/root/ControllerSettings").prompt("Now playing: %s\n%s · [B] next beat on the MP3" % [title, get_node("/root/Campaign").tuning().label])

func resume_game() -> void:
	level.paused = false
	get_tree().paused = false

func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

## Back to the start screen, opening on `screen` ("levels" or "title").
func leave(screen: String) -> void:
	get_tree().paused = false
	get_node("/root/Campaign").menu_screen = screen
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func toggle_side(id: String, force := false) -> void:
	if side_id == id and not force:
		return
	side_id = id
	for child in side.get_children():
		child.queue_free()
	if id == "settings":
		SCREENS.settings(side, Rect2(220, 60, 390, 200), true, func(): toggle_side("controller"), func(): toggle_side("display"))
	elif id == "display":
		var box := SCREENS.display_settings(side, Rect2(218, 34, 402, 285))
		SCREENS.button(box, "Back to settings", func(): toggle_side("settings"))
	elif id == "controller":
		SCREENS.controller_settings(side, Rect2(218, 34, 402, 285), func(): toggle_side("settings"))
	else:
		var box := SCREENS.column(side, Rect2(220, 60, 390, 200), 2)
		SCREENS.heading(box, "CONTROLS", 14)
		var tuning: Dictionary = get_node("/root/Campaign").tuning()
		var text := "A/D Move · W/S Ladders · Space twice Double jump\nHold toward wall to slide · Space on contact to bounce\nC Dash · Left Ctrl Crouch (crawl under walls) · E Interact\n1–5 Select · Q Blanket · N Inventory · R Reload\nLeft click Use · Right click Focus / place C4\nZ Think it through (up to 3 hints per objective)\nT Open a nearby terminal · B Next beat · M Mute\nBlanket: use it to hide · %ds active / %ds recharge\nEsc Resume · Backspace Retry · F10 Menu" % [int(tuning.stealth_duration), int(tuning.stealth_cooldown)]
		if get_node("/root/ControllerSettings").using_controller:
			text = get_node("/root/ControllerSettings").controls_help(tuning)
		SCREENS.note(box, text, 10, SCREENS.SAND)
