class_name Line3D
extends Node3D

const sides: int = 8
const radius: float = .5
const seg_limit: int = 1000 / sides

var material: BaseMaterial3D
var points: PackedVector3Array

var mesh: MeshInstance3D
var surface: Array
var verts: PackedVector3Array
var indices: PackedInt32Array

var tmpmesh: MeshInstance3D
var tmpsurface: Array
var tmpverts: PackedVector3Array
var tmpindices: PackedInt32Array

# todo needs cleanup, unneccessary duplicated code
func tmpEnd(p: Vector3):
	var dir: Vector3
	var right: Vector3
	var vert0: Vector3
	
	tmpverts.clear()
	tmpindices.clear()
	if not tmpmesh:
		tmpmesh = MeshInstance3D.new()
		tmpmesh.mesh = ArrayMesh.new()
		add_child(tmpmesh)
	
	if points.size() > 2:
		# copy end vertices of last drawn segment
		for i in range(sides):
			tmpverts.append(verts[-sides + i])
		
		# calc verts at last known point in line
		dir = (p - points[-2]).normalized()
		var last_vert0 = tmpverts[0]
		var last_right = points[-2] - last_vert0
		var new_up = dir.cross(last_right.normalized()).normalized()
		right = dir.cross(new_up).normalized()
		vert0 = right * radius
		for i in range(sides):
			tmpverts.append(vert0.rotated(dir, i * 2 * PI / sides) + points[-1])
		
		# calc verts at temp point
		dir = (p - points[-1]).normalized()
		if dir.length() < 0.1:
			dir = (p - points[-2]).normalized() # use previous orientation
		last_right = -right
		new_up = dir.cross(last_right.normalized()).normalized()
		right = dir.cross(new_up).normalized()
		vert0 = right * radius
		for i in range(sides):
			tmpverts.append(vert0.rotated(dir, i * 2 * PI / sides) + p)
		
		# tube
		for j in range(2):
			for i in range(sides + 1):
				tmpindices.append(j * sides +       + (0 + i) % sides)
				tmpindices.append(j * sides + sides + (0 + i) % sides)
				tmpindices.append(j * sides +       + (1 + i) % sides)
				tmpindices.append(j * sides +       + (1 + i) % sides)
				tmpindices.append(j * sides + sides + (0 + i) % sides)
				tmpindices.append(j * sides + sides + (1 + i) % sides)
		
		# cap end point
		for i in range(sides - 2):
			tmpindices.append(sides + sides + 0)
			tmpindices.append(sides + sides + i + 2)
			tmpindices.append(sides + sides + i + 1)
		
	elif points.size() == 2:
		# calc verts at point 0
		dir = (points[-1] - points[-2]).normalized()
		right = dir.cross(Vector3.UP).normalized()
		vert0 = right * radius
		for i in range(sides):
			tmpverts.append(vert0.rotated(dir, i * 2 * PI / sides) + points[-2])
		
		# calc verts at point 1
		dir = (p - points[-2]).normalized()
		var last_right = -right
		var new_up = dir.cross(last_right.normalized()).normalized()
		right = dir.cross(new_up).normalized()
		vert0 = right * radius
		for i in range(sides):
			tmpverts.append(vert0.rotated(dir, i * 2 * PI / sides) + points[-1])
		
		# calc verts at temp point
		dir = (p - points[-1]).normalized()
		last_right = -right
		new_up = dir.cross(last_right.normalized()).normalized()
		right = dir.cross(new_up).normalized()
		vert0 = right * radius
		for i in range(sides):
			tmpverts.append(vert0.rotated(dir, i * 2 * PI / sides) + p)
		
		# tube
		for j in range(2):
			for i in range(sides + 1):
				tmpindices.append(j * sides +       + (0 + i) % sides)
				tmpindices.append(j * sides + sides + (0 + i) % sides)
				tmpindices.append(j * sides +       + (1 + i) % sides)
				tmpindices.append(j * sides +       + (1 + i) % sides)
				tmpindices.append(j * sides + sides + (0 + i) % sides)
				tmpindices.append(j * sides + sides + (1 + i) % sides)
		
		# cap start point
		for i in range(sides - 2):
			tmpindices.append(0)
			tmpindices.append(i + 1)
			tmpindices.append(i + 2)
		
		# cap end point
		for i in range(sides - 2):
			tmpindices.append(sides + sides + 0)
			tmpindices.append(sides + sides + i + 2)
			tmpindices.append(sides + sides + i + 1)
	elif points.size() == 1:
		# calc verts at point 0
		dir = (p - points[-1]).normalized()
		right = dir.cross(Vector3.UP).normalized()
		vert0 = right * radius
		for i in range(sides):
			tmpverts.append(vert0.rotated(dir, i * 2 * PI / sides) + points[-1])
		# calc verts at temp point
		for i in range(sides):
			tmpverts.append(vert0.rotated(dir, i * 2 * PI / sides) + p)
		
		# tube
		for i in range(sides + 1):
			tmpindices.append(      + (0 + i) % sides)
			tmpindices.append(sides + (0 + i) % sides)
			tmpindices.append(      + (1 + i) % sides)
			tmpindices.append(      + (1 + i) % sides)
			tmpindices.append(sides + (0 + i) % sides)
			tmpindices.append(sides + (1 + i) % sides)
		
		# cap start point
		for i in range(sides - 2):
			tmpindices.append(0)
			tmpindices.append(i + 1)
			tmpindices.append(i + 2)
		
		# cap end point
		for i in range(sides - 2):
			tmpindices.append(sides + 0)
			tmpindices.append(sides + i + 2)
			tmpindices.append(sides + i + 1)
	
	tmpmesh.mesh.clear_surfaces()
	tmpmesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, tmpsurface)
	tmpmesh.mesh.surface_set_material(0, material)


