shader_type canvas_item;

const int MAX_EYES = 128;

const float MIN_FADE = 0.001;
const float EDGE_INNER = 0.994;
const float EDGE_OUTER = 1.006;
const float GLOW_INNER = 0.15;
const float GLOW_OUTER = 1.0;
group_uniforms screen_size;
uniform vec2 rect_size = vec2(1920.0, 1080.0);
group_uniforms eye_colors;
uniform vec4 eye_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 white_pupil_color : source_color = vec4(1.0);
uniform vec4 black_pupil_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int eye_count : hint_range(1, 128) = 72;

group_uniforms progression;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float hold_percent : hint_range(0.0, 1.0) = 0.0;
uniform float hold_progress : hint_range(0.0, 1.0) = 1.0;
uniform float eye_fade_stagger : hint_range(0.0, 1.0) = 0.75;

uniform float tiny_eye_size : hint_range(0.001, 0.05) = 0.0035;
uniform float small_eye_size : hint_range(0.001, 0.08) = 0.010;
uniform float large_eye_size : hint_range(0.001, 0.12) = 0.025;

uniform float large_eye_chance : hint_range(0.0, 1.0) = 0.12;
uniform float small_eye_chance : hint_range(0.0, 1.0) = 0.28;

group_uniforms eye_properties;

uniform float glow_intensity = 2.6;
uniform float glow_size : hint_range(1.0, 8.0) = 4.2;
uniform float blur_length : hint_range(1.0, 8.0) = 4.5;
uniform float blur_width : hint_range(0.05, 2.0) = 0.45;
uniform float blur_strength : hint_range(0.0, 4.0) = 1.7;

uniform vec4 hold_glow_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float hold_glow_intensity = 2.6;
uniform float hold_glow_size : hint_range(1.0, 8.0) = 4.2;
uniform float hold_blur_length : hint_range(1.0, 8.0) = 4.5;
uniform float hold_blur_width : hint_range(0.05, 2.0) = 0.45;
uniform float hold_blur_strength : hint_range(0.0, 4.0) = 1.7;

uniform float wobble_amount : hint_range(0.0, 0.1) = 0.008;
uniform float wobble_speed : hint_range(0.0, 20.0) = 0.35;

uniform float min_white_pupil_size = 0.30;
uniform float max_white_pupil_size = 0.50;

uniform float min_black_pupil_size = 0.10;
uniform float max_black_pupil_size = 0.22;

group_uniforms misc;
uniform float random_seed = 4.0;

float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

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

float sqr_directed_ellipse(vec2 p, vec2 direction, float length_radius, float width_radius) {
	vec2 side = vec2(-direction.y, direction.x);

	float along = dot(p, direction);
	float across = dot(p, side);

	return (along * along) / (length_radius * length_radius)
		+ (across * across) / (width_radius * width_radius);
}

float hard_mask(float shape) {
	return 1.0 - smoothstep(EDGE_INNER, EDGE_OUTER, shape);
}

float soft_mask(float shape) {
	return 1.0 - smoothstep(GLOW_INNER, GLOW_OUTER, shape);
}

float animated_eye_fade(float i) {
	float order = hash(i * 193.17 + random_seed * 77.7);
	float start = order * eye_fade_stagger;
	float end = start + (1.0 - eye_fade_stagger);

	return smoothstep(start, end, progress);
}

float held_eye_fade(float i) {
	if (hold_percent <= MIN_FADE || hold_progress <= MIN_FADE) {
		return 0.0;
	}

	float held_roll = hash(i * 312.91 + random_seed * 12.37);
	float is_held = step(held_roll + 0.00001, hold_percent);

	return is_held * hold_progress;
}

float get_eye_size(float i) {
	float type_roll = hash(i * 44.231 + random_seed);
	float size_roll = hash(i * 81.72 + random_seed);

	if (type_roll < large_eye_chance) {
		return mix(small_eye_size, large_eye_size, size_roll);
	}

	if (type_roll < small_eye_chance) {
		return mix(tiny_eye_size, small_eye_size, size_roll);
	}

	return tiny_eye_size * mix(0.55, 1.35, size_roll);
}

