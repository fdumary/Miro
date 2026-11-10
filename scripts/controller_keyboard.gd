extends CanvasLayer
## Adds controller keys below the existing terminal field, retaining its icon and contents.
var target: LineEdit
var draft := ""
var uppercase := false
var body: VBoxContainer
var placeholder: Control
var letter_buttons: Array[Button] = []
var panel: PanelContainer
var panel_position := Vector2.ZERO
var panel_size := Vector2.ZERO
var compact_labels: Dictionary = {}
func _ready() -> void:
	name = "ControllerKeyboard"
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	body = VBoxContainer.new()
	body.name = "ControllerKeys"
	body.theme = preload("res://scripts/visual_assets.gd").ui_theme()
	body.add_theme_constant_override("separation", 2)
	add_child(body)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 2)
	body.add_child(grid)
	for character in "1234567890qwertyuiopasdfghjkl;zxcvbnm,?!":
		var button := Button.new()
		button.text = character
		button.custom_minimum_size = Vector2(44, 18)
		button.add_theme_font_size_override("font_size", 10)
		button.set_meta("character", character)
		button.pressed.connect(append.bind(character))
		grid.add_child(button)
		letter_buttons.append(button)
	var actions := HBoxContainer.new()
	body.add_child(actions)
	for character in [" ", "/", ".", "-", "_"]:
		var button := Button.new()
		button.text = "Space" if character == " " else character
		button.custom_minimum_size = Vector2(44, 18)
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(append.bind(character))
		actions.add_child(button)
	var controls := HBoxContainer.new()
	body.add_child(controls)
	for entry in [["Backspace", erase], ["Shift", shift], ["Submit", submit], ["Cancel", close]]:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(114, 20)
		button.add_theme_font_size_override("font_size", 10)
		button.pressed.connect(entry[1])
		controls.add_child(button)
	var hint := Label.new()
	get_node("/root/ControllerSettings").bind_prompt(hint, "D-pad navigate · [Enter] select · [Esc] cancel")
	hint.add_theme_font_size_override("font_size", 9)
	body.add_child(hint)
	body.hide()
func _input(event: InputEvent) -> void:
	if body.visible:
		if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
			get_viewport().set_input_as_handled()
			submit()
			return
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close()
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		var focused := get_viewport().gui_get_focus_owner()
		if focused is LineEdit and focused.is_visible_in_tree() and focused.editable:
			get_viewport().set_input_as_handled()
			open(focused)
func _process(_delta: float) -> void:
	if body.visible:
		if not is_instance_valid(target) or not target.is_visible_in_tree() or not is_instance_valid(placeholder):
			close()
		else:
			body.position = placeholder.global_position
			body.size = placeholder.size
func open(field: LineEdit) -> void:
	if body.visible:
		close()
	target = field
	draft = field.text
	uppercase = false
	panel = null
	var ancestor := field.get_parent()
	while ancestor != null:
		if ancestor is PanelContainer:
			panel = ancestor
			break
		ancestor = ancestor.get_parent()
	if panel != null:
		panel_position = panel.position
		panel_size = panel.size
		panel.position = Vector2(40, 6)
		panel.size = Vector2(560, 348)
	# Keep the PC terminal's output visible while making room for the keys.
	compact_labels.clear()
	for child in field.get_parent().get_children():
		if child is Label and child.custom_minimum_size.y >= 80:
			compact_labels[child] = child.custom_minimum_size
			child.custom_minimum_size.y = 42
	placeholder = Control.new()
	placeholder.name = "ControllerKeysSpace"
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	placeholder.custom_minimum_size = body.get_combined_minimum_size()
	field.get_parent().add_child(placeholder)
	field.get_parent().move_child(placeholder, field.get_index() + 1)
	body.show()
	shift_labels()
	letter_buttons[0].grab_focus()
func append(character: String) -> void:
	if not is_instance_valid(target):
		return
	if target.max_length <= 0 or draft.length() < target.max_length:
		draft += character.to_upper() if uppercase else character
	update_field()
func erase() -> void:
	draft = draft.left(maxi(0, draft.length() - 1))
	update_field()
func shift() -> void:
	uppercase = not uppercase
	shift_labels()
func shift_labels() -> void:
	for button in letter_buttons:
		var character: String = button.get_meta("character")
		button.text = character.to_upper() if uppercase else character
func update_field() -> void:
	if is_instance_valid(target):
		target.text = draft
		target.text_changed.emit(draft)
func submit() -> void:
	if not is_instance_valid(target):
		close()
		return
	var field := target
	var value := draft
	field.text = value
	field.text_changed.emit(value)
	close()
	field.text_submitted.emit(value)
func close() -> void:
	body.hide()
	if is_instance_valid(placeholder):
		placeholder.queue_free()
	placeholder = null
	for label in compact_labels:
		if is_instance_valid(label):
			label.custom_minimum_size = compact_labels[label]
	compact_labels.clear()
	if is_instance_valid(panel):
		panel.position = panel_position
		panel.size = panel_size
		panel.set_deferred("size", panel_size)
	if is_instance_valid(target) and target.is_visible_in_tree():
		target.grab_focus()
	target = null
	panel = null
	draft = ""
