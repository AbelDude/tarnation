extends Node3D

const TERRAIN := preload("res://terrain.gd")
const TREE_MODEL := "res://assets/ancient-oak-swaying.glb"
const TREES_PER_AREA := 5.0 / 25000.0
const WORLD_SIZE := 500.0
const MIN_SPACING := 12.0
const START_CLEARANCE := preload("res://world_layout.gd").CLEARING_RADIUS
const PERSON_HEIGHT := 2.11
const OAK_TO_PERSON_RATIO := 13.0
const MODEL_HEIGHT := 8.427527
const OAK_SCALE := PERSON_HEIGHT * OAK_TO_PERSON_RATIO / MODEL_HEIGHT

var tree_positions: Array[Vector3] = []


func _ready() -> void:
	var scene := load(TREE_MODEL) as PackedScene
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var target_count := int(WORLD_SIZE * WORLD_SIZE * TREES_PER_AREA)
	var attempts := 0
	while tree_positions.size() < target_count and attempts < target_count * 100:
		attempts += 1
		var point := Vector2(rng.randf_range(-242, 242), rng.randf_range(-242, 242))
		if point.length() < START_CLEARANCE:
			continue
		var clear := true
		for existing in tree_positions:
			if point.distance_squared_to(Vector2(existing.x, existing.z)) < MIN_SPACING * MIN_SPACING:
				clear = false
				break
		if not clear:
			continue
		var position_on_ground := Vector3(point.x, TERRAIN.height_at(point.x, point.y) - 0.15, point.y)
		tree_positions.append(position_on_ground)
		var size := OAK_SCALE * rng.randf_range(0.85, 1.15)
		# Keep the imported scene intact so its animated blend shapes still sway.
		var tree := scene.instantiate() as Node3D
		tree.name = "Oak_%03d" % tree_positions.size()
		tree.position = position_on_ground
		tree.rotation.y = rng.randf_range(0, TAU)
		tree.scale = Vector3.ONE * size
		add_child(tree)
		for animation_player in tree.find_children("*", "AnimationPlayer", true, false):
			for animation_name in animation_player.get_animation_list():
				if animation_name == "RESET":
					continue
				var animation: Animation = animation_player.get_animation(animation_name)
				animation.loop_mode = Animation.LOOP_LINEAR
				animation_player.speed_scale = rng.randf_range(0.85, 1.15)
				animation_player.play(animation_name)
				animation_player.seek(rng.randf_range(0, animation.length), true)
				break
		add_trunk_collision(position_on_ground, size)
	assert(tree_positions.size() == target_count, "Could not place requested tree count")


func add_trunk_collision(base: Vector3, size: float) -> void:
	var trunk := StaticBody3D.new()
	trunk.position = base + Vector3(0, 2.0 * size, 0)
	var collision := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.75 * size
	cylinder.height = 4.0 * size
	collision.shape = cylinder
	trunk.add_child(collision)
	add_child(trunk)
