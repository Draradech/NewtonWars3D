class_name Network
extends Node3D

var time: float = -1
var timeout: float = 0

var tcp_client: StreamPeerTCP = StreamPeerTCP.new()
const MSG_SIM_TIME: int = 1
const MSG_OWN_ID: int = 2
const MSG_PLAYER_POS: int = 3
const MSG_PLAYER_DATA: int = 4
const MSG_PLAYER_NAME: int = 5
const MSG_PLAYER_DEL: int = 6
const MSG_PLANET: int = 7
const MSG_NEW_MISS: int = 8
const MSG_MISS_POS: int = 9
const MSG_ROUND_TIME: int = 10
const MSG_SET_NAME: int = 50
const MSG_SHOOT: int = 51

var playername: String
var playername_sent: = false
func tcp_connect() -> void:
	var host: String = Global.config["host"]
	var port: int = Global.config["port"]
	var err: = tcp_client.connect_to_host(host, port)
	if err != OK:
		push_error("error on connect")
	timeout = 1.0
	playername = Global.config["name"]

func tcp_disconnect() -> void:
	tcp_client.disconnect_from_host()

var in_packet: = false
var packet_id: = -1
var discon_notify: = true
var nodelay: = false
var player_id: = -1
func process_network(space: Space, delta: float) -> bool:
	var err: = tcp_client.poll()
	if err != OK:
		push_error("error on poll")
	if tcp_client.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		if not nodelay:
			tcp_client.set_no_delay(true)
			nodelay = true
		if not playername_sent:
			tcp_client.put_u32(MSG_SET_NAME)
			var cstr_name: = playername.to_ascii_buffer().slice(0, 16)
			if cstr_name.size() < 16:
				var pba: = PackedByteArray()
				@warning_ignore("return_value_discarded")
				pba.resize(16 - cstr_name.size())
				pba.fill(0)
				cstr_name.append_array(pba)
			err = tcp_client.put_data(cstr_name)
			if err != OK:
				push_error("error on put_data")
			playername_sent = true
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
						var pyid: = tcp_client.get_u32()
						space.set_my_pyid(pyid)
						player_id = pyid
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_PLAYER_DEL:
					if tcp_client.get_available_bytes() >= 4:
						var pyid: = tcp_client.get_u32()
						space.player_disconnect(pyid)
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
						space.update_planet(pnid, Vector3(x, y, z), r)
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
						space.update_player_pos(pyid, Vector3(x, y, z), r)
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_PLAYER_DATA:
					if tcp_client.get_available_bytes() >= 8:
						var pyid: = tcp_client.get_u32()
						var score: = tcp_client.get_float()
						space.update_player_score(pyid, score)
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_NEW_MISS:
					if tcp_client.get_available_bytes() >= 8:
						var pyid: = tcp_client.get_u32()
						var mid: = tcp_client.get_u32()
						space.new_shot(pyid, mid)
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
						space.update_shot_pos(mid, ts, Vector3(x, y, z))
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_PLAYER_NAME:
					if tcp_client.get_available_bytes() >= 20:
						var pyid: = tcp_client.get_u32()
						var pname: = tcp_client.get_string(16)
						space.update_player_name(pyid, pname)
						in_packet = false
					else:
						done = true
				elif packet_id == MSG_ROUND_TIME:
					if tcp_client.get_available_bytes() >= 4:
						var rt: = tcp_client.get_32()
						space.update_round_time(rt)
						in_packet = false
					else:
						done = true
				else:
					push_warning("Unknown packet ID: %d." % packet_id)
					tcp_client.disconnect_from_host()
					return false
			else:
				if tcp_client.get_available_bytes() >= 4:
					packet_id = tcp_client.get_u32()
					in_packet = true
				else:
					done = true
		if !Global.ui.is_menu_open() \
		and Input.is_action_just_pressed("fire"):
			_on_shoot()
		if player_id != -1: return true
	timeout -= delta
	if discon_notify and ((tcp_client.get_status() != StreamPeerTCP.STATUS_CONNECTING and tcp_client.get_status() != StreamPeerTCP.STATUS_CONNECTED) or timeout < 0):
		tcp_client.disconnect_from_host()
		Global.ui.disconnect_message.visible = true
		discon_notify = false
	return false

func _on_shoot() -> void:
	if Global.root.xr: Global.root.xr.vibrate_left(0.1)
	tcp_client.put_u32(MSG_SHOOT)
	tcp_client.put_double(Global.game.space.players[Global.game.space.player_id].pitch)
	tcp_client.put_double(Global.game.space.players[Global.game.space.player_id].yaw)
	tcp_client.put_double(Global.game.space.players[Global.game.space.player_id].speed)
