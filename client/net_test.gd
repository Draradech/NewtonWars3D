extends Node3D

var net_time: float
var render_time: float = -1

var tcp_client: StreamPeerTCP = StreamPeerTCP.new()
var connected: bool = false
var time_packet_id: int = 7  # MSG_SIM_TIME packet identifier

func _ready():
	var address = "127.0.0.1"
	var port = 3490
	
	var err = tcp_client.connect_to_host(address, port)
	if err == OK:
		connected = true
		print("Connected to the server.")
	else:
		print("Failed to connect to the server:", err)

func read_network():
	if not connected:
		return
	tcp_client.poll()
	if tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		print("Conecting")
		return
	elif tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		while tcp_client.get_available_bytes() > 0:
			# Read packet identifier (u32)
			var packet_id = tcp_client.get_u32()
			
			if packet_id == time_packet_id:
				# Read the simulation time (f64)
				net_time = tcp_client.get_double()
				if render_time < 0: render_time = net_time
			else:
				print("Unknown packet ID:", packet_id)
	else:
		print("Disconnected from the server:" + str(tcp_client.get_status()))
		connected = false
		return

func _process(delta: float) -> void:
	read_network()
	var next_render_time: = render_time + delta
	var target_time_delta: = (net_time - 0.05) - next_render_time
	var speedup: = 0.0
	if target_time_delta < -1./60:
		speedup = target_time_delta / 0.1 / 100.0 # 1% slowdown per 100ms buffer underrun
	elif target_time_delta > 1./60:
		speedup = target_time_delta / 0.1 / 100.0 # 1% speedup per 100ms buffer overfill
	next_render_time = render_time + delta * (1 + speedup)
	if next_render_time > net_time:
		print("skip.  net - render: %6.1fms speedup: %4.1f%%" % [(net_time - next_render_time) * 1000., speedup * 100])
		return
	render_time = next_render_time
	print("frame. net - render: %6.1fms speedup: %4.1f%%" % [(net_time - next_render_time) * 1000., speedup * 100])
