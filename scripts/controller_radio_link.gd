extends RefCounted
## A separate, windowless Godot instance owns the controller output. The game's
## AudioServer and its device are never changed by this link.
var server: TCPServer
var stream: StreamPeerTCP
var packets: PacketPeerStream
var token := ""
var pid := -1
var ready := false
var retry_left := 0.0
var handshake_left := 0.0
var mix_state: Array = []

static func speaker_device() -> String:
	for device in AudioServer.get_output_device_list():
		var name := device.to_lower()
		if "dualsense" in name or "dualshock" in name or "wireless controller" in name:
			return device
	return ""

func update(delta: float, paused: bool) -> void:
	if pid <= 0:
		if OS.get_name() != "Windows" or DisplayServer.get_name() == "headless":
			return
		retry_left -= delta
		if retry_left <= 0:
			retry_left = 3.0
			var device := speaker_device()
			if not device.is_empty():
				start(device)
		return
	if not OS.is_process_running(pid):
		close()
		return
	if not ready:
		handshake_left -= delta
		if handshake_left <= 0:
			close()
			return
	if stream == null and server.is_connection_available():
		stream = server.take_connection()
		packets = PacketPeerStream.new()
		packets.stream_peer = stream
	if stream == null:
		return
	stream.poll()
	if stream.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		close()
		return
	while packets.get_available_packet_count() > 0:
		var message = JSON.parse_string(packets.get_packet().get_string_from_utf8())
		if message is Array and message == ["ready", token]:
			ready = true
	if ready:
		var voice := AudioServer.get_bus_index("Voice")
		var master := AudioServer.get_bus_index("Master")
		var state := ["mix", paused, AudioServer.get_bus_volume_db(master) + (AudioServer.get_bus_volume_db(voice) if voice >= 0 else 0.0), AudioServer.is_bus_mute(master) or (voice >= 0 and AudioServer.is_bus_mute(voice))]
		if state != mix_state and send(state):
			mix_state = state

func start(device: String, driver := "WASAPI") -> void:
	server = TCPServer.new()
	if server.listen(0, "127.0.0.1") != OK:
		server = null
		return
	token = Crypto.new().generate_random_bytes(24).hex_encode()
	handshake_left = 5.0
	var args := PackedStringArray(["--display-driver", "headless", "--audio-driver", driver,
		"--log-file", "user://logs/controller-radio.log", "--max-fps", "60", "res://scenes/controller_radio_worker.tscn", "--",
		"--controller-radio-worker", str(server.get_local_port()), token, device])
	if OS.has_feature("editor"):
		args.insert(0, ProjectSettings.globalize_path("res://"))
		args.insert(0, "--path")
	pid = OS.create_process(OS.get_executable_path(), args)
	if pid <= 0:
		close()

func send(message: Array) -> bool:
	return ready and packets.put_packet(JSON.stringify(message).to_utf8_buffer()) == OK

func close() -> void:
	ready = false
	mix_state.clear()
	if is_instance_valid(stream):
		stream.disconnect_from_host()
	if is_instance_valid(server):
		server.stop()
	if pid > 0 and OS.is_process_running(pid):
		OS.kill(pid)
	pid = -1
	packets = null
	stream = null
	server = null
