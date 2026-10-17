extends StaticBody3D

const SIZE := 500.0
const STEP := 2.0
const POINTS := 251


static func height_at(x: float, z: float) -> float:
	var radius := Vector2(x, z).length()
	var valley := 18.0 * pow(radius / 250.0, 1.6)
	var humps := 3.0 * (1.0 - cos(x / 24.0) * cos(z / 31.0))
	humps += 1.5 * (1.0 - cos((x + z) / 39.0))
	return valley + humps


func _ready() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for row in range(POINTS):
		var z := -SIZE / 2.0 + row * STEP
		for column in range(POINTS):
			var x := -SIZE / 2.0 + column * STEP
			vertices.append(Vector3(x, height_at(x, z), z))
			var dx := (height_at(x + 0.1, z) - height_at(x - 0.1, z)) / 0.2
			var dz := (height_at(x, z + 0.1) - height_at(x, z - 0.1)) / 0.2
			normals.append(Vector3(-dx, 1.0, -dz).normalized())
	for row in range(POINTS - 1):
		for column in range(POINTS - 1):
			var a := row * POINTS + column
			var b := a + 1
			var c := a + POINTS
			var d := c + 1
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var surface := MeshInstance3D.new()
	surface.name = "TerrainSurface"
	surface.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = preload("res://floor_grid.gdshader")
	surface.material_override = material
	add_child(surface)
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	add_child(collision)
