extends Node3D

const TERRAIN := preload("res://terrain.gd")
const CLUSTER_AREA := 10000.0
const MIN_TREES_PER_CLUSTER := 3
const MAX_TREES_PER_CLUSTER := 12
const WORLD_SIZE := 500.0

var pine_height := 0.0
var pine_width_scale := 1.0
var cluster_centers: Array[Vector2] = []
var cluster_positions: Array = []


func _ready() -> void:
	var oak := load("res://assets/ancient-oak-swaying.glb").instantiate() as Node3D
	var limits := [INF, -INF]
	measure_height(oak, Transform3D.IDENTITY, limits)
	oak.free()
	var model_height: float = limits[1] - limits[0]
	var oak_scale: float = get_parent().get_node("Forest").OAK_SCALE
	pine_height = model_height * oak_scale * 1.5
	pine_width_scale = pine_height / (model_height * 1.6)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var variants: Array[ArrayMesh] = []
	for index in range(8):
		variants.append(create_pine_mesh(rng))
	var oak_positions: Array = get_parent().get_node("Forest").tree_positions
	var desired := int(WORLD_SIZE * WORLD_SIZE / CLUSTER_AREA)
	var attempts := 0
	while cluster_centers.size() < desired and attempts < 10000:
		attempts += 1
		var center := Vector2(rng.randf_range(-232, 232), rng.randf_range(-232, 232))
		if center.length() < 28.0:
			continue
		var clear := true
		for existing in cluster_centers:
			if center.distance_to(existing) < 40.0:
				clear = false
		if not clear:
			continue
		var tree_count := rng.randi_range(MIN_TREES_PER_CLUSTER, MAX_TREES_PER_CLUSTER)
		var offsets := make_cluster(rng, tree_count)
		if offsets.size() != tree_count:
			continue
		for offset in offsets:
			for oak_position in oak_positions:
				if (center + offset).distance_to(Vector2(oak_position.x, oak_position.z)) < 3.5:
					clear = false
		if not clear:
			continue
		var positions: Array[Vector3] = []
		var cluster := Node3D.new()
		cluster.name = "PineCluster_%02d" % cluster_centers.size()
		add_child(cluster)
		for offset in offsets:
			var point := center + offset
			var base := Vector3(point.x, TERRAIN.height_at(point.x, point.y) - 0.08, point.y)
			positions.append(base)
			var tree := MeshInstance3D.new()
			tree.name = "Pine_%02d" % positions.size()
			tree.mesh = variants[rng.randi_range(0, variants.size() - 1)]
			tree.position = base
			tree.rotation.y = rng.randf_range(0, TAU)
			cluster.add_child(tree)
			var trunk := StaticBody3D.new()
			trunk.position = base + Vector3(0, pine_height * 0.3, 0)
			var collision := CollisionShape3D.new()
			var shape := CylinderShape3D.new()
			shape.radius = 0.3 * pine_width_scale
			shape.height = pine_height * 0.6
			collision.shape = shape
			trunk.add_child(collision)
			cluster.add_child(trunk)
		cluster_centers.append(center)
		cluster_positions.append(positions)
	assert(cluster_centers.size() == desired, "Could not place requested pine clusters")


func make_cluster(rng: RandomNumberGenerator, tree_count: int) -> Array[Vector2]:
	var points: Array[Vector2] = [Vector2.ZERO]
	for attempt in range(2000):
		if points.size() == tree_count:
			break
		var anchor := points[rng.randi_range(0, points.size() - 1)]
		var candidate := anchor + Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(4.6, 5.4)
		if candidate.length() > 12.0:
			continue
		var clear := true
		for point in points:
			if candidate.distance_to(point) < 4.5:
				clear = false
		if clear:
			points.append(candidate)
	return points


func measure_height(node: Node, parent_transform: Transform3D, limits: Array) -> void:
	var transform := parent_transform
	if node is Node3D:
		transform *= node.transform
	if node is MeshInstance3D and node.mesh != null:
		var bounds: AABB = node.mesh.get_aabb()
		for corner in range(8):
			var point: Vector3 = transform * bounds.get_endpoint(corner)
			limits[0] = minf(limits[0], point.y)
			limits[1] = maxf(limits[1], point.y)
	for child in node.get_children():
		measure_height(child, transform, limits)


func create_pine_mesh(rng: RandomNumberGenerator) -> ArrayMesh:
	var result := ArrayMesh.new()
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color("65472e")
	bark.roughness = 1.0
	var trunk := CylinderMesh.new()
	trunk.bottom_radius = 0.3 * pine_width_scale
	trunk.top_radius = 0.09 * pine_width_scale
	trunk.height = pine_height * 0.88
	trunk.radial_segments = 9
	var wood := SurfaceTool.new()
	wood.begin(Mesh.PRIMITIVE_TRIANGLES)
	wood.append_from(trunk, 0, Transform3D(Basis.IDENTITY, Vector3(0, trunk.height / 2.0, 0)))
	wood.set_material(bark)
	wood.commit(result)
	var needles := StandardMaterial3D.new()
	needles.vertex_color_use_as_albedo = true
	needles.roughness = 1.0
	var foliage := SurfaceTool.new()
	foliage.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Overlapping, irregular branch skirts taper into a pointed evergreen crown.
	for tier in range(7):
		var fraction := float(tier) / 6.0
		var bottom := pine_height * (0.19 + fraction * 0.65)
		var top := minf(pine_height, bottom + pine_height * 0.23)
		if tier == 6:
			top = pine_height
		var radius := lerpf(1.85, 0.42, fraction) * rng.randf_range(0.9, 1.1) * pine_width_scale
		var ring: Array[Vector3] = []
		var phase := rng.randf_range(0, TAU)
		for segment in range(13):
			var angle := phase + segment * TAU / 13.0
			var spread := radius * rng.randf_range(0.82, 1.12)
			ring.append(Vector3(cos(angle) * spread, bottom + rng.randf_range(-0.16, 0.16), sin(angle) * spread))
		for segment in range(13):
			var a := ring[segment]
			var b := ring[(segment + 1) % 13]
			var shade := rng.randf_range(0.8, 1.15)
			foliage.set_color(Color(0.10, 0.29 + fraction * 0.07, 0.15) * shade)
			foliage.add_vertex(Vector3(0, top, 0))
			foliage.add_vertex(a)
			foliage.add_vertex(b)
			foliage.set_color(Color(0.07, 0.18, 0.10))
			foliage.add_vertex(Vector3(0, bottom, 0))
			foliage.add_vertex(b)
			foliage.add_vertex(a)
	foliage.generate_normals()
	foliage.set_material(needles)
	foliage.commit(result)
	return result
