shader_type canvas_item;

uniform vec4 color_to_replace: source_color;
uniform vec4 new_color: source_color;
uniform float range: hint_range(0.0, 1.0, 0.01);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	if (distance(tex.rgb, color_to_replace.rgb) <= range)
		COLOR = vec4(new_color.rgb, tex.a * COLOR.a);
	else
		COLOR = vec4(tex.rgb, tex.a * COLOR.a);
}
