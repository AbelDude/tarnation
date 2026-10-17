extends CharacterBody3D

signal swing_changed(direction: String)

@export var speed: float = 6.0
@export var jump_speed: float = 8.0
@export var spawn_position := Vector3(0, 0.55, 9.035)
var visual: Node3D
var camera_pivot: Node3D
var jump_requested := false
var pole_pivot: Node3D
var swing_tween: Tween
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var thrust_extension := 0.0
var attack_blend := 0.0
var gait_blend := 0.0
var right_shoulder := Vector3.ZERO
var right_upper_length := 0.0
var right_forearm_length := 0.0
var walk_phase := 0.0
const DRAG_THRESHOLD := 28.0
const QUICK_CLICK_MS := 250
var attack_held := false
var drag_fired := false
var drag_distance := Vector2.ZERO
var attack_pressed_at := 0


func _ready() -> void:
	floor_snap_length = 0.6
	floor_constant_speed = true
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.85, 2.2, 0.65)
	collision.shape = shape
	collision.position.y = 0.6
	add_child(collision)
	visual = preload("res://assets/woodsman.glb").instantiate()
	visual.name = "Woodsman"
	# Imported feet start at zero; the player body origin sits half a unit up.
	visual.position.y = -0.5
	visual.rotation.y = PI
	add_child(visual)
	skeleton = visual.find_children("*", "Skeleton3D", true, false)[0]
	animation_player = visual.find_children("*", "AnimationPlayer", true, false)[0]
	animation_player.stop()
	var upper := skeleton.find_bone("upper_arm.R")
	var forearm := skeleton.find_bone("forearm.R")
	var hand := skeleton.find_bone("hand.R")
	right_shoulder = skeleton.get_bone_global_rest(upper).origin
	right_upper_length = right_shoulder.distance_to(skeleton.get_bone_global_rest(forearm).origin)
	right_forearm_length = skeleton.get_bone_global_rest(forearm).origin.distance_to(skeleton.get_bone_global_rest(hand).origin)
	# Invisible animation driver retains swipe/thrust timing without a held object.
	pole_pivot = Node3D.new()
	pole_pivot.name = "AttackMotion"
	add_child(pole_pivot)
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
		global_position = spawn_position
		velocity = Vector3.ZERO


func _process(delta: float) -> void:
	if skeleton == null:
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.1 and is_on_floor()
	gait_blend = move_toward(gait_blend, 1.0 if moving else 0.0, delta * 6.0)
	if moving:
		walk_phase += delta * 10.0
	var stride := sin(walk_phase) * 0.42 * gait_blend
	for side in ["L", "R"]:
		var swing := stride if side == "L" else -stride
		rotate_bone_on_world_axis("thigh." + side, Vector3.RIGHT, swing)
		rotate_bone_on_world_axis("shin." + side, Vector3.RIGHT, -maxf(0.0, swing) * 0.7)
		rotate_bone_on_world_axis("foot." + side, Vector3.RIGHT, -swing * 0.25)
	rotate_bone_on_world_axis("upper_arm.L", Vector3.RIGHT, -stride * 0.65)
	var attacking := swing_tween != null and swing_tween.is_running()
	attack_blend = move_toward(attack_blend, 1.0 if attacking else 0.0, delta * 12.0)
	if attack_blend > 0.001:
		update_attack_arm()
	else:
		rotate_bone_on_world_axis("upper_arm.R", Vector3.RIGHT, stride * 0.65)
		reset_bone_rotation("forearm.R")
		reset_bone_rotation("hand.R")


func rotate_bone_on_world_axis(bone_name: String, axis: Vector3, angle: float) -> void:
	var index := skeleton.find_bone(bone_name)
	var world_axis := global_basis * axis
	var skeleton_axis := skeleton.global_basis.inverse() * world_axis
	var local_axis := skeleton.get_bone_global_rest(index).basis.inverse() * skeleton_axis
	var rest_rotation := skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(index, rest_rotation * Quaternion(local_axis.normalized(), angle))


func reset_bone_rotation(bone_name: String) -> void:
	var index := skeleton.find_bone(bone_name)
	skeleton.set_bone_pose_rotation(index, skeleton.get_bone_rest(index).basis.get_rotation_quaternion())


func update_attack_arm() -> void:
	var upper := skeleton.find_bone("upper_arm.R")
	var forearm := skeleton.find_bone("forearm.R")
	var wrist := skeleton.find_bone("hand.R")
	var shoulder := to_local(skeleton.to_global(right_shoulder))
	var rest_hand := to_local(skeleton.to_global(skeleton.get_bone_global_rest(wrist).origin))
	var cut := pole_pivot.basis.y
	var target := shoulder + Vector3(0.25 + cut.x * 0.4, cut.y * 0.45, -0.25 + cut.z * 0.25 - thrust_extension * 0.3)
	target = rest_hand.lerp(target, attack_blend)
	var reach := target - shoulder
	var distance := clampf(reach.length(), 0.06, (right_upper_length + right_forearm_length) * 0.98)
	var axis := reach.normalized()
	target = shoulder + axis * distance
	var along := (right_upper_length * right_upper_length - right_forearm_length * right_forearm_length + distance * distance) / (2.0 * distance)
	var bend := Vector3.RIGHT - axis * Vector3.RIGHT.dot(axis)
	if bend.length_squared() < 0.001:
		bend = Vector3.BACK - axis * Vector3.BACK.dot(axis)
	var elbow := shoulder + axis * along + bend.normalized() * sqrt(maxf(right_upper_length * right_upper_length - along * along, 0.0))
	aim_bone(upper, shoulder, elbow)
	aim_bone(forearm, elbow, target)
	reset_bone_rotation("hand.R")


func aim_bone(index: int, start: Vector3, finish: Vector3) -> void:
	var direction := (skeleton.to_local(to_global(finish)) - skeleton.to_local(to_global(start))).normalized()
	var rest := skeleton.get_bone_global_rest(index).basis
	var desired := Basis(Quaternion(rest.y.normalized(), direction)) * rest
	var parent := skeleton.get_bone_parent(index)
	var parent_basis := skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var pose := parent_basis.inverse() * desired
	skeleton.set_bone_pose_rotation(index, pose.orthonormalized().get_rotation_quaternion())



