@tool
extends Node3D

@export var material: BaseMaterial3D

var tpnext: float = 0.0
var ppnext: Vector3 = Vector3(0, sin(0), cos(0))
var tplast: float = 0.0
var pplast: Vector3 = Vector3(0, sin(0), cos(0))
var rplast: Vector3 = Vector3(0, sin(0), cos(0))
var rpnext: Vector3 = Vector3(0, sin(0), cos(0))
var rtpnext: float = 0
var rtplast: float = 0

var tr: float = 0.0

var line: Line3D
var line2: Line3D

func _ready():
	line = Line3D.new()
	line.material = material
	line2 = Line3D.new()
	line2.material = material
	add_child(line)
	add_child(line2)
	
	line2.addPoint(Vector3(0,0,0))
	line2.addPoint(Vector3(.5,.5,0))
	#line2.addPoint(Vector3(1.,.5,.5))
	line2.finalize()

var stop = 0
func _process(delta: float):
	if tr + delta > tpnext:
		return
	if tr <= tplast and tr + delta > tplast:
		line.addPoint(pplast)
		rplast = pplast
		rpnext = ppnext
		rtplast = tplast
		rtpnext = tpnext
	tr += delta
	line.tmpEnd(rplast + (rpnext - rplast) * (tr - rtplast) / (rtpnext - rtplast))

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
		ppnext = Vector3(l * tm, sin(l * tm * 2 * PI), cos(l * tm * 2 * PI))
