shader_type spatial;
render_mode diffuse_burley;

varying vec2 floor_position;

void vertex() {
	floor_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

float hash_ground(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float ground_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 fraction = fract(point);
	vec2 blend = fraction * fraction * (3.0 - 2.0 * fraction);
	return mix(mix(hash_ground(cell), hash_ground(cell + vec2(1.0, 0.0)), blend.x),
		mix(hash_ground(cell + vec2(0.0, 1.0)), hash_ground(cell + vec2(1.0)), blend.x), blend.y);
}

float layered_noise(vec2 point) {
	return ground_noise(point) * 0.57
		+ ground_noise(point * 2.07 + vec2(13.2, 7.1)) * 0.28
		+ ground_noise(point * 4.13 + vec2(-8.4, 19.7)) * 0.15;
}

void fragment() {
	// Broad irregular patches, medium leaf litter, and small earthy flecks.
	vec2 warp = vec2(ground_noise(floor_position * 0.04), ground_noise(floor_position * 0.04 + vec2(51.0))) * 5.0;
	float patches = layered_noise((floor_position + warp) * 0.065);
	float litter = layered_noise(floor_position * 0.6 + vec2(24.0, -17.0));
	float grain = ground_noise(floor_position * 9.0);
	float detail_visibility = 1.0 - smoothstep(0.06, 0.3, max(fwidth(floor_position.x), fwidth(floor_position.y)));
	vec3 soil = mix(vec3(0.075, 0.038, 0.018), vec3(0.18, 0.10, 0.043), litter);
	vec3 moss = mix(vec3(0.055, 0.13, 0.025), vec3(0.12, 0.24, 0.045), litter);
	vec3 floor_color = mix(soil, moss, smoothstep(0.23, 0.46, patches));
	float leaves = smoothstep(0.62, 0.79, layered_noise(floor_position * 2.5));
	floor_color = mix(floor_color, vec3(0.22, 0.13, 0.045), leaves * 0.3 * detail_visibility);
	floor_color *= mix(1.0, mix(0.8, 1.16, grain), detail_visibility);
	ALBEDO = floor_color;
	ROUGHNESS = mix(0.88, 1.0, litter);
}
