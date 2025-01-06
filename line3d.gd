class_name Line3D
extends Node3D

const sides = 8
const radius = .02
const surface_limit: int = 1000 / sides

var material: BaseMaterial3D
var surface: Array
var verts: PackedVector3Array
var indices: PackedInt32Array
var points: PackedVector3Array
var mesh: MeshInstance3D

func addPoint(p: Vector3):
	points.push_back(p)
	var point_num = points.size() - 1
	
	if point_num < 2: return
	
	var surface_num = (point_num - 2) / surface_limit
	var point_in_s = (point_num - 2) % surface_limit
	var dir
	var r
	var v0
	
	if point_in_s == 0:
		var oldverts = verts
		verts = PackedVector3Array()
		surface[Mesh.ARRAY_VERTEX] = verts
		indices.clear()
		mesh = MeshInstance3D.new()
		mesh.mesh = ArrayMesh.new()
		add_child(mesh)
		if surface_num == 0:
			dir = (points[-2] - points[-3]).normalized()
			r = dir.cross(Vector3.UP).normalized()
			v0 = r * radius
			for i in range(sides):
				verts.append(v0.rotated(dir, i * 2 * PI / sides) + points[-3])
		else:
			for i in range(sides):
				verts.append(oldverts[-sides + i])
	
	dir = (points[-1] - points[-3]).normalized()
	r = dir.cross(Vector3.UP).normalized()
	v0 = r * radius
	for i in range(sides):
		verts.append(v0.rotated(dir, i * 2 * PI / sides) + points[-2])
	
	for i in range(sides + 1):
		indices.append(point_in_s * sides         + (0 + i) % sides)
		indices.append(point_in_s * sides + sides + (0 + i) % sides)
		indices.append(point_in_s * sides         + (1 + i) % sides)
		indices.append(point_in_s * sides         + (1 + i) % sides)
		indices.append(point_in_s * sides + sides + (0 + i) % sides)
		indices.append(point_in_s * sides + sides + (1 + i) % sides)
	
	mesh.mesh.clear_surfaces()
	mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	mesh.mesh.surface_set_material(0, material)

func _init():
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = verts
	surface[Mesh.ARRAY_INDEX] = indices
