extends RichTextLabel

var player: Player
var digit: int = 0
func update_label(pl: Player):
	player = pl
	var pitchstring: = "%13.8f" % player.pitch
	if absf(player.pitch) < 1e-10: player.pitch = 0.0
	player.pitch = clampf(player.pitch, -999, 999)
	pitchstring = ("%13.8f" % player.pitch).insert((5 if digit < 0 else 4) - digit, "[/color]")
	pitchstring = pitchstring.insert((4 if digit < 0 else 3) - digit, "[color=ff7f00]")
	
	var yawstring: = "%13.8f" % player.yaw
	if absf(player.yaw) < 1e-10: player.yaw = 0.0
	player.yaw = clampf(player.yaw, -999, 999)
	yawstring = ("%13.8f" % player.yaw).insert((5 if digit < 0 else 4) - digit, "[/color]")
	yawstring = yawstring.insert((4 if digit < 0 else 3) - digit, "[color=ff7f00]")
	
	var speedstring: = "%13.8f" % player.speed
	if absf(player.speed) < 1e-10: player.speed = 0.0
	player.speed = clampf(player.speed, 0, 999)
	speedstring = ("%13.8f" % player.speed).insert((5 if digit < 0 else 4) - digit, "[/color]")
	speedstring = speedstring.insert((4 if digit < 0 else 3) - digit, "[color=ff7f00]")
	
	var bbstring: = "[center]"
	bbstring += "Yaw:   "
	bbstring += yawstring
	bbstring += "\nPitch: "
	bbstring += pitchstring
	bbstring += "\nSpeed: "
	bbstring += speedstring
	bbstring += "[/center]"
	text = bbstring

func _input(event: InputEvent) -> void:
	if get_parent().get_parent().is_menu_open: return
	if not player: return
	if event is InputEventKey and event.is_pressed():
		match(event.key_label):
			KEY_PAGEUP:
				digit += 1
			KEY_PAGEDOWN:
				digit -= 1
			KEY_UP:
				player.pitch += pow(10, digit)
			KEY_DOWN:
				player.pitch -= pow(10, digit)
			KEY_RIGHT:
				player.yaw += pow(10, digit)
			KEY_LEFT:
				player.yaw -= pow(10, digit)
			KEY_PLUS:
				player.speed += pow(10, digit)
			KEY_MINUS:
				player.speed -= pow(10, digit)
		digit = clampi(digit, -8, 2)
		update_label(player)
