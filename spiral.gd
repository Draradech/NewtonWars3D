@tool
extends Node3D

@export var material: BaseMaterial3D
var t = 0.0
var line: Line3D

func _ready():
	line = Line3D.new()
	line.material = material
	add_child(line)

func _physics_process(delta: float):
	if t > 100: return
	for i in range(10):
		t += delta
		line.addPoint(Vector3(.5 * t, sin(.5 * t * 2 * PI), cos(.5 * t * 2 * PI)))
