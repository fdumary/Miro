extends Node
## The worker loads the same clips and Radio bus, but only opens the chosen endpoint.
var connection := StreamPeerTCP.new()
var packets := PacketPeerStream.new()
var token := ""
var device := ""
var remaining := 5.0
var check_left := 0.0
var ready_sent := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() != 4 or args[0] != "--controller-radio-worker":
		get_tree().quit(1)
		return
	token = args[2]
	device = args[3]
	if device == "Default" or device not in AudioServer.get_output_device_list():
		get_tree().quit(1)
		return
	AudioServer.output_device = device
	var voice := AudioServer.get_bus_index("Voice")
	if voice >= 0:
		AudioServer.set_bus_volume_db(voice, 0.0)
	packets.stream_peer = connection
	if connection.connect_to_host("127.0.0.1", args[1].to_int()) != OK:
		get_tree().quit(1)

func _process(delta: float) -> void:
	connection.poll()
	var status := connection.get_status()
	if status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
		get_tree().quit()
		return
	if not ready_sent:
		remaining -= delta
		if remaining <= 0:
			get_tree().quit(1)
			return
		if status != StreamPeerTCP.STATUS_CONNECTED or AudioServer.output_device != device:
			return
		ready_sent = packets.put_packet(JSON.stringify(["ready", token]).to_utf8_buffer()) == OK
		# Do not play if the OS moves this instance back to the default output.
		if not ready_sent:
			return
	check_left -= delta
	if check_left <= 0:
		check_left = 0.25
		if AudioServer.output_device != device or device not in AudioServer.get_output_device_list():
			get_tree().quit()
			return
	var radio = get_node("/root/RemoteRadio")
	while packets.get_available_packet_count() > 0:
		var message = JSON.parse_string(packets.get_packet().get_string_from_utf8())
		if not message is Array or message.is_empty():
			continue
		match message[0]:
			"say":
				if message.size() == 2 and message[1] is String and AudioServer.output_device == device:
					radio.say(message[1])
			"stop":
				radio.stop()
			"mix":
				if message.size() == 4:
					get_tree().paused = bool(message[1])
					AudioServer.set_bus_volume_db(0, float(message[2]))
					AudioServer.set_bus_mute(0, bool(message[3]))
