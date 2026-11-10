extends Node
## Controller input preferences are separate from the OS playback device.
signal devices_changed
signal changed
const PATH := "user://settings.cfg"
const DEFAULTS := {
	"deadzone": 0.22, "invert_aim_y": false, "hold_crouch": false,
	"speaker_enabled": false, "speaker_endpoint": "",
}
var preferences := DEFAULTS.duplicate()
var using_controller := false:
	set(value):
		if using_controller == value:
			return
		using_controller = value
		if is_inside_tree():
			refresh_bound_prompts()
		changed.emit()
var keyboard: CanvasLayer
var active_device := -1

func _ready() -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	for key in DEFAULTS:
		preferences[key] = config.get_value("controller", key, DEFAULTS[key])
	preferences.deadzone = clampf(float(preferences.deadzone), 0.1, 0.45)
	Input.joy_connection_changed.connect(_on_connection_changed)
	bind_menu_buttons()
	keyboard = preload("res://scripts/controller_keyboard.gd").new()
	add_child(keyboard)
	var devices := Input.get_connected_joypads()
	using_controller = not devices.is_empty()
	if using_controller:
		active_device = devices[0]

## Menus everywhere (start screen, level select, settings, pause, pop-ups) take Cross / A to
## press the focused button and Circle / B to go back. Godot's defaults leave these unbound.
static func bind_menu_buttons() -> void:
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var event := InputEventJoypadButton.new()
		event.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], event):
			InputMap.action_add_event(pair[0], event)

func _on_connection_changed(device: int, connected: bool) -> void:
	if connected:
		active_device = device
		using_controller = true
	elif device == active_device:
		var devices := Input.get_connected_joypads()
		active_device = devices[0] if not devices.is_empty() else -1
		using_controller = active_device >= 0
	refresh_bound_prompts()
	devices_changed.emit()

func _input(event: InputEvent) -> void:
	if (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value) > float(preferences.deadzone)):
		var device_changed := active_device != event.device
		active_device = event.device
		using_controller = true
		if device_changed:
			refresh_bound_prompts()
	elif (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventMouseMotion and event.relative.length() > 3):
		using_controller = false

func playstation() -> bool:
	var name := Input.get_joy_name(active_device).to_lower() if active_device >= 0 else ""
	return name.is_empty() or ["ps4", "ps5", "playstation", "dual", "wireless controller"].any(func(part): return part in name)

func prompt(text: String) -> String:
	return pad_prompt(text) if using_controller else get_node("/root/InputBindings").keyboard_prompt(text.replace("A/D Move · W/S Ladders", "A/D Move · Shift Quiet walk · W/S Ladders"))

static func controller_text(text: String, ps := true) -> String:
	var cross := "Cross" if ps else "A"
	var circle := "Circle" if ps else "B"
	var square := "Square" if ps else "X"
	var triangle := "Triangle" if ps else "Y"
	var select := "Share" if ps else "View"
	var options := "Options" if ps else "Menu"
	var shoulder := "L1/R1" if ps else "LB/RB"
	var use := "R2" if ps else "RT"
	var focus := "L2" if ps else "LT"
	if text.begins_with("A / D  Move"):
		return "Left stick Move/Climb   %s Jump/Interact   %s Dash   %s Pause" % [cross, circle, options]
	text = text.replace("[1] [2] Choose", "[D-pad] Choose")
	text = text.replace("[Z] replace", "[L1] replace").replace("[X] replace", "[R1] replace")
	text = text.replace("[N / Esc]", "[Touchpad / Circle]" if ps else "[View / B]")
	text = text.replace("[Q, left click]", "[%s, %s]" % [triangle, use])
	text = text.replace("[Q + click]", "[%s + %s]" % [triangle, use])
	text = text.replace("[1, left click]", "[%s + %s]" % [shoulder, use])
	text = text.replace("STEALTH READY [2]", "STEALTH READY [%s]" % triangle)
	for key in ["[1]", "[2]", "[3]", "[4]", "[5]"]:
		text = text.replace(key, "[%s]" % shoulder)
	var replacements := {"[C]": "[%s]" % circle, "[R]": "[%s]" % square, "[Space]": "[%s]" % cross, "[E]": "[%s]" % cross, "[Enter]": "[%s]" % cross, "[Tab]": "[%s]" % select, "[Backspace]": "[%s]" % square, "[Esc]": "[%s]" % circle, "[Q]": "[%s]" % triangle, "[N]": "[Touchpad]" if ps else "[View]", "[Z]": "[D-pad Up]", "[T]": "[D-pad Down]", "[B]": "[D-pad Left/Right]", "[W / S]": "[Left stick]", "Press Backspace": "Press %s" % square, "right click": focus, "left click": use, "Left click": use, "Right click": focus, "Space": cross, "press Enter": "press %s" % cross, "STEALTH READY [2]": "STEALTH READY [%s]" % triangle}
	# Stealth is selected with Triangle/Y, not the item-cycle buttons.
	text = text.replace("STEALTH READY [2]", "STEALTH READY [%s]" % triangle)
	for key in replacements:
		text = text.replace(key, replacements[key])
	if not ps:
		for pair in [["L1/R1", "LB/RB"], ["Touchpad", "View"], ["Triangle", "Y"], ["Square", "X"], ["Circle", "B"], ["Cross", "A"], ["Options", "Menu"], ["Share", "View"], ["R2", "RT"], ["L2", "LT"], ["L1", "LB"], ["R1", "RB"]]:
			text = text.replace(pair[0], pair[1])
	return text


