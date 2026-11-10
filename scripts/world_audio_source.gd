extends Node2D
## Preserve the 2D caller API while rendering the sound through Godot's 3D speaker panner.
var source: AudioStreamPlayer3D
var spatial: Node3D
var stream: AudioStream:
	set(value):
		stream=value
		if is_instance_valid(source): source.stream=value
var bus := "Effects":
	set(value):
		bus=value
		if is_instance_valid(source): source.bus=value
var volume_db := 0.0:
	set(value):
		volume_db=value
		update_source()
var pitch_scale := 1.0:
	set(value):
		pitch_scale=value
		if is_instance_valid(source): source.pitch_scale=value
var stream_paused := false:
	set(value):
		stream_paused=value
		if is_instance_valid(source): source.stream_paused=value
var playing: bool:
	get: return is_instance_valid(source) and source.playing
var max_distance := 560.0
var attenuation := 1.0
var linear_db_drop := 0.0
func _ready() -> void:
	process_physics_priority=101
	set_physics_process(false)
	spatial=get_node("/root/SpatialAudio")
	source=spatial.create_source()
	if source == null: return
	source.bus=bus
	source.stream=stream
	source.pitch_scale=pitch_scale
	update_source()
func update_source() -> void:
	if not is_instance_valid(source) or not is_instance_valid(spatial): return
	source.position=spatial.mapped(global_position)
	var ratio := global_position.distance_to(spatial.listener_point)/maxf(1.0,max_distance)
	var gain := 0.0
	if linear_db_drop > 0.0:
		gain=-80.0 if ratio >= 1.0 else -linear_db_drop*ratio
	else:
		gain=linear_to_db(maxf(0.0001,pow(clampf(1.0-ratio,0.0,1.0),attenuation)))
	source.volume_db=volume_db+gain
func _physics_process(_delta: float) -> void:
	if playing: update_source()
	else: set_physics_process(false)
func play(from_position := 0.0) -> void:
	if not is_instance_valid(source): return
	update_source()
	source.play(from_position)
	set_physics_process(true)
func stop() -> void:
	set_physics_process(false)
	if is_instance_valid(source): source.stop()
func _exit_tree() -> void:
	if is_instance_valid(source): source.queue_free()
