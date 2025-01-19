class_name MissileInput
extends RichTextLabel

var player: Player
func update_label(pl: Player, digit: int) -> void:
	player = pl
	var col: Color = Global.config["color_self"]
	
	var pitchstring: = "%13.8f" % player.pitch
	if absf(player.pitch) < 1e-10: player.pitch = 0.0
	player.pitch = clampf(player.pitch, -999, 999)
	pitchstring = ("%13.8f" % player.pitch).insert((5 if digit < 0 else 4) - digit, "[/color]")
	pitchstring = pitchstring.insert((4 if digit < 0 else 3) - digit, "[color=%s]" % col.to_html(false))
	
	var yawstring: = "%13.8f" % player.yaw
	if absf(player.yaw) < 1e-10: player.yaw = 0.0
	player.yaw = clampf(player.yaw, -999, 999)
	yawstring = ("%13.8f" % player.yaw).insert((5 if digit < 0 else 4) - digit, "[/color]")
	yawstring = yawstring.insert((4 if digit < 0 else 3) - digit, "[color=%s]" % col.to_html(false))
	
	var speedstring: = "%13.8f" % player.speed
	if absf(player.speed) < 1e-10: player.speed = 0.0
	player.speed = clampf(player.speed, 0, 999)
	speedstring = ("%13.8f" % player.speed).insert((5 if digit < 0 else 4) - digit, "[/color]")
	speedstring = speedstring.insert((4 if digit < 0 else 3) - digit, "[color=%s]" % col.to_html(false))
	
	var bbstring: = "[center]"
	bbstring += "Yaw:   "
	bbstring += yawstring
	bbstring += "\nPitch: "
	bbstring += pitchstring
	bbstring += "\nSpeed: "
	bbstring += speedstring
	bbstring += "[/center]"
	text = bbstring
