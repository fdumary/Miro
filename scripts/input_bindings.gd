extends Node
const PATH := "user://settings.cfg"
const KEYS := {"move_left":KEY_A,"move_right":KEY_D,"climb_up":KEY_W,"climb_down":KEY_S,"jump":KEY_SPACE,"dodge":KEY_ALT,"slow_walk":KEY_SHIFT,"crouch":KEY_CTRL,"interact":KEY_E,"advance":KEY_ENTER,"skip":KEY_TAB,"pause_game":KEY_ESCAPE,"retry":KEY_BACKSPACE,"blanket":KEY_Q,"guitar":KEY_G,"inventory":KEY_N,"reload":KEY_R,"music_next":KEY_B,"terminal":KEY_T,"hint":KEY_Z,"mute":KEY_M,"return_menu":KEY_F10,"slot_1":KEY_1,"slot_2":KEY_2,"slot_3":KEY_3,"slot_4":KEY_4,"slot_5":KEY_5,"use_item":0,"focus_item":0}
var settings_path := PATH
var custom: Dictionary = {}
var preset := "Default"
var waiting := ""
var panel: CanvasLayer
var rows: Dictionary = {}
var notice: Label
var controller_help: Label
var previous_focus: Control
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var config := ConfigFile.new()
	config.load(settings_path)
	custom = config.get_value("bindings","keyboard",{})
	preset = config.get_value("bindings","preset","Default")
	apply()
func event_for(action: String) -> InputEvent:
	var spec: Array = custom.get(action, ["mouse",1 if action == "use_item" else 2] if action in ["use_item","focus_item"] else ["key",KEYS[action]])
	if spec[0] == "mouse":
		var event := InputEventMouseButton.new()
		event.button_index = int(spec[1])
		return event
	var event := InputEventKey.new()
	event.physical_keycode = int(spec[1])
	return event
func label(action: String) -> String:
	var event := event_for(action)
	if event is InputEventKey and event.physical_keycode == KEY_ALT: return "Left Alt"
	return ("Mouse %d" % event.button_index) if event is InputEventMouseButton else OS.get_keycode_string(event.physical_keycode)
func matches(event: InputEvent, action: String) -> bool:
	return event_for(action).is_match(event)
func canonical_key(event: InputEvent) -> int:
	for action in KEYS:
		if matches(event,action): return int(KEYS[action])
	return 0