func addPoint(p: Vector3):
	points.push_back(p)
	var point_num: int = points.size() - 1
	
	if point_num < 2: return
	
	var surface_num: int = (point_num - 2) / seg_limit
	var seg_in_surf: int = (point_num - 2) % seg_limit
	var dir: Vector3
	var right: Vector3
	var vert0: Vector3
	
	if seg_in_surf == 0:
		var oldverts = verts
		verts = PackedVector3Array()
		surface[Mesh.ARRAY_VERTEX] = verts
		indices.clear()
		mesh = MeshInstance3D.new()
		mesh.mesh = ArrayMesh.new()
		add_child(mesh)
		if surface_num == 0:
			dir = (points[-2] - points[-3]).normalized()
			right = dir.cross(Vector3.UP).normalized()
			vert0 = right * radius
			for i in range(sides):
				verts.append(vert0.rotated(dir, i * 2 * PI / sides) + points[-3])
		else:
			for i in range(sides):
				verts.append(oldverts[-sides + i])
	
	dir = (points[-1] - points[-3]).normalized()
	var last_vert0 = verts[seg_in_surf * sides]
	var last_right = points[-3] - last_vert0
	var new_up = dir.cross(last_right.normalized()).normalized()
	right = dir.cross(new_up).normalized()
	vert0 = right * radius
	for i in range(sides):
		verts.append(vert0.rotated(dir, i * 2 * PI / sides) + points[-2])
	
	# cap start point
	if point_num == 2:
		for i in range(sides - 2):
			indices.append(0)
			indices.append(i + 1)
			indices.append(i + 2)
	
	for i in range(sides + 1):
		indices.append(seg_in_surf * sides         + (0 + i) % sides)
		indices.append(seg_in_surf * sides + sides + (0 + i) % sides)
		indices.append(seg_in_surf * sides         + (1 + i) % sides)
		indices.append(seg_in_surf * sides         + (1 + i) % sides)
		indices.append(seg_in_surf * sides + sides + (0 + i) % sides)
		indices.append(seg_in_surf * sides + sides + (1 + i) % sides)
	
	mesh.mesh.clear_surfaces()
	mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	mesh.mesh.surface_set_material(0, material)

func finalize():
	var point_num: int = points.size() # pretend we added a new virtual point
	
	if point_num < 2: return
	
	var surface_num: int = (point_num - 2) / seg_limit
	var seg_in_surf: int = (point_num - 2) % seg_limit
	var dir: Vector3
	var right: Vector3
	var vert0: Vector3
	
	dir = (points[-1] - points[-2]).normalized()
	var last_vert0 = verts[seg_in_surf * sides]
	var last_right = points[-2] - last_vert0
	var new_up = dir.cross(last_right.normalized()).normalized()
	right = dir.cross(new_up).normalized()
	vert0 = right * radius
	
	if seg_in_surf == 0:
		var oldverts = verts
		verts = PackedVector3Array()
		surface[Mesh.ARRAY_VERTEX] = verts
		indices.clear()
		mesh = MeshInstance3D.new()
		mesh.mesh = ArrayMesh.new()
		add_child(mesh)
		if surface_num == 0:
			for i in range(sides):
				verts.append(vert0.rotated(dir, i * 2 * PI / sides) + points[-2])
		else:
			for i in range(sides):
				verts.append(oldverts[-sides + i])
	
	for i in range(sides):
		verts.append(vert0.rotated(dir, i * 2 * PI / sides) + points[-1])
	
	# cap start point
	if point_num == 2:
		for i in range(sides - 2):
			indices.append(0)
			indices.append(i + 1)
			indices.append(i + 2)
	
	for i in range(sides + 1):
		indices.append(seg_in_surf * sides         + (0 + i) % sides)
		indices.append(seg_in_surf * sides + sides + (0 + i) % sides)
		indices.append(seg_in_surf * sides         + (1 + i) % sides)
		indices.append(seg_in_surf * sides         + (1 + i) % sides)
		indices.append(seg_in_surf * sides + sides + (0 + i) % sides)
		indices.append(seg_in_surf * sides + sides + (1 + i) % sides)
	
	# cap end point
	for i in range(sides - 2):
		indices.append(seg_in_surf * sides + sides + 0)
		indices.append(seg_in_surf * sides + sides + i + 2)
		indices.append(seg_in_surf * sides + sides + i + 1)
	
	mesh.mesh.clear_surfaces()
	mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	mesh.mesh.surface_set_material(0, material)
	remove_child(tmpmesh)

func _init():
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = verts
	surface[Mesh.ARRAY_INDEX] = indices
	tmpsurface.resize(Mesh.ARRAY_MAX)
	tmpsurface[Mesh.ARRAY_VERTEX] = tmpverts
	tmpsurface[Mesh.ARRAY_INDEX] = tmpindices
