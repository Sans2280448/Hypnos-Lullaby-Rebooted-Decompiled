shader_type canvas_item;

const float MIN_FADE = 0.001;
const float EDGE_INNER = 0.994;
const float EDGE_OUTER = 1.006;

group_uniforms screen_size;
uniform vec2 rect_size = vec2(1920.0, 1080.0);

group_uniforms eye_colors;
uniform int eye_style : hint_enum("Normal", "Silhouette") = 0;
uniform vec4 eye_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 white_pupil_color : source_color = vec4(1.0);
uniform vec4 black_pupil_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

group_uniforms eye_size;
uniform int eye_size_variant : hint_enum("Tiny", "Small", "Large", "Custom") = 1;
uniform float tiny_eye_fill : hint_range(0.01, 1.5) = 0.18;
uniform float small_eye_fill : hint_range(0.01, 1.5) = 0.38;
uniform float large_eye_fill : hint_range(0.01, 1.5) = 1.0;
uniform float custom_eye_fill : hint_range(0.01, 1.5) = 0.5;

group_uniforms eye_position;
uniform vec2 eye_position = vec2(0.5, 0.5);

group_uniforms pupils;
uniform float white_pupil_size : hint_range(0.01, 1.0) = 0.40;
uniform float black_pupil_size : hint_range(0.01, 1.0) = 0.16;

group_uniforms;

vec2 aspect_correct(vec2 p, float aspect) {
	if (aspect > 1.0) {
		p.x = (p.x - 0.5) * aspect + 0.5;
	} else {
		p.y = (p.y - 0.5) / aspect + 0.5;
	}

	return p;
}

float sqr_circle(vec2 p, float radius) {
	return dot(p, p) / (radius * radius);
}

float hard_mask(float shape) {
	return 1.0 - smoothstep(EDGE_INNER, EDGE_OUTER, shape);
}

float get_eye_fill() {
	if (eye_size_variant == 0) {
		return tiny_eye_fill;
	}

	if (eye_size_variant == 1) {
		return small_eye_fill;
	}

	if (eye_size_variant == 2) {
		return large_eye_fill;
	}

	return custom_eye_fill;
}

void fragment() {
	float aspect = rect_size.x / rect_size.y;

	vec2 uv = aspect_correct(UV, aspect);
	vec2 center = aspect_correct(eye_position, aspect);

	float eye_size = max(aspect, 1.0) * 0.5 * get_eye_fill();
	vec2 p = uv - center;

	float eye_mask = hard_mask(sqr_circle(p, eye_size));

	if (eye_mask <= MIN_FADE) {
		discard;
	}

	float white_mask = hard_mask(sqr_circle(p, eye_size * white_pupil_size)) * eye_mask;
	float black_mask = hard_mask(sqr_circle(p, eye_size * black_pupil_size)) * white_mask;

	vec3 color = eye_color.rgb;

	if (eye_style == 1) {
		color = vec3(0.0);
	} else {
		color = mix(color, white_pupil_color.rgb, white_mask);
		color = mix(color, black_pupil_color.rgb, black_mask);
	}

	COLOR = vec4(color, eye_mask) * COLOR;
}