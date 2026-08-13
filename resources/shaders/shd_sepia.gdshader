shader_type canvas_item;
uniform sampler2D screen_texture: hint_screen_texture, filter_linear;

varying vec4 modulate;
void fragment() {
	vec4 col = texture(screen_texture, SCREEN_UV);
	
	float r = col.r;
	float g = col.g;
	float b = col.b;
	
	float sepiaR = (r * 0.393) + (g * 0.768) + (b * 0.189);
	float sepiaG = (r * 0.349) + (g * 0.686) + (b * 0.168);
	float sepiaB = (r * 0.272) + (g * 0.534) + (b * 0.131);
	
	COLOR.rgb = vec3(sepiaR, sepiaG, sepiaB) * modulate.rgb;
	COLOR.a = col.a * modulate.a;
}

void vertex() {
	modulate = COLOR;
}