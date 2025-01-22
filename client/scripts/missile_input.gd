class_name MissileInput
extends RichTextLabel

func update_label(player: Player) -> void:
	var col: Color = Global.config["color_self"]
	
	var pitchstring: = ("%13.8f" % player.pitch).insert((5 if player.digit < 0 else 4) - player.digit, "[/color]")
	pitchstring = pitchstring.insert((4 if player.digit < 0 else 3) - player.digit, "[color=%s]" % col.to_html(false))
	
	var yawstring: = ("%13.8f" % player.yaw).insert((5 if player.digit < 0 else 4) - player.digit, "[/color]")
	yawstring = yawstring.insert((4 if player.digit < 0 else 3) - player.digit, "[color=%s]" % col.to_html(false))
	
	var speedstring: = ("%13.8f" % player.speed).insert((5 if player.digit < 0 else 4) - player.digit, "[/color]")
	speedstring = speedstring.insert((4 if player.digit < 0 else 3) - player.digit, "[color=%s]" % col.to_html(false))
	
	var bbstring: = "[center]"
	bbstring += "Yaw:   "
	bbstring += yawstring
	bbstring += "\nPitch: "
	bbstring += pitchstring
	bbstring += "\nSpeed: "
	bbstring += speedstring
	bbstring += "[/center]"
	text = bbstring
