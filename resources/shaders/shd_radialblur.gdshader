shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 2.0) = 1.0;
uniform float falloff : hint_range(0.0, 1.0) = 0.5;
uniform int samples : hint_range(0, 64) = 16;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = uv - clamp(center, vec2(0.0), vec2(1.0));

	float dist = length(dir) * 2.0;
	float fall = pow(min(dist, 1.0), 3.0 * falloff);
	float step_scale = intensity / float(samples) * 0.05;

	vec4 color = texture(screen_texture, uv);

	for (int i = 1; i <= samples; i++) {
		float fi = float(i);
		float offset = fi * step_scale * fall;
		color += texture(screen_texture, uv - dir * offset);
	}

	color /= float(samples + 1);
	COLOR = color;
}