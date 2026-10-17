extends CharacterBody3D

signal swing_changed(direction: String)

@export var speed: float = 6.0
@export var jump_speed: float = 8.0
var visual: Node3D
var camera_pivot: Node3D
var jump_requested := false
var pole_pivot: Node3D
var swing_tween: Tween
const BODY_YELLOW := Color("f4ce35")
const HAND_REST := Vector3(0.65, 0.5, -0.35)
var thrust_extension := 0.0
var right_upper_arm: MeshInstance3D
var right_forearm: MeshInstance3D
var right_elbow: MeshInstance3D
var right_hand: MeshInstance3D
var left_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var walk_phase := 0.0
const DRAG_THRESHOLD := 28.0
const QUICK_CLICK_MS := 250
var attack_held := false
var drag_fired := false
var drag_distance := Vector2.ZERO
var attack_pressed_at := 0


func _ready() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.85, 2.2, 0.65)
	collision.shape = shape
	collision.position.y = 0.6
	add_child(collision)
	visual = Node3D.new()
	add_child(visual)
	add_visual_box(Vector3(0, 0.6, 0), Vector3(0.72, 0.8, 0.4), BODY_YELLOW)
	add_visual_box(Vector3(0, 1.05, 0), Vector3(0.2, 0.18, 0.2), BODY_YELLOW)
	add_sphere("Head", Vector3(0, 1.37, 0), 0.31)
	left_leg = add_limb_pivot("LeftLeg", Vector3(-0.21, 0.22, 0), Vector3(0.24, 0.65, 0.28))
	right_leg = add_limb_pivot("RightLeg", Vector3(0.21, 0.22, 0), Vector3(0.24, 0.65, 0.28))
	left_arm = add_limb_pivot("LeftArm", Vector3(-0.48, 0.9, 0), Vector3(0.2, 0.72, 0.22))
	add_sphere("RightShoulder", Vector3(0.46, 0.9, 0), 0.14)
	right_upper_arm = add_arm_segment("RightUpperArm")
	right_forearm = add_arm_segment("RightForearm")
	right_elbow = add_sphere("RightElbow", Vector3.ZERO, 0.115)
	right_hand = add_sphere("RightHand", HAND_REST, 0.12)
	var pole := MeshInstance3D.new()
	pole.name = "HeldPole"
	pole_pivot = Node3D.new()
	pole_pivot.position = HAND_REST
	visual.add_child(pole_pivot)
	pole.position = Vector3(0, 0.35, 0)
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.065
	pole_mesh.bottom_radius = 0.065
	pole_mesh.height = 1.6
	pole.mesh = pole_mesh
	var pole_material := StandardMaterial3D.new()
	pole_material.albedo_color = BODY_YELLOW
	pole_material.metallic = 0.0
	pole_material.roughness = 0.4
	pole.material_override = pole_material
	pole_pivot.add_child(pole)
	camera_pivot = Node3D.new()
	camera_pivot.position.y = 1.2
	camera_pivot.rotation.x = -0.3
	add_child(camera_pivot)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.0
	arm.margin = 0.2
	arm.add_excluded_object(get_rid())
	var probe := SphereShape3D.new()
	probe.radius = 0.2
	arm.shape = probe
	camera_pivot.add_child(arm)
	var camera := Camera3D.new()
	camera.fov = 75.0
	camera.current = true
	arm.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			attack_held = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.keycode == KEY_SPACE:
			jump_requested = true
		elif event.keycode == KEY_UP:
			start_swing("up")
		elif event.keycode == KEY_DOWN:
			start_swing("down")
		elif event.keycode == KEY_RIGHT:
			start_swing("right")
		elif event.keycode == KEY_LEFT:
			start_swing("left")
	if event is InputEventMouseButton:
		if event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				begin_attack_gesture()
			else:
				end_attack_gesture()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if attack_held or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			update_attack_gesture(event.relative)
			return
		rotate_y(-event.relative.x * 0.003)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x - event.relative.y * 0.003, -1.1, 0.35)


func begin_attack_gesture() -> void:
	attack_held = true
	# A press during an attack still locks the camera until release.
	drag_fired = swing_tween != null and swing_tween.is_running()
	drag_distance = Vector2.ZERO
	attack_pressed_at = Time.get_ticks_msec()


func update_attack_gesture(movement: Vector2) -> void:
	if not attack_held or drag_fired:
		return
	drag_distance += movement
	if drag_distance.length() < DRAG_THRESHOLD:
		return
	drag_fired = true
	if absf(drag_distance.x) >= absf(drag_distance.y):
		start_swing("left" if drag_distance.x > 0 else "right")
	else:
		start_swing("up" if drag_distance.y > 0 else "down")


func end_attack_gesture() -> void:
	if not attack_held:
		return
	attack_held = false
	if not drag_fired and Time.get_ticks_msec() - attack_pressed_at <= QUICK_CLICK_MS:
		start_thrust()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		attack_held = false


