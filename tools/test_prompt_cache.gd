extends SceneTree
var failures := 0
func check(ok: bool, label_: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + label_)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var controller = root.get_node("ControllerSettings")
	var bindings = root.get_node("InputBindings")
	var original_mode: bool = controller.using_controller
	var original_custom: Dictionary = bindings.custom.duplicate(true)
	controller.using_controller = false
	controller.refresh_bound_prompts()
	var hint := "[E] Interact"
	var before: String = controller.prompt(hint)
	var initial_size: int = controller._prompt_cache.size()
	for i in range(1000): check(controller.prompt(hint) == before, "stable repeated label")
	check(controller._prompt_cache.size() == initial_size, "repeated hints reuse one entry")
	bindings.custom["interact"] = ["key", KEY_F]
	bindings.apply()
	check(controller.prompt(hint) != before and "F" in controller.prompt(hint), "rebind invalidates cache")
	controller.using_controller = true
	check(controller.prompt(hint) == controller.pad_prompt(hint), "device switch invalidates cache")
	for i in range(1000): controller.prompt("Hint %d [E]" % i)
	check(controller._prompt_cache.size() == controller.PROMPT_CACHE_LIMIT, "dynamic text remains bounded")
	bindings.custom = original_custom
	bindings.apply()
	controller.using_controller = original_mode
	print("PROMPT_CACHE_RESULT: failures=", failures)
	quit(0 if failures == 0 else 1)
