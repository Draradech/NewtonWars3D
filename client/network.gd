class_name Network
extends Node3D

var time: float = -1

var tcp_client: StreamPeerTCP = StreamPeerTCP.new()
const MSG_SIM_TIME: int = 1
const MSG_OWN_ID: int = 2
const MSG_PLAYER_POS: int = 3
const MSG_PLAYER_DEL: int = 6
const MSG_PLANET: int = 7
const MSG_NEW_MISS: int = 8
const MSG_MISS_POS: int = 9
const MSG_MISS_END: int = 10
const MSG_SHOOT: int = 51

func _ready():
	var address = "192.168.0.149"
	var port = 3490
	tcp_client.connect_to_host(address, port)
	tcp_client.set_no_delay(true)

var in_packet: = false
var packet_id: int
var discon_notify = true
func read_network(display: Display) -> bool:
	tcp_client.poll()
	if tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var done: = false
		while not done:
			if in_packet:
				if packet_id == MSG_SIM_TIME:
					if tcp_client.get_available_bytes() >= 8:
						time = tcp_client.get_double()
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_OWN_ID:
					if tcp_client.get_available_bytes() >= 4:
						var pyid = tcp_client.get_u32()
						display.set_my_pyid(pyid)
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_PLAYER_DEL:
					if tcp_client.get_available_bytes() >= 4:
						var pyid = tcp_client.get_u32()
						display.player_disconnect(pyid)
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_PLANET:
					if tcp_client.get_available_bytes() >= 20:
						var pnid: = tcp_client.get_u32()
						var x: = tcp_client.get_float()
						var y: = tcp_client.get_float()
						var z: = tcp_client.get_float()
						var r: = tcp_client.get_float()
						display.update_planet(pnid, Vector3(x, y, z), r)
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_PLAYER_POS:
					if tcp_client.get_available_bytes() >= 20:
						var pyid: = tcp_client.get_u32()
						var x: = tcp_client.get_float()
						var y: = tcp_client.get_float()
						var z: = tcp_client.get_float()
						var r: = tcp_client.get_float()
						display.update_player_pos(pyid, Vector3(x, y, z), r)
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_NEW_MISS:
					if tcp_client.get_available_bytes() >= 8:
						var pyid: = tcp_client.get_u32()
						var mid: = tcp_client.get_u32()
						display.new_shot(pyid, mid)
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_MISS_POS:
					if tcp_client.get_available_bytes() >= 24:
						var mid: = tcp_client.get_u32()
						var ts: = tcp_client.get_double()
						var x: = tcp_client.get_float()
						var y: = tcp_client.get_float()
						var z: = tcp_client.get_float()
						display.update_shot_pos(mid, ts, Vector3(x, y, z))
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_MISS_END:
					if tcp_client.get_available_bytes() >= 4:
						var mid: = tcp_client.get_u32()
						display.shot_die(mid)
						in_packet = false
					else:
						done = true
				else:
					print("Unknown packet ID: %d." % packet_id)
					tcp_client.disconnect_from_host()
					return false
			else:
				if tcp_client.get_available_bytes() >= 4:
					packet_id = tcp_client.get_u32()
					in_packet = true
				else:
					done = true
		if Input.is_action_just_pressed("fire"):
			tcp_client.put_u32(MSG_SHOOT)
			tcp_client.put_double(display.players[display.player_id].pitch)
			tcp_client.put_double(display.players[display.player_id].yaw)
			tcp_client.put_double(display.players[display.player_id].speed)
		return true
	if discon_notify:
		print("Disconnected.")
		discon_notify = false
	return false