## Bind static UI copy once; changing input mode updates every living bound control.
func bind_prompt(control: Control, text: String, pad_text := "") -> void:
	control.set_meta("keyboard_prompt", text)
	control.set_meta("controller_prompt", pad_text)
	control.add_to_group("device_prompts")
	apply_bound_prompt(control)

func apply_bound_prompt(control: Control) -> void:
	var base: String = control.get_meta("keyboard_prompt", "")
	var pad: String = control.get_meta("controller_prompt", "")
	control.set("text", pad_prompt(pad) if using_controller and not pad.is_empty() else prompt(base))

func refresh_bound_prompts() -> void:
	for control in get_tree().get_nodes_in_group("device_prompts"):
		apply_bound_prompt(control)

func device_status() -> String:
	var names := PackedStringArray()
	for id in Input.get_connected_joypads():
		var name := Input.get_joy_name(id)
		names.append(name if not name.is_empty() else "Controller %d" % (id + 1))
	return "No controller connected" if names.is_empty() else "Connected: " + ", ".join(names)

func set_preference(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key) or preferences[key] == value:
		return
	preferences[key] = value
	save()
	changed.emit()

func restore_defaults() -> void:
	preferences = DEFAULTS.duplicate()
	save()
	changed.emit()

func save() -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	for key in preferences:
		config.set_value("controller", key, preferences[key])
	config.save(PATH)

func controls_help(tuning: Dictionary) -> String:
	var text := "Left stick Move / climb · Right stick Aim\nCross Jump / interact · Circle Dash\nL3 Crouch · L1/R1 Select item\nTriangle Blanket / guitar · R2 Use\nL2 Focus / place C4 · Square Reload\nTouchpad Inventory · D-pad Up Hint\nD-pad Down Terminal · D-pad Left/Right Music\nOptions Pause · Use pause menu to retry / select levels\nBlanket: %ds active / %ds recharge" % [int(tuning.stealth_duration), int(tuning.stealth_cooldown)]
	return pad_prompt(text)

func pad_prompt(text: String) -> String:
	text=controller_text(text,true)
	var binding=get_node("/root/InputBindings")
	var names={JOY_BUTTON_A:"Cross",JOY_BUTTON_Y:"Triangle",JOY_BUTTON_LEFT_SHOULDER:"L1",JOY_BUTTON_LEFT_STICK:"L3",JOY_BUTTON_RIGHT_STICK:"R3"}
	for original in names:
		text=text.replace(names[original],"{PAD_%d}" % original)
	for original in names:
		text=text.replace("{PAD_%d}" % original,names.get(binding.pad_button(original),names[original]))
	if binding.preset == "Southpaw":
		text=text.replace("Left stick","{MOVE}").replace("Right stick","Left stick").replace("{MOVE}","Right stick")
	return controller_text(text,false) if not playstation() else text
