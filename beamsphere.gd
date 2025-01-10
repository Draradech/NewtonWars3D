class_name BeamSphere
extends MeshInstance3D

const sides: int = 8

var surface: Array
var verts: PackedVector3Array
var indices: PackedInt32Array

const PHI = (1 + sqrt(5)) / 2
const IPH = 1 / PHI

var ddvert = [
	Vector3(   1,    1,    1),
	Vector3(   1,    1,   -1),
	Vector3(   1,   -1,    1),
	Vector3(   1,   -1,   -1),
	Vector3(  -1,    1,    1),
	Vector3(  -1,    1,   -1),
	Vector3(  -1,   -1,    1),
	Vector3(  -1,   -1,   -1),
	Vector3(   0,  PHI,  IPH),
	Vector3(   0,  PHI, -IPH),
	Vector3(   0, -PHI,  IPH),
	Vector3(   0, -PHI, -IPH),
	Vector3( PHI,  IPH,    0),
	Vector3( PHI, -IPH,    0),
	Vector3(-PHI,  IPH,    0),
	Vector3(-PHI, -IPH,    0),
	Vector3( IPH,    0,  PHI),
	Vector3(-IPH,    0,  PHI),
	Vector3( IPH,    0, -PHI),
	Vector3(-IPH,    0, -PHI),
]

var ddedge = [
	[ 0,  8], [ 0, 12], [ 0, 16],
	[ 1,  9], [ 1, 12], [ 1, 18],
	[ 2, 10], [ 2, 13], [ 2, 16],
	[ 3, 11], [ 3, 13], [ 3, 18],
	[ 4,  8], [ 4, 14], [ 4, 17],
	[ 5,  9], [ 5, 14], [ 5, 19],
	[ 6, 10], [ 6, 15], [ 6, 17],
	[ 7, 11], [ 7, 15], [ 7, 19],
	[ 8,  9], [10, 11],
	[12, 13], [14, 15],
	[16, 17], [18, 19],
]

var ddface = [
	[ 0,  8,  9,  1, 12],
	[ 0, 12, 13,  2, 16],
	[ 0, 16, 17,  4,  8],
	[ 1,  9,  5, 19, 18],
	[ 1, 18,  3, 13, 12],
	[ 2, 10,  6, 17, 16],
	[ 2, 13,  3, 11, 10],
	[ 3, 18, 19,  7, 11],
	[ 4, 14,  5,  9,  8],
	[ 4, 17,  6, 15, 14],
	[ 5, 14, 15,  7, 19],
	[ 6, 10, 11,  7, 15],
]

func addCylinder(p1: Vector3, p2: Vector3, r: float):
	var vo = verts.size()
	
	# calc verts at point 1
	var dir: = (p2 - p1).normalized()
	var right: = dir.cross(Vector3.UP)
	if right.length_squared() < .1:
		right = dir.cross(Vector3.FORWARD)
	right = right.normalized()
	var vert0: = right * r
	for i in range(sides):
		verts.append(vert0.rotated(dir, i * 2 * PI / sides) + p1)
	
	# calc verts at point 2
	for i in range(sides):
		verts.append(vert0.rotated(dir, i * 2 * PI / sides) + p2)
	
	# tube
	for i in range(sides + 1):
		indices.append(vo +       + (0 + i) % sides)
		indices.append(vo + sides + (0 + i) % sides)
		indices.append(vo +       + (1 + i) % sides)
		indices.append(vo +       + (1 + i) % sides)
		indices.append(vo + sides + (0 + i) % sides)
		indices.append(vo + sides + (1 + i) % sides)
	
	# cap start point
	for i in range(sides - 2):
		indices.append(vo + 0)
		indices.append(vo + i + 1)
		indices.append(vo + i + 2)
	
	# cap end point
	for i in range(sides - 2):
		indices.append(vo + sides + 0)
		indices.append(vo + sides + i + 2)
		indices.append(vo + sides + i + 1)

func _init(center: Vector3, r1: float, r2: float):
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = verts
	surface[Mesh.ARRAY_INDEX] = indices
	
	for edge in ddedge:
		addCylinder(ddvert[edge[0]].normalized() * r1 + center, ddvert[edge[1]].normalized() * r1 + center , r2)
	for face in ddface:
		var vcenter: = Vector3.ZERO
		for corner in face:
			vcenter += ddvert[corner]
		vcenter = vcenter.normalized() * r1
		for corner in face:
			addCylinder(vcenter + center, ddvert[corner].normalized() * r1 + center, r2)
	
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
