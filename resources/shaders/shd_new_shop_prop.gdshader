shader_type spatial;

render_mode unshaded, cull_front, blend_add, depth_draw_never;

uniform vec4 glow_color : source_color = vec4(1.0, 0.051, 0.973, 0.157);

uniform float outline_width : hint_range(0.0, 0.2, 0.001) = 0.033;
uniform float glow_strength : hint_range(0.0, 10.0, 0.1) = 2.0;

uniform float pulse_speed : hint_range(0.0, 10.0, 0.1) = 0.5;
uniform float pulse_brightness : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float pulse_size : hint_range(0.0, 1.0, 0.01) = 0.25;

void vertex() {
	float pulse = sin(TIME * pulse_speed * 6.283185);
	float size_multiplier = 1.0 + pulse * pulse_size;

	VERTEX += NORMAL * outline_width * size_multiplier;
}

void fragment() {
	float pulse = sin(TIME * pulse_speed * 6.283185);

	float pulse_normalized = pulse * 0.5 + 0.5;

	float brightness = mix(
		1.0 - pulse_brightness,
		1.0 + pulse_brightness,
		pulse_normalized
	);

	ALBEDO = glow_color.rgb * brightness;
	EMISSION = glow_color.rgb * glow_strength * brightness;
	ALPHA = glow_color.a;
}