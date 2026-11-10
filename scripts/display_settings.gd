extends Node
signal changed
## Presentation preferences only: movement, AI and physics retain their authored tick rate.
const PATH := "user://settings.cfg"
const CAPS := [-1, -2, 30, 60, 120, 144, 165, 180, 240, 360, 0]
const DEFAULTS := {"frame_cap": -1, "vsync": 1, "window_mode": 0, "show_fps": 0}
var preferences := DEFAULTS.duplicate()
var settings_path := PATH
var windowed_size := Vector2i(1280, 720)
var windowed_position := Vector2i.ZERO
var frame_cap_override := false
var vsync_override := false
var window_mode_override := false
var fps_layer: CanvasLayer
var fps_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--controller-radio-worker" in OS.get_cmdline_user_args(): return
	load_preferences()
	# Godot strips several recognised engine options from get_cmdline_args().
	# Preserve their already-applied startup values before reading presentation preferences.
	frame_cap_override = Engine.max_fps > 0 or "--max-fps" in OS.get_cmdline_args() or "--fixed-fps" in OS.get_cmdline_args()
	vsync_override = DisplayServer.window_get_vsync_mode() != int(ProjectSettings.get_setting("display/window/vsync/vsync_mode", 1)) or "--disable-vsync" in OS.get_cmdline_args()
	window_mode_override = DisplayServer.window_get_mode() != int(ProjectSettings.get_setting("display/window/size/mode", 0)) or "--fullscreen" in OS.get_cmdline_args() or "--maximized" in OS.get_cmdline_args() or "--windowed" in OS.get_cmdline_args()
	if DisplayServer.get_name() == "headless": return
	windowed_size = DisplayServer.window_get_size()
	windowed_position = DisplayServer.window_get_position()
	apply()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(update_display_cap)
	timer.timeout.connect(update_fps)
	add_child(timer)
	timer.start()

func load_preferences() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	for key in DEFAULTS:
		var value = config.get_value("display", key, DEFAULTS[key])
		preferences[key] = value if typeof(value) == TYPE_INT else DEFAULTS[key]
	if preferences.frame_cap not in CAPS: preferences.frame_cap = DEFAULTS.frame_cap
	if preferences.vsync not in [0, 1, 2]: preferences.vsync = DEFAULTS.vsync
	if preferences.window_mode not in [0, 1, 2]: preferences.window_mode = DEFAULTS.window_mode
	if preferences.show_fps not in [0, 1]: preferences.show_fps = 0

func save_preferences() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	for key in DEFAULTS: config.set_value("display", key, preferences[key])
	config.save(settings_path)

func refresh_rate() -> float:
	if DisplayServer.get_name() == "headless": return 60.0
	var rate := DisplayServer.screen_get_refresh_rate(DisplayServer.window_get_current_screen())
	return rate if rate > 0.0 else 60.0

func resolved_cap(rate := -1.0) -> int:
	var cap: int = preferences.frame_cap
	if cap >= 0: return cap
	var hz := refresh_rate() if rate < 0.0 else rate
	if hz <= 0.0: hz = 60.0
	return maxi(1, roundi(hz) - (3 if cap == -2 else 0))

func update_display_cap() -> void:
	if frame_cap_override: return
	var cap := resolved_cap()
	if Engine.max_fps != cap:
		Engine.max_fps = cap
		changed.emit()

func apply() -> void:
	update_display_cap()
	if DisplayServer.get_name() == "headless": return
	update_fps()
	if not vsync_override:
		DisplayServer.window_set_vsync_mode(preferences.vsync)
	if window_mode_override: return
	var modes := [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	var desired: int = modes[int(preferences.window_mode)]
	var current := DisplayServer.window_get_mode()
	if desired == current: return
	var fullscreen_modes := [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	if current not in fullscreen_modes and desired in fullscreen_modes:
		windowed_size = DisplayServer.window_get_size()
		windowed_position = DisplayServer.window_get_position()
	DisplayServer.window_set_mode(desired)
	if desired == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(windowed_size)
		DisplayServer.window_set_position(windowed_position)
	else:
		DisplayServer.window_move_to_foreground()

func set_preference(key: String, value: int) -> void:
	if key not in DEFAULTS: return
	if key == "frame_cap" and value not in CAPS: return
	if key == "vsync" and value not in [0, 1, 2]: return
	if key == "window_mode" and value not in [0, 1, 2]: return
	if key == "show_fps" and value not in [0, 1]: return
	preferences[key] = value
	if key == "frame_cap": frame_cap_override = false
	if key == "vsync": vsync_override = false
	if key == "window_mode": window_mode_override = false
	apply()
	save_preferences()
	changed.emit()

func set_preset(vrr: bool) -> void:
	preferences.frame_cap = -2 if vrr else -1
	preferences.vsync = 0 if vrr else 1
	frame_cap_override = false
	vsync_override = false
	apply()
	save_preferences()
	changed.emit()

func update_fps() -> void:
	if DisplayServer.get_name() == "headless": return
	if preferences.show_fps == 0:
		if is_instance_valid(fps_layer): fps_layer.visible = false
		return
	if not is_instance_valid(fps_layer):
		fps_layer = CanvasLayer.new()
		fps_layer.layer = 100
		add_child(fps_layer)
		fps_label = Label.new()
		fps_label.position = Vector2(548, 4)
		fps_label.size = Vector2(86, 18)
		fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fps_label.add_theme_font_size_override("font_size", 12)
		fps_label.add_theme_color_override("font_color", Color.WHITE)
		fps_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		fps_label.add_theme_constant_override("shadow_offset_x", 1)
		fps_label.add_theme_constant_override("shadow_offset_y", 1)
		fps_layer.add_child(fps_label)
	fps_layer.visible = true
	fps_label.text = "%d FPS" % roundi(Engine.get_frames_per_second())
