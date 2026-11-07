## Runs the exported-playthrough QA check in the editor build: godot --headless --fixed-fps 60 --script res://tools/run_playthrough_local.gd
extends SceneTree
func _initialize() -> void:
	call_deferred("go")
func go() -> void:
	change_scene_to_file("res://scenes/intro.tscn")
	await process_frame
	await process_frame
	root.add_child((func(): var n = Node.new(); n.set_script(load("res://tools/export_playthrough.gd")); return n).call())
