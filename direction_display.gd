extends Control

var active_direction := ""


func set_swing_direction(direction: String) -> void:
	active_direction = direction
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	offset_left = 28.0
	offset_top = -148.0
	offset_right = 148.0
	offset_bottom = -28.0


func _draw() -> void:
	var center := Vector2(60, 60)
	var color := Color("eef1f4")
	# Dark backing keeps the plus readable over the floor and sky.
	draw_line(Vector2(60, 12), Vector2(60, 108), Color("25313b"), 18.0, true)
	draw_line(Vector2(12, 60), Vector2(108, 60), Color("25313b"), 18.0, true)
	var endpoints := {"up": Vector2(60, 12), "down": Vector2(60, 108), "left": Vector2(12, 60), "right": Vector2(108, 60)}
	for direction in endpoints:
		var arm_color := Color("f04444") if direction == active_direction else color
		draw_line(center, endpoints[direction], arm_color, 10.0, true)
	draw_circle(center, 20.0, Color("25313b"))
	var circle_color := Color("f04444") if active_direction == "thrust" else color
	if active_direction == "thrust":
		draw_circle(center, 15.0, circle_color)
	draw_arc(center, 17.0, 0.0, TAU, 64, circle_color, 3.0, true)
