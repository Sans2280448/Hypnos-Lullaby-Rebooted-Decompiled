shader_type canvas_item;

const float MIN_FADE = 0.001;
const float EDGE_INNER = 0.994;
const float EDGE_OUTER = 1.006;

const vec4 EYE_COLOR = vec4(1.0, 0.0, 0.0, 1.0);
const vec4 OUTER_PUPIL_COLOR = vec4(1.0);
const vec4 INNER_PUPIL_COLOR = vec4(0.0, 0.0, 0.0, 1.0);

const float OUTER_PUPIL_SIZE = 0.40;
const float INNER_PUPIL_SIZE = 0.16;

const float TINY_EYE_FILL = 0.18;
const float SMALL_EYE_FILL = 0.38;
const float LARGE_EYE_FILL = 1.0;

uniform int eye_style : hint_enum("Normal", "Silhouette") = 0;
uniform int eye_size_variant : hint_enum("Tiny", "Small", "Large", "Custom") = 1;
uniform sampler2D glow;

group_uniforms unown_metadata;
uniform vec2[1] eye_positions;
uniform vec2[1] eye_sizes;

void vertex() {
	// Called for every vertex the material is visible on.
}

float get_eye_fill() {
	switch (eye_style) {
		case 0:
			return TINY_EYE_FILL;
		case 1:
			return SMALL_EYE_FILL;
		case 2:
			return LARGE_EYE_FILL;
	}

	return 1.0;
}

float sqr_circle(vec2 p, float radius) {
	return dot(p, p) / (radius * radius);
}

float hard_mask(float shape) {
	return 1.0 - smoothstep(EDGE_INNER, EDGE_OUTER, shape);
}

void draw_eye(int idx) {
	// tryin my best, okay? :(
}

bool eye_rect_intersects(vec2 uv, int idx) {
	vec2 position = eye_positions[idx];
	vec2 size = eye_sizes[idx];
	return uv[0] >= position[0] && uv[0] <= position[1] && uv[1] >= position[1] && uv[1];
}

void fragment() {
	vec2 texture_size = vec2(1.0 / TEXTURE_PIXEL_SIZE.x, 1.0 / TEXTURE_PIXEL_SIZE.y);

	bool has_any_intersects = false;
	for (int i = 0; i < eye_positions.length(); i++) {
		if (eye_rect_intersects(UV, idx)) {
			draw_eye(int idx); // probably
			has_any_intersects = true;
		}
	}

	if (!has_any_intersects)
		discard;

	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
