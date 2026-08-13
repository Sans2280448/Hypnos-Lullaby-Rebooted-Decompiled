shader_type spatial;
uniform vec4 colorer : source_color;

void fragment() {
	ALBEDO = colorer.rgb;
}

void light() {
	float light = max(dot(NORMAL,LIGHT),0.0) *ATTENUATION;
	light = round(light*2.0)/8.0;
	vec3 diffuse = vec3(light) * LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += diffuse;
}
