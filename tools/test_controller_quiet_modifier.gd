extends SceneTree
var failures: Array[String] = []
var checks := 0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label_: String) -> void:
	checks+=1
	if not ok:failures.append(label_);push_error(label_)
func frames(n: int) -> void:
	for i in range(n):await physics_frame;await process_frame
func button(index: int,down: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.device=0;event.button_index=index;event.pressed=down
	Input.parse_input_event(event)
	await frames(2)
func run() -> void:
	var bindings=root.get_node("InputBindings")
	var original=bindings.preset
	var settings=root.get_node("ControllerSettings")
	var hold_crouch=settings.preferences.hold_crouch
	settings.preferences.hold_crouch=false
	var level=load("res://scenes/intro.tscn").instantiate();root.add_child(level);current_scene=level
	await frames(4);level.finish_dialogue();level.set_process(false);level.world_features.set_process(false)
	if is_instance_valid(level.card):level.card.finish()
	var p=level.player
	p.has_supplies=true;p.controls.pad_device=0
	for g in level.guards():g.set_physics_process(false);g.position=Vector2(-500,-500)
	for preset in ["Default","Tactical","Bumper Jumper","Bumper Jumper Tactical","Southpaw"]:
		bindings.preset=preset;bindings.apply()
		var modifier: int=bindings.pad_button(JOY_BUTTON_RIGHT_STICK)
		var crouch: int=bindings.pad_button(JOY_BUTTON_LEFT_STICK)
		check(modifier!=crouch,preset+" distinct stick clicks")
		check(bindings.canonical_pad(modifier)==JOY_BUTTON_RIGHT_STICK,preset+" modifier inverse mapping")
		p.position=Vector2(350,236);p.velocity=Vector2.ZERO;p.is_concealed=false;p.pad_crouch=false
		Input.action_press("move_right");await frames(4)
		var normal: float=absf(p.velocity.x)
		await button(modifier,true)
		var quiet: float=absf(p.velocity.x)
		check(p.controls.wants_quiet_modifier(),preset+" modifier held")
		check(not p.crouching,preset+" modifier does not crouch")
		check(quiet>0 and absf(quiet/normal-0.55)<0.01,preset+" quiet speed matches Shift")
		await button(modifier,false)
		check(not p.controls.wants_quiet_modifier(),preset+" release clears modifier")
		p.position=Vector2(350,236);p.is_concealed=true;p.stealth_remaining=12
		await frames(3)
		var slow: float=absf(p.velocity.x)
		await button(modifier,true)
		check(absf(p.velocity.x)>slow and p.is_concealed,preset+" held modifier accelerates blanket")
		await button(modifier,false)
		check(absf(absf(p.velocity.x)-slow)<0.1,preset+" release restores blanket speed")
		p.is_concealed=false
		await button(crouch,true);await button(crouch,false)
		await frames(8)
		check(p.crouching and not p.controls.wants_quiet_modifier(),preset+" crouch remains separate")
		p.pad_crouch=false
		Input.action_release("move_right")
	bindings.preset=original;bindings.apply()
	settings.preferences.hold_crouch=hold_crouch
	print("CONTROLLER_QUIET_RESULT: ",checks-failures.size(),"/",checks)
	quit(0 if failures.is_empty() else 1)
