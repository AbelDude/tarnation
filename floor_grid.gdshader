shader_type spatial;
render_mode diffuse_burley;

varying vec2 floor_position;

void vertex() {
	floor_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float grid_line(vec2 position, float spacing, float width) {
	vec2 distance_to_line = abs(mod(position + spacing * 0.5, spacing) - spacing * 0.5);
	vec2 pixel_width = max(fwidth(position), vec2(0.001));
	vec2 coverage = vec2(1.0) - smoothstep(vec2(width), vec2(width) + pixel_width, distance_to_line);
	// Fade lines smaller than a pixel to avoid shimmering near the horizon.
	coverage *= clamp(vec2(spacing * 0.2) / pixel_width, vec2(0.0), vec2(1.0));
	return max(coverage.x, coverage.y);
}

void fragment() {
	float minor = grid_line(floor_position, 10.0, 0.035);
	float major = grid_line(floor_position, 50.0, 0.09);
	vec3 grass = vec3(0.224, 0.545, 0.251);
	ALBEDO = mix(grass, vec3(0.13, 0.32, 0.16), minor * 0.8);
	ALBEDO = mix(ALBEDO, vec3(0.07, 0.19, 0.10), major);
	ROUGHNESS = 0.95;
}
