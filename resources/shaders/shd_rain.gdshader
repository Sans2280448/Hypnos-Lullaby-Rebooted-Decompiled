/*
	Rain Shader for Godot
	Originally written for Friday Night Funkin'
	GDShader port by cherrythecool
	Additional adjustments & optimization by rushillbun
*/

shader_type canvas_item;

uniform float scale = 1.0;
uniform float intensity = 1.0;
uniform float distortionStrength = 1.0;

uniform float rain_speed = 8.0; 

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

const vec2 DISTORTION_DIR = vec2(0.70710678, 0.70710678); 
const vec3 RAIN_ATMOSPHERE = vec3(0.4, 0.5, 0.8);

float rand(vec2 co) {
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float rainDrop(vec2 p, float sc, float time_val, out float distortAmount) {
	p *= 0.1;
	p.x += p.y * 0.1;
	p.y -= time_val / sc;
	p.y *= 0.03;

	float ix = floor(p.x);
	float iy = floor(p.y);
	vec2 idx = vec2(ix, iy);

	p.y += mod(ix, 2.0) * 0.5 + (rand(vec2(ix)) - 0.5) * 0.3;
	iy = floor(p.y);
	idx = vec2(ix, iy);

	p -= vec2(ix, iy);
	p.x += (rand(idx.yx) * 2.0 - 1.0) * 0.35;
	vec2 d = abs(p - 0.5);
	float drop = max(d.x * 0.8, d.y * 0.5) - 0.1;

	distortAmount = 0.0;
	if (drop < 0.0) {
		float center = length(p - 0.5);
		distortAmount = smoothstep(0.0, 0.4, -drop) * smoothstep(0.0, 0.2, center);
	}

	bool empty = rand(idx) < mix(1.0, 0.1, intensity);
	return empty ? 1.0 : drop;
}

void fragment() {
	vec2 pos = FRAGCOORD.xy;
	vec2 distortedUV = SCREEN_UV;
	float rainAmount = 0.0;
	
	float time_val = TIME * (rain_speed * 100.0);
	float base_scale_inv = 1.0 / scale;

	for (int i = 0; i < 3; i++) {
		float sc = float(i + 1); 
		float offset = float(i) * 500.0;
		float distortAmount;

		float drop = rainDrop(pos * sc * base_scale_inv + offset, sc, time_val, distortAmount);
		
		if (drop < 0.0) {
			float distFactor = distortAmount * distortionStrength * (sc / 3.0);
			distortedUV += DISTORTION_DIR * distFactor;
			rainAmount += (1.0 - rainAmount) * 0.75;
		}
	}

	vec4 texcolor = texture(SCREEN_TEXTURE, distortedUV);
	vec3 finalColor = mix(texcolor.rgb, RAIN_ATMOSPHERE, 0.1 * rainAmount);
	
	if (length(finalColor) < 0.001) {
		discard;
	}
	
	COLOR = vec4(finalColor, texcolor.a);
}