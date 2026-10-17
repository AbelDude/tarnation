extends Node3D


func _ready() -> void:
	var model := preload("res://assets/log-cabin.glb").instantiate()
	add_child(model)
	# Use the actual surfaces, keeping the doorway and interior open.
	var faces := PackedVector3Array()
	for part in model.find_children("*", "MeshInstance3D", true, false):
		var transform: Transform3D = global_transform.affine_inverse() * part.global_transform
		var mesh_faces: PackedVector3Array = part.mesh.get_faces()
		for vertex in mesh_faces:
			faces.append(transform * vertex)
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
