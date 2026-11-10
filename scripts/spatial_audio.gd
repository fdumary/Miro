extends Node3D
## A lightweight 3D audio world for the side-on game. 100 game pixels = one audio metre.
const SCALE := 0.01
var listener: AudioListener3D
var audio_viewport: SubViewport
var audio_camera: Camera3D
var listener_point := Vector2.ZERO
var enabled := true
func _ready() -> void:
	if "--controller-radio-worker" in OS.get_cmdline_user_args():
		enabled=false
		set_physics_process(false)
		return
	process_physics_priority=100
	# A disabled 1px viewport supplies Godot's required camera for 3D audio, with no 3D draw pass.
	audio_viewport=SubViewport.new()
	audio_viewport.size=Vector2i(1,1)
	audio_viewport.own_world_3d=true
	audio_viewport.audio_listener_enable_3d=true
	audio_viewport.render_target_update_mode=SubViewport.UPDATE_DISABLED
	add_child(audio_viewport)
	audio_camera=Camera3D.new()
	audio_camera.cull_mask=0
	audio_viewport.add_child(audio_camera)
	audio_camera.make_current()
	listener=AudioListener3D.new()
	audio_viewport.add_child(listener)
	listener.make_current()
func mapped(point: Vector2) -> Vector3:
	return Vector3(point.x*SCALE,-point.y*SCALE,0.0)
func _physics_process(_delta: float) -> void:
	var scene=get_tree().current_scene
	if not is_instance_valid(scene): return
	var player=scene.get("player")
	if not is_instance_valid(player) or not player is Node2D: return
	listener_point=player.global_position
	listener.position=mapped(listener_point)+Vector3(0,0,0.1)
func create_source() -> AudioStreamPlayer3D:
	if not enabled: return null
	var source := AudioStreamPlayer3D.new()
	source.attenuation_model=AudioStreamPlayer3D.ATTENUATION_DISABLED
	source.max_distance=0.0
	source.attenuation_filter_cutoff_hz=20500.0
	source.panning_strength=1.0
	source.process_mode=Node.PROCESS_MODE_PAUSABLE
	audio_viewport.add_child(source)
	return source
