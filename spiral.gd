extends Node3D

@export var mat_shot: BaseMaterial3D

var tpnext: float = 0.0
var ppnext: Vector3 = Vector3(0, 50. * sin(0), 50. * cos(0))
var tplast: float = 0.0
var pplast: Vector3 = Vector3(0, 50. * sin(0), 50. * cos(0))
var rplast: Vector3 = Vector3(0, 50. * sin(0), 50. * cos(0))
var rpnext: Vector3 = Vector3(0, 50. * sin(0), 50. * cos(0))
var rtpnext: float = 0
var rtplast: float = 0

var rt: float = 0.0

var line: Line3D

func _ready():
	line = Line3D.new()
	line.material = mat_shot
	add_child(line)

var stop = 0
func _process(delta: float):
	if rt + delta > tpnext:
		return
	if rt <= tplast and rt + delta > tplast:
		line.addPoint(pplast)
		rplast = pplast
		rpnext = ppnext
		rtplast = tplast
		rtpnext = tpnext
	rt += delta
	line.tmpEnd(rplast + (rpnext - rplast) * (rt - rtplast) / (rtpnext - rtplast))

var i: int = 0
var slowdown: int = 10
func _physics_process(delta: float):
	i += 1
	if i % slowdown == 0:
		pplast = ppnext
		tplast = tpnext
		tpnext += delta * slowdown
		var tm = tpnext / slowdown
		var l = 1.
		var s = 50.
		ppnext = Vector3(s * l * tm, s * sin(l * tm * 2 * PI), s * cos(l * tm * 2 * PI))
