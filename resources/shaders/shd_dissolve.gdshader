shader_type spatial;
render_mode depth_prepass_alpha, cull_disabled;

uniform sampler2D texture_albedo : source_color;
uniform sampler2D texture_normal : source_color;

uniform float metallic_amount : hint_range(0, 1) = 0.8;

uniform vec4 emission_color : source_color = vec4(1.0, 0.439, 1.0,1.0);
uniform float emission_amount = 15.0;

uniform sampler2D dissolve_texture;
uniform float burn_size : hint_range(0,2) = 0.1;
uniform float dissolve_amount : hint_range(-0.1,1.1) = -0.1;


void fragment() {
	vec4 albedo_tex = texture(texture_albedo,UV);
	ALBEDO = albedo_tex.rgb;
	vec4 normal_tex = texture(texture_normal,UV);
	NORMAL_MAP = normal_tex.rgb;
	
	float sample = texture(dissolve_texture, UV).r;
	float emission_value = 1.0 - smoothstep(dissolve_amount, dissolve_amount + burn_size, sample);
	EMISSION = vec3(emission_value * emission_amount * emission_color.rgb);
	METALLIC = metallic_amount;
	ALPHA = smoothstep(dissolve_amount - burn_size, dissolve_amount, sample);
}