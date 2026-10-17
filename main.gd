extends Node3D

const PLAYER_SCRIPT := preload("res://player.gd")


func _ready() -> void:
	var terrain := StaticBody3D.new()
	terrain.name = "Floor"
	terrain.set_script(preload("res://terrain.gd"))
	add_child(terrain)
	var forest := Node3D.new()
	forest.name = "Forest"
	forest.set_script(preload("res://forest.gd"))
	add_child(forest)
	var pines := Node3D.new()
	pines.name = "PineForest"
	pines.set_script(preload("res://pine_forest.gd"))
	add_child(pines)
	add_box("NorthWall", Vector3(0, 40, -250), Vector3(500.5, 100, 0.5), Color("254d30"), false)
	add_box("SouthWall", Vector3(0, 40, 250), Vector3(500.5, 100, 0.5), Color("254d30"), false)
	add_box("WestWall", Vector3(-250, 40, 0), Vector3(0.5, 100, 500), Color("254d30"), false)
	add_box("EastWall", Vector3(250, 40, 0), Vector3(0.5, 100, 500), Color("254d30"), false)


	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	light.shadow_enabled = true
	add_child(light)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("91b5cb")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.65
	world.environment = environment
	add_child(world)

	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PLAYER_SCRIPT)
	player.position = Vector3(0, 0.5, 0)
	add_child(player)

	var overlay := CanvasLayer.new()
	add_child(overlay)
	var instructions := Label.new()
	instructions.text = "WASD Move | CLICK Thrust | HOLD + DRAG Slash | MOUSE Look | SPACE Jump | ESC Release"
	instructions.position = Vector2(24, 20)
	instructions.add_theme_font_size_override("font_size", 17)
	instructions.add_theme_color_override("font_shadow_color", Color.BLACK)
	instructions.add_theme_constant_override("shadow_offset_x", 2)
	instructions.add_theme_constant_override("shadow_offset_y", 2)
	instructions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(instructions)
	var direction_display := Control.new()
	direction_display.name = "DirectionDisplay"
	direction_display.set_script(preload("res://direction_display.gd"))
	overlay.add_child(direction_display)
	player.connect("swing_changed", Callable(direction_display, "set_swing_direction"))


func add_box(box_name: String, center: Vector3, size: Vector3, color: Color, visible_box: bool = true) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = center
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	if not visible_box:
		add_child(body)
		return
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	visual.material_override = material
	if box_name == "Floor":
		var grid_material := ShaderMaterial.new()
		grid_material.shader = preload("res://floor_grid.gdshader")
		visual.material_override = grid_material
	body.add_child(visual)
	add_child(body)



