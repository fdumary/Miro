extends Control
## Review menu: no spoilers/implementation detail required to start a normal run.
var music: Node

func _ready() -> void:
	music = get_node("/root/MusicDirector")
	if "--verify-playthrough" in OS.get_cmdline_user_args() or Array(OS.get_cmdline_user_args()).any(func(arg): return arg.begins_with("--level=")):
		get_tree().call_deferred("change_scene_to_file", "res://scenes/intro.tscn")
		return
	music.review_override = false
	music.play_track("yz33")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("272744")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var box := VBoxContainer.new()
	box.position = Vector2(95, 12)
	box.size = Vector2(450, 330)
	box.add_theme_constant_override("separation", 5)
	add_child(box)
	var title := Label.new()
	title.text = "MIRO — LAST ONE STANDING"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	add_button(box, "Start new run", func(): launch_level(1))
	var levels := HBoxContainer.new()
	box.add_child(levels)
	for number in range(1, 6):
		add_button(levels, "Level %d" % number, launch_level.bind(number))
	var caption := Label.new()
	caption.text = "Review levels directly • F10 returns here • M mutes all audio"
	caption.add_theme_font_size_override("font_size", 11)
	box.add_child(caption)
	for bus in ["Music", "Effects", "Voice"]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var label := Label.new()
		label.text = bus
		label.custom_minimum_size.x = 70
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = -40
		slider.max_value = 0
		slider.step = 1
		slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		slider.value_changed.connect(func(value): music.set_volume(bus, value))
	var tracks := OptionButton.new()
	tracks.add_item("Soundtrack review — choose a beat")
	var ids: Array = music.catalog.keys()
	for id in ids:
		tracks.add_item(music.catalog[id].title)
	tracks.item_selected.connect(func(index):
		if index > 0:
			music.review_override = true
			music.play_track(ids[index - 1]))
	box.add_child(tracks)
	var note := Label.new()
	note.text = "Music lowers during speech. Overheard lines have subtitles.\nLevel 3: listen for the terminal password, or inspect its slip."
	note.add_theme_font_size_override("font_size", 11)
	box.add_child(note)
	add_button(box, "Quit", func(): get_tree().quit())

func add_button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(action)
	parent.add_child(button)

func launch_level(number: int) -> void:
	var campaign = get_node("/root/Campaign")
	campaign.case_anchors.clear()
	campaign.completed_sigils.clear()
	campaign.narrative_milestones.clear()
	campaign.launch_consumed = true
	get_tree().change_scene_to_file("res://scenes/intro.tscn" if number == 1 else "res://scenes/levels/level_%02d.tscn" % number)