vec2 get_eye_position(float i, float aspect) {
	vec2 base_pos = vec2(
		hash(i * 12.9898 + random_seed * 19.17),
		hash(i * 78.233 + random_seed * 41.73)
	);

	float x_speed = wobble_speed + hash(i * 31.7) * 0.25;
	float y_speed = wobble_speed + hash(i * 59.2) * 0.25;

	vec2 wobble = vec2(
		sin(TIME * x_speed + hash(i * 17.4) * TAU),
		cos(TIME * y_speed + hash(i * 83.9) * TAU)
	) * wobble_amount;

	return aspect_correct(base_pos + wobble, aspect);
}

void add_eye(
	vec2 uv,
	vec2 center,
	vec2 screen_center,
	float i,
	float size,
	float normal_fade,
	float held_fade,
	inout vec3 color,
	inout float alpha
) {
	float final_fade = max(normal_fade, held_fade);

	if (final_fade <= MIN_FADE) {
		return;
	}

	vec2 p = uv - center;

	float final_glow_size = mix(glow_size, hold_glow_size, held_fade);
	float final_blur_length = mix(blur_length, hold_blur_length, held_fade);
	float final_blur_width = mix(blur_width, hold_blur_width, held_fade);
	float final_blur_strength = mix(blur_strength, hold_blur_strength, held_fade);

	float glow_radius = size * final_glow_size;
	float blur_x = glow_radius * final_blur_length;
	float blur_y = glow_radius * final_blur_width;
	float bounds = max(glow_radius, max(blur_x, blur_y));

	if (abs(p.x) > bounds || abs(p.y) > bounds) {
		return;
	}

	vec2 to_center = screen_center - center;
	vec2 direction = to_center * inversesqrt(max(dot(to_center, to_center), 0.00001));

	float eye_mask = hard_mask(sqr_circle(p, size)) * final_fade;
	float round_glow = soft_mask(sqr_circle(p, glow_radius));

	float blur_glow = 1.0 - smoothstep(
		0.0,
		1.0,
		sqr_directed_ellipse(p, direction, blur_x, blur_y)
	);

	float glow_mask = max(round_glow, blur_glow * final_blur_strength) * final_fade;

	float white_size = mix(
		min_white_pupil_size,
		max_white_pupil_size,
		hash(i * 91.77 + random_seed)
	);

	float black_size = mix(
		min_black_pupil_size,
		max_black_pupil_size,
		hash(i * 27.41 + random_seed)
	);

	float white_mask = hard_mask(sqr_circle(p, size * white_size)) * eye_mask;
	float black_mask = hard_mask(sqr_circle(p, size * black_size)) * white_mask;

	vec3 final_glow_color = mix(glow_color.rgb, hold_glow_color.rgb, held_fade);
	float final_glow_intensity = mix(glow_intensity, hold_glow_intensity, held_fade);

	color += final_glow_color * glow_mask * final_glow_intensity;
	color = mix(color, eye_color.rgb, eye_mask);
	color = mix(color, white_pupil_color.rgb, white_mask);
	color = mix(color, black_pupil_color.rgb, black_mask);

	alpha = max(alpha, max(glow_mask * 0.7, eye_mask));
}

void fragment() {
	float aspect = rect_size.x / rect_size.y;

	vec2 uv = aspect_correct(UV, aspect);
	vec2 screen_center = aspect_correct(vec2(0.5), aspect);

	vec3 color = vec3(0.0);
	float alpha = 0.0;

	int count = min(eye_count, MAX_EYES);

	for (int index = 0; index < MAX_EYES; index++) {
		if (index >= count) {
			break;
		}

		float i = float(index);

		float normal_fade = animated_eye_fade(i);
		float held_fade = held_eye_fade(i);

		if (normal_fade <= MIN_FADE && held_fade <= MIN_FADE) {
			continue;
		}

		add_eye(
			uv,
			get_eye_position(i + 1.0, aspect),
			screen_center,
			i,
			get_eye_size(i),
			normal_fade,
			held_fade,
			color,
			alpha
		);
	}

	COLOR = vec4(color, alpha);
}