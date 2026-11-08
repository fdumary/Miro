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

func _ready() -> void:
	var config := ConfigFile.new()
	config.load(PATH)
	for key in DEFAULTS:
		preferences[key] = config.get_value("controller", key, DEFAULTS[key])
	preferences.deadzone = clampf(float(preferences.deadzone), 0.1, 0.45)
	Input.joy_connection_changed.connect(_on_connection_changed)
	bind_menu_buttons()

## Menus everywhere (start screen, level select, settings, pause, pop-ups) take Cross / A to
## press the focused button and Circle / B to go back. Godot's defaults leave these unbound.
static func bind_menu_buttons() -> void:
	for pair in [["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B]]:
		var event := InputEventJoypadButton.new()
		event.button_index = pair[1]
		if not InputMap.action_has_event(pair[0], event):
			InputMap.action_add_event(pair[0], event)

func _on_connection_changed(_device: int, _connected: bool) -> void:
	devices_changed.emit()

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