func apply() -> void:
	for action in KEYS:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for event in InputMap.action_get_events(action):
			if event is InputEventKey or event is InputEventMouseButton: InputMap.action_erase_event(action,event)
		InputMap.action_add_event(action,event_for(action))
		if action == "dodge":
			var alternate := InputEventKey.new()
			alternate.physical_keycode=KEY_C
			InputMap.action_add_event(action,alternate)
	for action in ["dodge", "advance", "pause_game", "skip"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadButton:
				InputMap.action_erase_event(action,event)
				var defaults := {"dodge":JOY_BUTTON_B,"advance":JOY_BUTTON_A,"pause_game":JOY_BUTTON_START,"skip":JOY_BUTTON_BACK}
				event.button_index=pad_button(defaults[action])
				InputMap.action_add_event(action,event)
	for action in ["move_left","move_right","climb_up","climb_down"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				InputMap.action_erase_event(action,event)
				event.axis = (0 if action in ["move_left","move_right"] else 1) + (2 if preset == "Southpaw" else 0)
				InputMap.action_add_event(action,event)
func pad_button(original: int) -> int:
	var mapping := {}
	if preset in ["Bumper Jumper","Bumper Jumper Tactical"]:
		mapping[JOY_BUTTON_A]=JOY_BUTTON_LEFT_SHOULDER
		mapping[JOY_BUTTON_LEFT_SHOULDER]=JOY_BUTTON_Y
		mapping[JOY_BUTTON_Y]=JOY_BUTTON_A
	if preset in ["Tactical","Bumper Jumper Tactical"]:
		mapping[JOY_BUTTON_LEFT_STICK]=JOY_BUTTON_RIGHT_STICK
	return int(mapping.get(original,original))
func canonical_pad(button: int) -> int:
	if preset in ["Tactical","Bumper Jumper Tactical"] and button == JOY_BUTTON_LEFT_STICK: return -1
	for original in range(21):
		if pad_button(original)==button: return original
	return button
func save() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value("bindings","keyboard",custom)
	config.set_value("bindings","preset",preset)
	config.save(settings_path)
	apply()
	get_node("/root/ControllerSettings").refresh_bound_prompts()
	get_node("/root/ControllerSettings").changed.emit()
func _input(event: InputEvent) -> void:
	if waiting.is_empty():
		if is_instance_valid(panel) and event.is_action_pressed("ui_cancel"):
			close()
			get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey or event is InputEventMouseButton) or not event.pressed: return
	get_viewport().set_input_as_handled()
	if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
		waiting=""
		notice.text="Cancelled"
		return
	for action in KEYS:
		if (action != waiting and matches(event,action)) or (event is InputEventKey and event.physical_keycode == KEY_C and waiting != "dodge"):
			notice.text="Already assigned to %s. Choose another input; Esc cancels." % action.replace("_"," ")
			return
	custom[waiting]=["mouse",event.button_index] if event is InputEventMouseButton else ["key",event.physical_keycode]
	rows[waiting].text=label(waiting)
	waiting=""
	notice.text="Binding saved"
	save()
func open() -> void:
	if is_instance_valid(panel): return
	previous_focus=get_viewport().gui_get_focus_owner()
	panel=CanvasLayer.new()
	panel.layer=120
	add_child(panel)
	var background := PanelContainer.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(background)
	var style := StyleBoxFlat.new()
	style.bg_color=Color("272744")
	style.content_margin_left=16
	style.content_margin_right=16
	style.content_margin_top=10
	style.content_margin_bottom=10
	background.add_theme_stylebox_override("panel",style)
	var box := VBoxContainer.new()
	background.add_child(box)
	notice=Label.new()
	notice.text="CONTROLS · Select a binding, then press a key or mouse button. Esc cancels."
	notice.add_theme_font_size_override("font_size",12)
	box.add_child(notice)
	var choices := OptionButton.new()
	for name in ["Default","Bumper Jumper","Tactical","Bumper Jumper Tactical","Southpaw"]:
		choices.add_item(name)
		if name==preset: choices.selected=choices.item_count-1
	choices.add_theme_font_size_override("font_size",12)
	box.add_child(choices)
	choices.item_selected.connect(func(index): preset=choices.get_item_text(index); save(); refresh_controller_help())
	var help := Label.new()
	help.text="Bumper Jumper: L1 Jump/Interact, Triangle Previous item, R1 Next item, Cross Blanket/Guitar.\nTactical: R3 Crouch. Other actions stay mapped. Southpaw swaps sticks. C remains alternate dash."
	help.add_theme_font_size_override("font_size",10)
	box.add_child(help)
	var tabs := TabContainer.new()
	tabs.name="BindingTabs"
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(tabs)
	var scroll := ScrollContainer.new()
	scroll.name="Keyboard and Mouse"
	tabs.add_child(scroll)
	var controller_scroll := ScrollContainer.new()
	controller_scroll.name="Controller"
	tabs.add_child(controller_scroll)
	controller_help=Label.new()
	controller_help.add_theme_font_size_override("font_size",12)
	controller_scroll.add_child(controller_help)
	refresh_controller_help()
	var list := VBoxContainer.new()
	list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	rows.clear()
	for action in KEYS:
		var row := HBoxContainer.new()
		list.add_child(row)
		var title := Label.new()
		title.add_theme_font_size_override("font_size",12)
		title.text=action.replace("_"," ").capitalize()
		title.custom_minimum_size.x=200
		row.add_child(title)
		var button := Button.new()
		button.add_theme_font_size_override("font_size",12)
		button.text=label(action)
		button.custom_minimum_size.x=160
		row.add_child(button)
		rows[action]=button
		button.pressed.connect(func(): waiting=action; notice.text="Press a key or mouse button for " + action)
	var reset := Button.new()
	reset.add_theme_font_size_override("font_size",12)
	reset.text="Restore default bindings"
	box.add_child(reset)
	reset.pressed.connect(func(): custom.clear(); preset="Default"; save(); close(); open())
	var back := Button.new()
	back.add_theme_font_size_override("font_size",12)
	back.text="Back"
	box.add_child(back)
	back.pressed.connect(close)
	back.grab_focus()
func close() -> void:
	waiting=""
	if is_instance_valid(panel): panel.queue_free()
	panel=null
	if is_instance_valid(previous_focus): previous_focus.grab_focus.call_deferred()

func keyboard_prompt(text: String) -> String:
	var replacements := {"[C]":"["+label("dodge")+" / C]", "[Q]":"["+label("blanket")+"]", "[R]":"["+label("reload")+"]", "[E]":"["+label("interact")+"]", "[Space]":"["+label("jump")+"]", "[N]":"["+label("inventory")+"]", "[T]":"["+label("terminal")+"]", "[Z]":"["+label("hint")+"]"}
	for key in replacements: text=text.replace(key,replacements[key])
	text=text.replace("C Dash",label("dodge")+" / C Dash").replace("C  Dash",label("dodge")+" / C  Dash")
	for action in ["slot_1","slot_2","slot_3","slot_4","slot_5"]:
		text=text.replace("["+action.trim_prefix("slot_")+"]","["+label(action)+"]")
	text=text.replace("A/D",label("move_left")+"/"+label("move_right")).replace("A / D",label("move_left")+" / "+label("move_right"))
	text=text.replace("W/S",label("climb_up")+"/"+label("climb_down"))
	text=text.replace("Space",label("jump")).replace("Left Ctrl",label("crouch")).replace("Shift Quiet",label("slow_walk")+" Quiet")
	for pair in [["Q Blanket","blanket"],["N Inventory","inventory"],["R Reload","reload"],["E Interact","interact"],["T Open","terminal"],["B Next","music_next"],["Z Think","hint"],["M Mute","mute"],["M mutes","mute"]]:
		text=text.replace(pair[0],label(pair[1])+str(pair[0]).substr(1))
	text=text.replace("F10",label("return_menu"))
	text=text.replace("Left click",label("use_item")).replace("left click",label("use_item")).replace("Right click",label("focus_item")).replace("right click",label("focus_item"))
	return text

func refresh_controller_help() -> void:
	if is_instance_valid(controller_help):
		controller_help.text=get_node("/root/ControllerSettings").controls_help(get_node("/root/Campaign").tuning())
