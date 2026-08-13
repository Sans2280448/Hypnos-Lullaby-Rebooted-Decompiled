shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

uniform vec4 gray_color  : source_color = vec4(0.6510, 0.6392, 0.6392, 1.0);
uniform vec4 red_color   : source_color = vec4(0.4235, 0.1059, 0.1059, 1.0);
uniform vec4 black_color : source_color = vec4(0.063, 0.059, 0.059, 1.0);

uniform float tolerance : hint_range(0.0, 1.0) = 0.08;
void fragment()
{
	vec4 tex = texture(TEXTURE, UV);

	if (tex.a <= 0.0)
	{
		COLOR = vec4(0.0);
	}

	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);

	float gray_diff  = distance(screen.rgb, gray_color.rgb);
	float black_diff = distance(screen.rgb, black_color.rgb);

	vec3 version1 = gray_color.rgb;

	if (gray_diff <= tolerance)
	{
		version1 = red_color.rgb;
	}

	vec3 version2 = black_color.rgb;

	if (black_diff <= tolerance)
	{
		version2 = red_color.rgb;
	}

	vec3 final_color = mix(version2, version1, progress);

	COLOR = vec4(final_color, tex.a * COLOR.a);
}