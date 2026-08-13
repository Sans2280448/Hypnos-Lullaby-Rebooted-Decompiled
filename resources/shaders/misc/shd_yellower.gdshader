// Shader stolen from res://resources/shaders/color/shd_simple_color_replace.gdshader
// Modified by lunarcleint

shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

const int MAX_COLORS = 2;
uniform vec4 colors_to_mask[MAX_COLORS]: source_color;
uniform float range: hint_range(0.0, 1.0, 0.01);

void fragment() {
	vec4 screen_c = texture(SCREEN_TEXTURE, SCREEN_UV);

	for (int i = 0; i < MAX_COLORS; i++) {
		vec4 color_to_mask = colors_to_mask[i];
		
		if (distance(screen_c.rgba, color_to_mask.rgba) <= range && screen_c.a > 0.0) {
			COLOR = vec4(1.0, 1.0, 0.0, 1.0);
			break;
		}
		else
			COLOR = vec4(0.0);
	}
}