func start_thrust() -> void:
	if swing_tween != null and swing_tween.is_running():
		return
	swing_changed.emit("thrust")
	swing_tween = create_tween()
	# Level the pole, drive it forward along its length, then retract.
	swing_tween.tween_property(pole_pivot, "rotation", Vector3(-PI / 2.0, 0, 0), 0.12).set_trans(Tween.TRANS_SINE)
	swing_tween.tween_property(self, "thrust_extension", 0.5, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	swing_tween.tween_property(self, "thrust_extension", 0.0, 0.2).set_trans(Tween.TRANS_SINE)
	swing_tween.tween_property(pole_pivot, "rotation", Vector3.ZERO, 0.16).set_trans(Tween.TRANS_SINE)
	swing_tween.tween_callback(func(): swing_changed.emit(""))


func start_swing(direction: String) -> void:
	if swing_tween != null and swing_tween.is_running():
		return
	var start := Vector3.ZERO
	var finish := Vector3.ZERO
	match direction:
		"up":
			start = Vector3(0.35, 0, 0)
			finish = Vector3(-2.7, 0, 0)
		"down":
			start = Vector3(-2.7, 0, 0)
			finish = Vector3(0.35, 0, 0)
		"right":
			start = Vector3(-PI / 2.0, -1.3, 0)
			finish = Vector3(-PI / 2.0, 1.3, 0)
		"left":
			start = Vector3(-PI / 2.0, 1.3, 0)
			finish = Vector3(-PI / 2.0, -1.3, 0)
	swing_changed.emit(direction)
	swing_tween = create_tween()
	if direction == "down":
		# Prepare outside the right side instead of cutting downward in front.
		swing_tween.tween_property(pole_pivot, "rotation", Vector3(0, 0, -PI / 2.0), 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		swing_tween.tween_method(prepare_upward_swing, 0.0, 1.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	else:
		swing_tween.tween_property(pole_pivot, "rotation", start, 0.12).set_trans(Tween.TRANS_SINE)
	swing_tween.tween_property(pole_pivot, "rotation", finish, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing_tween.tween_property(pole_pivot, "rotation", Vector3.ZERO, 0.18).set_trans(Tween.TRANS_SINE)
	swing_tween.tween_callback(func(): swing_changed.emit(""))


func prepare_upward_swing(progress: float) -> void:
	# Follow the outside arc from right to bottom, then align for the upward cut.
	var side_pose := Quaternion(Vector3.FORWARD, PI / 2.0)
	var bottom_pose := Quaternion(Vector3.RIGHT, -2.7)
	pole_pivot.quaternion = side_pose.slerp(bottom_pose, progress)


func _physics_process(delta: float) -> void:
	var input_direction := Vector3(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		0,
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	).normalized()
	var direction := global_transform.basis * input_direction
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if is_on_floor():
		velocity.y = jump_speed if jump_requested else 0.0
	else:
		velocity.y -= 20.0 * delta
	jump_requested = false
	move_and_slide()
	if global_position.y < -15.0:
		global_position = Vector3(0, 1, 0)
		velocity = Vector3.ZERO


func _process(delta: float) -> void:
	if pole_pivot == null:
		return
	# The wrist travels with the cut, and the two arm segments follow the grip.
	pole_pivot.position = HAND_REST + (pole_pivot.basis.y - Vector3.UP) * 0.22
	pole_pivot.position.z -= thrust_extension
	update_right_arm()
	var moving := Vector2(velocity.x, velocity.z).length() > 0.1 and is_on_floor()
	if moving:
		walk_phase += delta * 10.0
	var stride := sin(walk_phase) * 0.45 if moving else 0.0
	left_leg.rotation.x = lerp_angle(left_leg.rotation.x, stride, minf(delta * 14.0, 1.0))
	right_leg.rotation.x = lerp_angle(right_leg.rotation.x, -stride, minf(delta * 14.0, 1.0))
	left_arm.rotation.x = lerp_angle(left_arm.rotation.x, -stride * 0.65, minf(delta * 14.0, 1.0))


func update_right_arm() -> void:
	var shoulder := Vector3(0.46, 0.9, 0)
	var hand := pole_pivot.position
	var reach := hand - shoulder
	var distance := reach.length()
	var axis := reach.normalized()
	# Equal arm segments bend outward at the elbow.
	var bend := Vector3.RIGHT - axis * Vector3.RIGHT.dot(axis)
	if bend.length_squared() < 0.001:
		bend = Vector3.BACK - axis * Vector3.BACK.dot(axis)
	var elbow := (shoulder + hand) * 0.5 + bend.normalized() * sqrt(maxf(0.4225 - distance * distance * 0.25, 0.0))
	right_elbow.position = elbow
	right_hand.position = hand
	place_arm_segment(right_upper_arm, shoulder, elbow)
	place_arm_segment(right_forearm, elbow, hand)


func place_arm_segment(segment: MeshInstance3D, start: Vector3, finish: Vector3) -> void:
	var difference := finish - start
	segment.position = (start + finish) * 0.5
	segment.quaternion = Quaternion(Vector3.UP, difference.normalized())
	segment.scale = Vector3(1, difference.length(), 1)


func yellow_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = BODY_YELLOW
	material.roughness = 0.75
	return material


func add_sphere(part_name: String, center: Vector3, radius: float) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.position = center
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	part.mesh = mesh
	part.material_override = yellow_material()
	visual.add_child(part)
	return part


func add_arm_segment(part_name: String) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.095
	mesh.bottom_radius = 0.095
	mesh.height = 1.0
	part.mesh = mesh
	part.material_override = yellow_material()
	visual.add_child(part)
	return part


func add_limb_pivot(part_name: String, joint: Vector3, size: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = joint
	visual.add_child(pivot)
	var part := MeshInstance3D.new()
	part.position.y = -size.y / 2.0
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = yellow_material()
	pivot.add_child(part)
	return pivot


func add_visual_box(center: Vector3, size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.position = center
	var box := BoxMesh.new()
	box.size = size
	instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	instance.material_override = material
	visual.add_child(instance)



