extends VBoxContainer
const SCREENS = preload("res://scripts/menu_screens.gd")
var preferences: Node
var status: Label
var controls_legend: Label
var speaker_status: Label
var deadzone: HSlider
var deadzone_value: Label
var invert: CheckButton
var crouch: CheckButton
var speaker: CheckButton
var endpoint: OptionButton
var devices := PackedStringArray()
var refresh_left := 0.0

func setup(back: Callable) -> void:
	preferences = get_node("/root/ControllerSettings")
	SCREENS.heading(self, "CONTROLLER", 16)
	status = SCREENS.note(self, "", 11)
	status.name = "ConnectionStatus"
	status.clip_text = true
	var row := HBoxContainer.new()
	add_child(row)
	var label := Label.new()
	label.text = "Stick deadzone"
	row.add_child(label)
	deadzone = HSlider.new()
	deadzone.name = "StickDeadzone"
	deadzone.min_value = 0.10
	deadzone.max_value = 0.45
	deadzone.step = 0.01
	deadzone.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(deadzone)
	deadzone_value = Label.new()
	deadzone_value.custom_minimum_size.x = 42
	row.add_child(deadzone_value)
	deadzone.value_changed.connect(func(value: float): preferences.set_preference("deadzone", value))
	invert = check_option("Invert right stick Y", "invert_aim_y")
	crouch = check_option("Hold L3 to crouch", "hold_crouch")
	speaker = check_option("Remote dialogue on controller speaker", "speaker_enabled")
	endpoint = OptionButton.new()
	endpoint.name = "ControllerSpeakerDevice"
	endpoint.clip_text = true
	add_child(endpoint)
	endpoint.item_selected.connect(func(index: int): preferences.set_preference("speaker_endpoint", endpoint.get_item_metadata(index)))
	speaker_status = SCREENS.note(self, "", 9)
	controls_legend = SCREENS.note(self, preferences.controls_help(get_node("/root/Campaign").tuning()), 9)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(buttons)
	SCREENS.button(buttons, "Reset defaults", preferences.restore_defaults)
	SCREENS.button(buttons, "Back", back)
	preferences.devices_changed.connect(refresh)
	preferences.changed.connect(refresh)
	refresh()
	deadzone.grab_focus()

func check_option(title: String, key: String) -> CheckButton:
	var control := CheckButton.new()
	control.text = title
	control.add_theme_font_size_override("font_size", 12)
	add_child(control)
	control.toggled.connect(func(value: bool): preferences.set_preference(key, value))
	return control

func refresh_status() -> void:
	status.text = preferences.device_status()

func refresh() -> void:
	refresh_status()
	if is_instance_valid(crouch): crouch.text = preferences.pad_prompt("Hold L3 to crouch")
	if is_instance_valid(invert): invert.text = preferences.pad_prompt("Invert Right stick Y")
	if is_instance_valid(controls_legend): controls_legend.text = preferences.controls_help(get_node("/root/Campaign").tuning())
	var config: Dictionary = preferences.preferences
	deadzone.set_value_no_signal(config.deadzone)
	deadzone_value.text = "%d%%" % roundi(config.deadzone * 100)
	invert.set_pressed_no_signal(config.invert_aim_y)
	crouch.set_pressed_no_signal(config.hold_crouch)
	speaker.set_pressed_no_signal(config.speaker_enabled)
	var windows := OS.get_name() == "Windows"
	speaker.disabled = not windows
	endpoint.disabled = not windows or not config.speaker_enabled
	devices = AudioServer.get_output_device_list() if windows else PackedStringArray()
	endpoint.clear()
	endpoint.add_item("Controller speaker: Automatic")
	endpoint.set_item_metadata(0, "")
	var selected := 0
	for device in devices:
		if device == "Default":
			continue
		endpoint.add_item(device)
		var index := endpoint.item_count - 1
		endpoint.set_item_metadata(index, device)
		if device == config.speaker_endpoint:
			selected = index
	if selected == 0 and not str(config.speaker_endpoint).is_empty():
		endpoint.add_item("Unavailable: " + str(config.speaker_endpoint))
		selected = endpoint.item_count - 1
		endpoint.set_item_metadata(selected, config.speaker_endpoint)
	endpoint.select(selected)
	if not windows:
		speaker_status.text = "Controller speaker output is available on Windows."
	elif not config.speaker_enabled:
		speaker_status.text = "Remote dialogue plays through the normal audio output."
	else:
		var output: String = preload("res://scripts/controller_radio_link.gd").speaker_device(config.speaker_endpoint)
		speaker_status.text = "Radio output: " + output if not output.is_empty() else "No speaker endpoint available. Using normal audio."

func _process(delta: float) -> void:
	if preferences == null or OS.get_name() != "Windows":
		return
	refresh_left -= delta
	if refresh_left <= 0.0:
		refresh_left = 1.0
		if devices != AudioServer.get_output_device_list():
			refresh()
